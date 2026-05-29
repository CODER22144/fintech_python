CREATE SCHEMA [code] AUTHORIZATION DBO;
GO
CREATE SCHEMA [md] AUTHORIZATION DBO;
GO
CREATE SCHEMA [mastcode] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [docen] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [purchase] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [fiac] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [cost] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [sales] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [inven] AUTHORIZATION [dbo]
GO
CREATE SCHEMA [gl] AUTHORIZATION [dbo]
GO

-- Create synonyms to use universal functions
-- SELECT name AS synonym_name, base_object_name FROM sys.synonyms;

IF OBJECT_ID(N'dbo.uspLogError') IS NOT NULL
	DROP SYNONYM [dbo].[uspLogError];
GO
CREATE SYNONYM [dbo].[uspLogError] FOR [UniDb].[dbo].[spLogError];
GO

IF OBJECT_ID(N'mastcode.ConvertBase64') IS NOT NULL
	DROP SYNONYM [mastcode].[ConvertBase64];
GO
CREATE SYNONYM [mastcode].[ConvertBase64] FOR [UniDb].[mastcode].[fn_ConvertBase64]
GO

IF OBJECT_ID(N'mastcode.DecodeBase64') IS NOT NULL
	DROP SYNONYM [mastcode].[DecodeBase64];
GO

CREATE SYNONYM [mastcode].[DecodeBase64] FOR [UniDb].[mastcode].[fn_DecodeBase64]
GO

IF OBJECT_ID(N'mastcode.Num2Word') IS NOT NULL
	DROP SYNONYM [mastcode].[Num2Word];
GO

CREATE SYNONYM [mastcode].[Num2Word] FOR [UniDb].[mastcode].[fn_Num2Word]
GO

IF OBJECT_ID(N'mastcode.CastNumber2P') IS NOT NULL
	DROP SYNONYM [mastcode].[CastNumber2P];
GO

CREATE SYNONYM [mastcode].[CastNumber2P] FOR [UniDb].[mastcode].[fn_CastNumber2P]
GO

IF OBJECT_ID(N'mastcode.CastNumber3P') IS NOT NULL
	DROP SYNONYM [mastcode].[CastNumber3P];
GO

CREATE SYNONYM [mastcode].[CastNumber3P] FOR [UniDb].[mastcode].[fn_CastNumber3P]
GO

IF OBJECT_ID(N'mastcode.FinancialYear',N'U') IS NOT NULL
	DROP TABLE [mastcode].[FinancialYear];
GO

CREATE TABLE [mastcode].[FinancialYear] 
(
    Fy VARCHAR(9) PRIMARY KEY,  -- Format '2024-2025'
    SDate DATE NOT NULL,
    EDate DATE NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,	
    CONSTRAINT CK_mastcode_FinancialYear_fyformat
		CHECK (Fy LIKE '[0-9][0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]'),
    CONSTRAINT CK_FinYear_DateRange 
        CHECK (EDate > SDate),
    -- Must start on April 1 and end on March 31 of the following year
    CONSTRAINT CK_FinYear_AprilToMarch
        CHECK (
            MONTH(SDate) = 4 AND DAY(SDate) = 1 AND
            MONTH(EDate) = 3 AND DAY(EDate) = 31 AND
            YEAR(EDate) = YEAR(SDate) + 1
        ),
    -- Ensure Fy string matches SDate/EDate years
    CONSTRAINT CK_FinYear_YearMatch
        CHECK (
            LEFT(Fy,4) = CAST(YEAR(SDate) AS CHAR(4)) AND
            RIGHT(Fy,4) = CAST(YEAR(EDate) AS CHAR(4))
        )
);
GO

CREATE OR ALTER TRIGGER [mastcode].[Tr_FinancialYear]
ON [mastcode].[FinancialYear]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM mastcode.FinancialYear)
    BEGIN
		ROLLBACK TRANSACTION;
        THROW 50001, 'At least one Active Financial Year must exist.', 1;
        RETURN;
    END

    IF EXISTS (SELECT 1 FROM inserted WHERE IsActive = 1)
    BEGIN
        UPDATE fy
        SET IsActive = 0
        FROM mastcode.FinancialYear fy
        WHERE fy.Fy NOT IN (SELECT Fy FROM inserted WHERE IsActive = 1);
    END

    IF NOT EXISTS (SELECT 1 FROM mastcode.FinancialYear WHERE IsActive = 1)
    BEGIN
        IF (SELECT COUNT(*) FROM mastcode.FinancialYear) = 1
        BEGIN
            UPDATE mastcode.FinancialYear
            SET IsActive = 1;
        END
        ELSE
        BEGIN
            UPDATE mastcode.FinancialYear
            SET IsActive = 1
            WHERE EDate = (
                SELECT MAX(EDate)
                FROM mastcode.FinancialYear
            );
        END
    END
END;
GO

INSERT INTO [mastcode].[FinancialYear] (Fy,SDate,EDate,IsActive)
	VALUES ('2025-2026','2025-04-01','2026-03-31',1);
GO

IF OBJECT_ID(N'mastcode.Cfy',N'V') IS NOT NULL
	DROP VIEW [mastcode].[Cfy];
GO

CREATE VIEW [mastcode].[Cfy] 
AS
SELECT Fy, SDate, EDate
FROM [mastcode].[FinancialYear] WHERE IsActive = 1;
GO

IF OBJECT_ID(N'gl.PostDocToLedger',N'P') IS NOT NULL
	DROP PROCEDURE [gl].[PostDocToLedger];
GO

CREATE PROCEDURE [gl].[PostDocToLedger]
	@docId BIGINT,
	@docType VARCHAR(3),
	@checkSum VARCHAR(1) = NULL -- IF 'D' Then Delete and Insert again
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
    -- Use UPDLOCK + HOLDLOCK to acquire an update lock and hold it for the transaction.
    -- This serializes concurrent check/post attempts for the same docId/docType.

	DECLARE @postedExists INT,
		@msg VARCHAR(100);

	SELECT @postedExists = COUNT(1)
        FROM [gl].[GeneralLedger] WITH (UPDLOCK, HOLDLOCK)
        WHERE docId = @docId AND docType = @docType;
	
	BEGIN TRY
    BEGIN TRAN;
	
	IF @postedExists > 0
    BEGIN
		IF @checkSum IS NULL OR @checkSum <> 'D'
        BEGIN
			SET @msg = CONCAT(@docType, ' ', CAST(@docId AS VARCHAR),' already posted');
			THROW 60001, @msg, 1;
		END
        IF @checkSum = 'D'
        BEGIN
			DELETE FROM [gl].[GeneralLedger]
                WHERE docId = @docId AND docType = @docType;
		END
	END

	IF @docType = 'INV'
	BEGIN
		-- Customer Post
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, narration, drAmount)
		SELECT docId,Typ docType,Dt,lcode,'To Invoice No. '+CAST([No] AS varchar) Narration,TotVal  FROM [sales].[Sale] WHERE docId = @docId;
		-- Sales Post
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, narration, crAmount)
		SELECT docId,Typ docType,Dt,'Sales' AS lcode,'By Invoice No. '+CAST([No] AS varchar) Narration,AssAmt FROM [sales].[Sale] WHERE  docId = @docId AND AssAmt > 0;
		-- Tax Post
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, narration, crAmount)
		SELECT docId,Typ docType,Dt,'Gst' AS lcode,'By Invoice No. '+CAST([No] AS varchar) Narration,GstAmt FROM [sales].[Sale] WHERE  docId = @docId AND GstAmt > 0;
	END
	COMMIT;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK;
		THROW;
	END CATCH;
END
GO

IF OBJECT_ID (N'mastcode.IsNullOrEmpty', N'FN') IS NOT NULL  
    DROP FUNCTION [mastcode].[IsNullOrEmpty];  
GO

CREATE FUNCTION [mastcode].[IsNullOrEmpty]
(
    @input VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    IF @input IS NULL OR LTRIM(RTRIM(@input)) = ''
        RETURN NULL;

    RETURN @input;
END;
GO

IF OBJECT_ID(N'mastcode.ufGetCompanyState',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[ufGetCompanyState];
GO

CREATE FUNCTION [mastcode].[ufGetCompanyState]()
RETURNS SMALLINT
AS
BEGIN
	DECLARE @stcd SMALLINT
    SELECT @stcd = compStateCode FROM [mastcode].[Company]
	RETURN @stcd;
END;
GO

IF OBJECT_ID (N'mastcode.ufCDate', N'FN') IS NOT NULL  
    DROP FUNCTION [mastcode].[ufCDate];  
GO  

-- Return Current Date in yyyy/mm/dd Without time
CREATE FUNCTION [mastcode].[ufCDate]() 
RETURNS DATETIME
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @CDate date;
    SET @CDate= CONVERT(date,GETDATE(),111);
    RETURN(@CDate);
END;
GO

IF OBJECT_ID (N'mastcode.ufCDateTime', N'FN') IS NOT NULL  
    DROP FUNCTION [mastcode].[ufCDateTime];  
GO  

-- Return Current Date in yyyy/mm/dd hh:mm With time
CREATE FUNCTION [mastcode].[ufCDateTime]() 
RETURNS DATETIME
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @CDateTime datetime;
    SET @CDateTime= CAST(CONVERT(VARCHAR(16), GETDATE(), 120) AS datetime);
    RETURN(@CDateTime);
END;
GO

IF OBJECT_ID (N'mastcode.ufGetIDate', N'FN') IS NOT NULL  
    DROP FUNCTION [mastcode].[ufGetIDate];
GO  

-- Return Date INTO VARCHAR dd/mm/yyyy
CREATE FUNCTION [mastcode].[ufGetIDate](@dt DATETIME) 
RETURNS VARCHAR(10)
WITH EXECUTE AS CALLER
AS
BEGIN
    DECLARE @CDate VARCHAR(10);
    SET @CDate= CONVERT(varchar,@dt,105);
    RETURN(@CDate);
END;
GO

IF OBJECT_ID (N'mastcode.ufGetDate', N'FN') IS NOT NULL  
    DROP FUNCTION [mastcode].[ufGetDate];
GO  
-- CONVERT Date INTO VARCHAR mm/dd/yyyy
CREATE FUNCTION [mastcode].[ufGetDate](@dt DATETIME)   
RETURNS VARCHAR(10)  
WITH EXECUTE AS CALLER  
AS  
BEGIN  
	DECLARE @CDate VARCHAR(10);  
    SET @CDate= CONVERT(varchar,@dt,101);  
    RETURN(@CDate);  
END;  
GO

IF OBJECT_ID (N'mastcode.TransType', N'U') IS NOT NULL  
    DROP TABLE [mastcode].[TransType];  
GO 

CREATE TABLE [mastcode].[TransType]
(
	ty VARCHAR(1) NOT NULL CONSTRAINT pk_mastcode_transtype_ty PRIMARY KEY (ty),
	tyDescription VARCHAR(10) NOT NULL CONSTRAINT uk_mastcode_transtype_tydescription UNIQUE (tyDescription),
) ON [PRIMARY];
GO

-- Transaction Type
INSERT INTO [mastcode].[TransType] (ty,tyDescription)
VALUES ('S','Single'),
	('M','Multi')
GO

IF OBJECT_ID(N'mastcode.uspGetTransType', N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetTransType];
GO

CREATE PROCEDURE [mastcode].[uspGetTransType]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ty,tyDescription FROM [mastcode].[TransType];
END
GO

IF OBJECT_ID(N'mastcode.IsValidDocno',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidDocno];
GO

CREATE FUNCTION [mastcode].[IsValidDocno]
(
    @value VARCHAR(100)
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;

    -- Check length between 1 and 16
    IF LEN(@value) BETWEEN 1 AND 16
    BEGIN
        -- First character must be a-z, A-Z, or 1-9 (0 not allowed)
        IF PATINDEX('[a-zA-Z1-9]%', @value) = 1
        BEGIN
            -- Remaining characters (2 to 16) must be in allowed set
            IF @value NOT LIKE '%[^a-zA-Z0-9/-]%'
            BEGIN
                SET @result = 1
            END
        END
    END

    RETURN @result
END
GO

IF OBJECT_ID(N'mastcode.IsValidDescription',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidDescription];
GO

CREATE FUNCTION [mastcode].[IsValidDescription]
(
    @input NVARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
    IF @input IS NULL RETURN 0;

	-- String is valid which not contains charaster \ or "
    IF @input LIKE '%[\]%' OR @input LIKE '%"%'  
        RETURN 0;

    RETURN 1;
END
GO

IF OBJECT_ID(N'mastcode.IsValidPhone',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidPhone];
GO

CREATE FUNCTION [mastcode].[IsValidPhone]
(
    @value VARCHAR(20)
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;
	-- Ensures only digits and between 6 and 12 character
    IF LEN(@value) BETWEEN 6 AND 12 AND @value NOT LIKE '%[^0-9]%'
    BEGIN
        SET @result = 1;
    END

    RETURN @result;
END
GO

IF OBJECT_ID(N'mastcode.IsValidGSTIN',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidGSTIN];
GO

CREATE FUNCTION [mastcode].[IsValidGSTIN](@gstin VARCHAR(20))
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    IF @gstin = 'URP' RETURN 1

	IF LEN(@gstin) != 15 RETURN 0

    IF PATINDEX('[0-3][0-9][A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z][0-9A-Z]Z[0-9A-Z]', @gstin) != 1
        RETURN 0

    RETURN 1
END
GO

IF OBJECT_ID(N'mastcode.IsValidPAN',N'FN') IS NOT NULL
	DROP FUNCTION mastcode.IsValidPAN;
GO

CREATE FUNCTION [mastcode].[IsValidPAN](@pan VARCHAR(10))
RETURNS BIT
WITH SCHEMABINDING
AS
BEGIN
    IF LEN(@pan) != 10 RETURN 0

    IF PATINDEX('[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]', @pan) != 1
        RETURN 0

    RETURN 1
END
GO

IF OBJECT_ID(N'mastcode.IsValidHSN',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidHSN];
GO

CREATE FUNCTION [mastcode].[IsValidHSN]
(
    @input VARCHAR(20)
)
RETURNS BIT
AS
BEGIN
    -- Reject NULL or non-numeric input
    IF @input IS NULL OR @input NOT LIKE '%[0-9]%'
        RETURN 0;

    -- Check: input must be 4, 6, or 8 characters long
    IF LEN(@input) NOT IN (4, 6, 8)
        RETURN 0;

    -- Check: all characters must be digits
    IF @input LIKE '%[^0-9]%'
        RETURN 0;

    -- Check: string must NOT be all zeros
    IF @input = REPLICATE('0', LEN(@input))
        RETURN 0;

    RETURN 1;
END
GO

IF OBJECT_ID(N'mastcode.Num2Word') IS NOT NULL
	DROP SYNONYM [mastcode].[Num2Word];
GO
CREATE SYNONYM [mastcode].[Num2Word] FOR [UniDb].[mastcode].[fn_Num2Word]
GO

IF OBJECT_ID(N'mastcode.uspGetYesNo') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetYesNo];
GO
CREATE SYNONYM [mastcode].[uspGetYesNo] FOR [UniDb].[mastcode].[spGetYesNo]
GO

IF OBJECT_ID(N'mastcode.uspGetBitYesNo') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetBitYesNo];
GO
CREATE SYNONYM [mastcode].[uspGetBitYesNo] FOR [UniDb].[mastcode].[spGetBitYesNo]
GO

IF OBJECT_ID(N'mastcode.IsValidState',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidState];
GO

CREATE FUNCTION [mastcode].[IsValidState](@stcode SMALLINT)
RETURNS BIT
AS
BEGIN
	
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[States] WHERE [sid] = @stcode)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.IsValidCountries',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidCountries];
GO

CREATE FUNCTION [mastcode].[IsValidCountries](@ctcode VARCHAR(2))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[Countries] WHERE [cid] = @ctcode)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.IsValidTdsType',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidTdsType];
GO

CREATE FUNCTION [mastcode].[IsValidTdsType](@tdscode VARCHAR(10))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[TdsType] WHERE [tdsCode] = @tdscode)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetTdsType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetTdsType];
GO
CREATE SYNONYM [mastcode].[uspGetTdsType] FOR [UniDb].[mastcode].[spGetTdsType];
GO

IF OBJECT_ID(N'mastcode.uspGetTdsTypeDropDown') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetTdsTypeDropDown];
GO
CREATE SYNONYM [mastcode].[uspGetTdsTypeDropDown] FOR [UniDb].[mastcode].[spGetTdsTypeDropDown];
GO

IF OBJECT_ID(N'mastcode.uspGetTdsTypeById') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetTdsTypeById];
GO
CREATE SYNONYM [mastcode].[uspGetTdsTypeById] FOR [UniDb].[mastcode].[spGetTdsTypeById];
GO

IF OBJECT_ID(N'mastcode.IsValidGstSupplyType',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidGstSupplyType];
GO

CREATE FUNCTION [mastcode].[IsValidGstSupplyType](@suptype VARCHAR(10))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[GstSupplyType] WHERE [SupTyp] = @suptype)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.IsValidGSTRegnType',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidGSTRegnType];
GO

CREATE FUNCTION [mastcode].[IsValidGSTRegnType](@regid VARCHAR(3))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[GSTRegnType] WHERE [regId] = @regid)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetCurrency') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetCurrency];
GO
CREATE SYNONYM [mastcode].[uspGetCurrency] FOR [UniDb].[mastcode].[spGetCurrency]
GO

IF OBJECT_ID(N'mastcode.LedgerType') IS NOT NULL
	DROP SYNONYM [mastcode].[LedgerType];
GO
CREATE SYNONYM [mastcode].[LedgerType] FOR [UniDb].[mastcode].[LedgerType]
GO

IF OBJECT_ID(N'mastcode.uspGetLedgerStatus') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetLedgerStatus];
GO
CREATE SYNONYM [mastcode].[uspGetLedgerStatus] FOR [UniDb].[mastcode].[spGetLedgerStatus]
GO

IF OBJECT_ID(N'mastcode.IsValidLedgerStatus', N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidLedgerStatus];
GO

CREATE FUNCTION [mastcode].[IsValidLedgerStatus](@lstatus VARCHAR(1))
RETURNS BIT
AS
BEGIN
	
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[LedgerStatus] WHERE lstatus = @lstatus)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.IsValidShippingId',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidShippingId];
GO

CREATE FUNCTION [mastcode].[IsValidShippingId](@lcode VARCHAR(10), @shipId bigint)
RETURNS BIT
AS
BEGIN
	IF (SELECT lcode FROM [mastcode].[CustomerShipping] WHERE shipCode = @shipId) = @lcode
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetGstSupplyType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetGstSupplyType];
GO
CREATE SYNONYM [mastcode].[uspGetGstSupplyType] FOR [UniDb].[mastcode].[spGetGstSupplyType]
GO

IF OBJECT_ID(N'mastcode.uspGetLedgerType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetLedgerType];
GO
CREATE SYNONYM [mastcode].[uspGetLedgerType] FOR [UniDb].[mastcode].[spGetLedgerType]
GO

IF OBJECT_ID(N'mastcode.uspGetGSTRegnType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetGSTRegnType];
GO
CREATE SYNONYM [mastcode].[uspGetGSTRegnType] FOR [UniDb].[mastcode].[spGetGSTRegnType]
GO

IF OBJECT_ID(N'mastcode.IsValidDocType',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidDocType];
GO

CREATE FUNCTION [mastcode].[IsValidDocType](@doctype VARCHAR(10))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[DocType] WHERE [docId] = @doctype)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetDocType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetDocType];
GO
CREATE SYNONYM [mastcode].[uspGetDocType] FOR [UniDb].[mastcode].[spGetDocType]
GO

IF OBJECT_ID(N'mastcode.DocType') IS NOT NULL
	DROP SYNONYM [mastcode].[DocType];
GO
CREATE SYNONYM [mastcode].[DocType] FOR [UniDb].[mastcode].[ViDocType]
GO

IF OBJECT_ID(N'mastcode.uspGetStates') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetStates];
GO
CREATE SYNONYM [mastcode].[uspGetStates] FOR [UniDb].[mastcode].[spGetStates]
GO

IF OBJECT_ID(N'mastcode.States') IS NOT NULL
	DROP SYNONYM [mastcode].[States];
GO
CREATE SYNONYM [mastcode].[States] FOR [UniDb].[mastcode].[ViStates]
GO

IF OBJECT_ID(N'mastcode.uspGetCountries') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetCountries];
GO
CREATE SYNONYM [mastcode].[uspGetCountries] FOR [UniDb].[mastcode].[spGetCountries]
GO

IF OBJECT_ID(N'mastcode.Countries') IS NOT NULL
	DROP SYNONYM [mastcode].[Countries];
GO
CREATE SYNONYM [mastcode].[Countries] FOR [UniDb].[mastcode].[ViCountries]
GO

IF OBJECT_ID(N'mastcode.Countries') IS NOT NULL
	DROP SYNONYM [mastcode].[Countries];
GO
CREATE SYNONYM [mastcode].[Countries] FOR [UniDb].[mastcode].[ViCountries]
GO

IF OBJECT_ID(N'mastcode.GstSupplyType') IS NOT NULL
	DROP SYNONYM [mastcode].[GstSupplyType];
GO
CREATE SYNONYM [mastcode].[GstSupplyType] FOR [UniDb].[mastcode].[ViGstSupplyType]
GO

IF OBJECT_ID(N'mastcode.GstSupplyType') IS NOT NULL
	DROP SYNONYM [mastcode].[GstSupplyType];
GO
CREATE SYNONYM [mastcode].[GstSupplyType] FOR [UniDb].[mastcode].[ViGstSupplyType]
GO

IF OBJECT_ID(N'mastcode.IsValidGstRate',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidGstRate];
GO

CREATE FUNCTION [mastcode].[IsValidGstRate](@rgst DECIMAL(6,3))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT * FROM [UniDb].[mastcode].[GstRate] WHERE [rgst] = @rgst)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetGstRate') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetGstRate];
GO

CREATE SYNONYM [mastcode].[uspGetGstRate] FOR [UniDb].[mastcode].[spGetGstRate]
GO

IF OBJECT_ID('mastcode.uspGetTdsType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetTdsType];
GO
CREATE SYNONYM [mastcode].[uspGetTdsType] FOR [UniDb].[mastcode].[spGetTdsType]
GO

IF OBJECT_ID(N'mastcode.TdsType') IS NOT NULL
	DROP SYNONYM [mastcode].[TdsType];
GO
CREATE SYNONYM [mastcode].[TdsType] FOR [UniDb].[mastcode].[ViTdsType]
GO

IF OBJECT_ID (N'mastcode.SaleDiscountType', N'U') IS NOT NULL  
    DROP TABLE [mastcode].[SaleDiscountType];  
GO 

CREATE TABLE [mastcode].[SaleDiscountType]
(
	discType VARCHAR(1) NOT NULL CONSTRAINT pk_mastcode_salediscounttype_disctype PRIMARY KEY (discType),
	discDescription VARCHAR(10) NOT NULL CONSTRAINT uk_mastcode_salediscounttype_discdescription UNIQUE (discDescription),
) ON [PRIMARY];
GO

-- Discount Type For Customer
INSERT INTO [mastcode].[SaleDiscountType] (discType,discDescription)
VALUES ('F','Fixed'),
	('T','TaxPaid'),
	('Z','Zero'),
	('M','Material')
GO

IF OBJECT_ID(N'mastcode.uspGetSaleDiscountType', N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetSaleDiscountType];
GO

CREATE PROCEDURE [mastcode].[uspGetSaleDiscountType]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT discType,discDescription FROM [mastcode].[SaleDiscountType];
END
GO

IF OBJECT_ID(N'mastcode.IsValidUnit',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidUnit];
GO

CREATE FUNCTION [mastcode].[IsValidUnit](@unit VARCHAR(8))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[MaterialUnit] WHERE [key] = @unit)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetMaterialUnit') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetMaterialUnit];
GO
CREATE SYNONYM [mastcode].[uspGetMaterialUnit] FOR [UniDb].[mastcode].[spGetMaterialUnit]
GO

IF OBJECT_ID(N'mastcode.MaterialUnit') IS NOT NULL
	DROP SYNONYM [mastcode].[MaterialUnit];
GO
CREATE SYNONYM [mastcode].[MaterialUnit] FOR [UniDb].[mastcode].[MaterialUnit]
GO

IF OBJECT_ID(N'mastcode.IsValidMaterialStatus',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidMaterialStatus];
GO

CREATE FUNCTION [mastcode].[IsValidMaterialStatus](@mst VARCHAR(1))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[MaterialStatus] WHERE mst = @mst)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetMaterialStatus') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetMaterialStatus];
GO
CREATE SYNONYM [mastcode].[uspGetMaterialStatus] FOR [UniDb].[mastcode].[spGetMaterialStatus]
GO

IF OBJECT_ID(N'mastcode.uspGetModeOfFreight') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetModeOfFreight];
GO
CREATE SYNONYM [mastcode].[uspGetModeOfFreight] FOR [UniDb].[mastcode].[spGetModeOfFreight]
GO

IF OBJECT_ID(N'mastcode.uspGetTransportMode') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetTransportMode];
GO
CREATE SYNONYM [mastcode].[uspGetTransportMode] FOR [UniDb].[mastcode].[spGetTransportMode]
GO

IF OBJECT_ID(N'mastcode.TransportMode') IS NOT NULL
	DROP SYNONYM [mastcode].[TransportMode];
GO
CREATE SYNONYM [mastcode].[TransportMode] FOR [UniDb].[mastcode].[ViTransportMode]
GO

IF OBJECT_ID(N'mastcode.uspGetModeOfPayment') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetModeOfPayment];
GO
CREATE SYNONYM [mastcode].[uspGetModeOfPayment] FOR [UniDb].[mastcode].[spGetModeOfPayment]
GO

IF OBJECT_ID(N'mastcode.uspGetVehicleType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetVehicleType];
GO
CREATE SYNONYM [mastcode].[uspGetVehicleType] FOR [UniDb].[mastcode].[spGetVehicleType]
GO

IF OBJECT_ID (N'sales.ufGetMaterialAmount', N'TF') IS NOT NULL  
    DROP FUNCTION [sales].[ufGetMaterialAmount];  
GO  

CREATE FUNCTION [sales].[ufGetMaterialAmount] (@lcode VARCHAR(10),@matno VARCHAR(15),@qty DECIMAL(12,2))
RETURNS @mdetails TABLE (
	lcode VARCHAR(10),
	matno VARCHAR(15),
	igstOnIntra VARCHAR(1), 
	saleDescription VARCHAR(50),
	qty DECIMAL(12,3),
	unit VARCHAR(8),
	hsnCode VARCHAR(10),
	gstTaxRate DECIMAL(5,2),
	mrp DECIMAL(12,2),
	rate DECIMAL(12,2),
	amount DECIMAL(12,2),    
	gstAmount DECIMAL(12,2),
	tAmount DECIMAL(12,2)
) 
AS    
BEGIN    
	DECLARE @json NVARCHAR(max), 
		@igstOnIntra VARCHAR(1),
		@mrp DECIMAL(12,2),
		@listPrice DECIMAL(12,2),
		@discType VARCHAR(1),
		@discRate DECIMAL(5,2) = 0,
		@loyaltyDisc DECIMAL(5,2) = 0,
		@paymentDisc DECIMAL(5,2) = 0,
		@saleDescription VARCHAR(50),
		@unit VARCHAR(8),
		@hsnCode VARCHAR(10),
		@gstTaxRate DECIMAL(5,2) = 0,
		@srate DECIMAL(12,2) = NULL,
		@rate DECIMAL(12,2) = NULL,
		@amount DECIMAL(12,2) = 0,    
		@gstAmount DECIMAL(12,2) = 0,
		@tAmount DECIMAL(12,2)= 0

		SELECT @igstOnIntra = igstOnIntra,
			@mrp = mrp,
			@listPrice = listPrice,
			@discType = discType,
			@discRate = discRate,
			@loyaltyDisc = loyaltyDisc,
			@paymentDisc = paymentDisc,
			@saleDescription = saleDescription,
			@unit = unit,
			@hsnCode = hsnCode,
			@gstTaxRate = gstTaxRate,
			@srate = srate
		FROM [sales].[ufGetMaterialRate](@lcode,@matno)

		IF @unit IS NULL OR @hsnCode IS NULL OR @discType IS NULL
		BEGIN			
			RETURN; 
		END

		IF @discType = 'F' 
		BEGIN
			SET @rate = ROUND((@listPrice - (@listPrice * @discRate * .01)),2,1)	
			SET @rate = ROUND((@rate - (@rate * @loyaltyDisc * .01)),2,1)
			SET @rate = ROUND((@rate - (@rate * @paymentDisc * .01)),2,1)
		END
		IF @discType = 'M' 
		BEGIN
			SET @rate = @srate
		END
		IF @discType = 'T'
		BEGIN
			SET @discRate = Round(100*((@gstTaxRate + @discRate)/(@gstTaxRate + 100.00)),2,0)
			SET @rate = ROUND((@listPrice - (@listPrice * @discRate * .01)),2,0)	
			SET @rate = ROUND((@rate - (@rate * @loyaltyDisc * .01)),2,0)
			SET @rate = ROUND((@rate - (@rate * @paymentDisc * .01)),2,0)
		END

		SET @amount = ROUND((@qty * @rate),2,1)
		SET @gstAmount = ROUND((@amount) * @gstTaxRate * .01,1,0)              
	
		SET @tAmount = @amount + @gstAmount    
		
		IF @discType != 'T'
			SET @mrp = 0;

		INSERT INTO @mdetails (lcode,matno,igstOnIntra,saleDescription,qty,unit,hsnCode,gstTaxRate,mrp,rate,amount,gstAmount,tAmount) 
		SELECT @lcode,@matno,@igstOnIntra,@saleDescription,@qty,@unit,@hsnCode,@gstTaxRate,@mrp,@rate,@amount,@gstAmount,@tAmount

		RETURN
END
GO

IF OBJECT_ID (N'mastcode.DocInitialNo', N'U') IS NOT NULL  
    DROP TABLE [mastcode].[DocInitialNo];  
GO

CREATE TABLE [mastcode].[DocInitialNo]
(
	docName VARCHAR(3),
	initialNo BIGINT,	
	fiYear TINYINT CHECK (LEN(CAST(fiyear AS VARCHAR))=2),
	docNo AS docName+'/'+CAST(fiyear AS VARCHAR)+'/'+'0'
) ON [PRIMARY];
GO

INSERT INTO [mastcode].[DocInitialNo] (docName,initialNo,fiYear)
VALUES ('INV',1,25),
	('DBN',2,25),
	('CRN',3,25),	
	('SDB',4,25),
	('JWO',5,25),
	('DLC',6,25),
	('PYV',7,25),
	('RCV',8,25),
	('RCM',9,25),
	('FCN',10,25),
	('BNK',11,25)
GO

IF OBJECT_ID(N'mastcode.IsValidBillType',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidBillType];
GO

CREATE FUNCTION [mastcode].[IsValidBillType](@bt VARCHAR(1))
RETURNS BIT
AS
BEGIN
	
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[BillType] WHERE [bt] = @bt)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetBillType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetBillType];
GO
CREATE SYNONYM [mastcode].[uspGetBillType] FOR [UniDb].[mastcode].[spGetBillType]
GO

IF OBJECT_ID(N'mastcode.BillType') IS NOT NULL
	DROP SYNONYM [mastcode].[BillType];
GO
CREATE SYNONYM [mastcode].[BillType] FOR [UniDb].[mastcode].[ViBillType]
GO

IF OBJECT_ID(N'mastcode.IsValidDocReason',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidDocReason];
GO

CREATE FUNCTION [mastcode].[IsValidDocReason](@drId VARCHAR(2))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[DocReason] WHERE [drId] = @drId)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetDocReason') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetDocReason];
GO
CREATE SYNONYM [mastcode].[uspGetDocReason] FOR [UniDb].[mastcode].[spGetDocReason]
GO

IF OBJECT_ID(N'mastcode.DocReason') IS NOT NULL
	DROP SYNONYM [mastcode].[DocReason];
GO
CREATE SYNONYM [mastcode].[DocReason] FOR [UniDb].[mastcode].[ViDocReason]
GO

IF OBJECT_ID(N'mastcode.IsValidDocAgainst',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidDocAgainst];
GO

CREATE FUNCTION [mastcode].[IsValidDocAgainst](@daId VARCHAR(2))
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 'X' FROM [UniDb].[mastcode].[DocAgainst] WHERE [daId] = @daId)
		RETURN 1;

        RETURN 0;    
END
GO

IF OBJECT_ID(N'mastcode.uspGetDocAgainst') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetDocAgainst];
GO
CREATE SYNONYM [mastcode].[uspGetDocAgainst] FOR [UniDb].[mastcode].[spGetDocAgainst]
GO

IF OBJECT_ID(N'mastcode.DocAgainst') IS NOT NULL
	DROP SYNONYM [mastcode].[DocAgainst];
GO
CREATE SYNONYM [mastcode].[DocAgainst] FOR [UniDb].[mastcode].[ViDocAgainst]
GO

IF OBJECT_ID(N'mastcode.uspGetFcnType') IS NOT NULL
	DROP SYNONYM [mastcode].[uspGetFcnType];
GO
CREATE SYNONYM [mastcode].[uspGetFcnType] FOR [UniDb].[mastcode].[spGetFcnType]
GO

IF OBJECT_ID('mastcode.NewDocNo',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[NewDocNo];
GO

CREATE FUNCTION [mastcode].[NewDocNo](@docNo VARCHAR(16),@factor INT)
RETURNS VARCHAR(16)
AS
BEGIN
	DECLARE @newdocno VARCHAR(16)

	SET @newdocno = LEFT(@docNo,LEN(@docNo) - LEN(PARSENAME(REPLACE(@docNo, '/', '.'), 1))) +
			TRY_CAST(TRY_CAST(PARSENAME(REPLACE(@docNo, '/', '.'), 1) AS bigint) + @factor AS varchar)
	RETURN @newdocno
END
GO

IF OBJECT_ID(N'mastcode.Company',N'U') IS NOT NULL
	DROP TABLE [mastcode].[Company];
GO

CREATE TABLE [mastcode].[Company]
(
	cid VARCHAR(10) NOT NULL CONSTRAINT pk_sales_company_cid PRIMARY KEY (cid) DEFAULT (RIGHT('0'+CAST(MONTH(GETDATE()) AS VARCHAR),2)+CAST(FORMAT(GETDATE(), 'yy') AS VARCHAR)+LEFT(CAST(CAST(NEWID() AS VARBINARY(6)) AS Bigint),6)),
	compGstin VARCHAR(15) NULL CONSTRAINT ck_mastcode_company_compgstin CHECK ([mastcode].[isValidGstin](compGstin) > 0),
	legalName VARCHAR(100) NOT NULL,
	tradeName VARCHAR(100) NULL,
    compAdd VARCHAR(100) NOT NULL,
	compAdd1 VARCHAR(100) NULL,
	compCity VARCHAR(50) NOT NULL,    
	compStateCode SMALLINT NOT NULL CONSTRAINT ck_mastcode_company_compstatecode CHECK ([mastcode].[isValidState](compStateCode) > 0),
	compZipCode VARCHAR(6) NOT NULL,
	compCountryCode VARCHAR(2) NOT NULL CONSTRAINT ck_mastcode_company_compcountrycode CHECK ([mastcode].[isValidCountries](compCountryCode) > 0),
    compPhone VARCHAR(12) NULL,
    compEmail VARCHAR(100) NULL,
	compCIN VARCHAR(21) NULL, 
	compPAN VARCHAR(10) NULL CONSTRAINT ck_mastcode_company_comppan CHECK ([mastcode].[isValidPAN](compPAN) > 0),
	bankCode VARCHAR(10) NULL,
	bankName VARCHAR(50) NULL,
	accountNo VARCHAR(20) NULL,
	ifscCode VARCHAR(11) NULL,
	adCode VARCHAR(15) NULL,
	swiftCode VARCHAR(10) NULL,
	compMediaPath VARCHAR(100) NULL,
	compLogo VARCHAR(100) NULL,
	compBrandLogo VARCHAR(100) NULL,
	compDocLogo VARCHAR(100) NULL,
	compMedia VARCHAR(100) NULL,
	signImage VARCHAR(100) NULL,
	compDbName VARCHAR(155) NULL,
	clientCode VARCHAR(10) NULL, 
	productCode VARCHAR(10) NULL	
) ON [PRIMARY];
GO

IF OBJECT_ID(N'mastcode.AcGroups', N'U') IS NOT NULL
	DROP TABLE [mastcode].[AcGroups];
GO

CREATE TABLE [mastcode].[AcGroups]
(
	agCode VARCHAR(5) NOT NULL CONSTRAINT pk_mastcode_aggroups_agcode PRIMARY KEY,
	agDescription VARCHAR(50) NOT NULL CONSTRAINT uk_mastcode_aggroups_agdescription UNIQUE,
	mgcode VARCHAR(5) CONSTRAINT fk_mastcode_aggroup_mgcode REFERENCES [mastcode].[AcGroups](agCode),
	isTr VARCHAR(1) NOT NULL CONSTRAINT ck_mastcode_aggroups_istr CHECK (IsTr IN ('Y','N')),
	isPl VARCHAR(1) NOT NULL CONSTRAINT ck_mastcode_aggroups_ispl CHECK (IsPl IN ('Y','N')),
	isBl VARCHAR(1) NOT NULL CONSTRAINT ck_mastcode_aggroups_isbl CHECK (IsBl IN ('Y','N')),
	lastUpdated DATETIME NOT NULL DEFAULT CAST(CONVERT(VARCHAR(16), GETDATE(), 120) AS datetime),
	workstation VARCHAR(15)  NOT NULL DEFAULT CONVERT(VARCHAR(15), CONNECTIONPROPERTY('client_net_address')),
) ON [PRIMARY];
GO

IF OBJECT_ID(N'mastcode.LedgerCodes',N'U') IS NOT NULL
	DROP TABLE [mastcode].[LedgerCodes];
GO

CREATE TABLE [mastcode].[LedgerCodes]
(	
	lcode VARCHAR(10) NOT NULL CONSTRAINT pk_mastcode_ledgercodes_lcode PRIMARY KEY (LCode),
	lname VARCHAR(50) NOT NULL,
	ltype VARCHAR(1) NOT NULL, -- DROP DOWN PROC [mastcode].[uspGetLedgerType]
	agCode VARCHAR(5) NOT NULL CONSTRAINT fk_mastcode_ledgercodes_agcode REFERENCES [mastcode].[AcGroups](AgCode), -- DROP DOWN PROC EXEC [mastcode].[uspGetAcGroups]
	lstatus VARCHAR(1) NOT NULL CONSTRAINT df_mastcode_ledgercodes_lstatus DEFAULT 'A' CONSTRAINT ck_mastcode_ledgercodes_lstatus CHECK([mastcode].[IsValidLedgerStatus](lstatus) > 0), -- Drop Down PROC [mastcode].[uspGetLedgerStatus]
	remark VARCHAR(100) NULL,

	-- If lType != 'O' Then It is Mandetory 
	[add] VARCHAR(100) NULL,
	add1 VARCHAR(100) NULL,
	city VARCHAR(50) NULL,
	Stcd SMALLINT NULL CONSTRAINT fk_mastcode_ledgercodes_stcd CHECK (Stcd IS NULL OR [mastcode].[IsValidState](Stcd) > 0), -- DROP DOWN PROC [mastcode].[uspGetStates]
	zipCode VARCHAR(6) NULL,
	distance INT NULL DEFAULT 0,
	country VARCHAR(2) NULL CONSTRAINT ck_mastcode_ledgercodes_country CHECK (country IS NULL OR [mastcode].[IsValidCountries](Country) > 0), -- DROP DOWN PROC [mastcode].[uspGetCountries]

	phone VARCHAR(10) NULL,
	altPhone VARCHAR(10) NULL,
	email VARCHAR(50) NULL,
	
	crDays SMALLINT NULL DEFAULT 0,
	paymentTerm VARCHAR(100) NULL,
	SupTyp VARCHAR(10) NULL CONSTRAINT ck_mastcode_ledgercodes_suptype CHECK (SupTyp IS NULL OR [mastcode].[IsValidGstSupplyType](SupTyp) > 0), -- DROP DOWN PROC [mastcode].[uspGetGstSupplyType]
	regId VARCHAR(3) NULL CONSTRAINT ck_mastcode_ledgercodes_regid CHECK (regId IS NULL OR [mastcode].[IsValidGSTRegnType](regId) > 0), -- DROP DOWN EXEC [mastcode].[uspGetGSTRegnTYpe]
	Gstin VARCHAR(15) NULL CONSTRAINT ck_mastcode_ledgercodes_gstin CHECK (Gstin IS NULL OR [mastcode].[isValidGSTIN](Gstin)> 0), -- If lGSTType != 'URP' Then it is Mandetory
	rc VARCHAR(1) NOT NULL CHECK (rc IN ('Y','N')) DEFAULT 'N',
	isEcom VARCHAR(1) NOT NULL CHECK (isEcom IN ('Y','N')) DEFAULT 'N',
	tdsCode VARCHAR(10) NULL CONSTRAINT fk_mastcode_ledgercodes_tdscode CHECK (tdsCode IS NULL OR [mastcode].[IsValidTdsType](tdsCode) > 0), -- Drop Down Proc EXEC [mastcode].[uspGetTdsType]
	igstOnIntra VARCHAR(1) NULL CHECK (igstOnIntra IN ('Y','N')), -- Auto Populated From lState (State Code)

	-- If lType = 'V' Then It is Mandetory 
	bankAcNo VARCHAR(20) NULL,
	bankName VARCHAR(50) NULL,
	bankAcName VARCHAR(50) NULL,
	ifscCode VARCHAR(11) NULL,
	swiftCode VARCHAR(20) NULL,

	-- If lType = 'C' OR lType = 'B' Then It is Mandetory 
	discType VARCHAR(1) NULL CONSTRAINT fk_mastcode_ledgercodes_disctype FOREIGN KEY (discType) REFERENCES [mastcode].[SaleDiscountType](discType) DEFAULT 'Z', -- DROP DOWN PROC [mastcode].[uspGetSaleDiscountType]
	discRate DECIMAL(5,2) NOT NULL DEFAULT 0,
	loyaltyDisc DECIMAL(5,2) NOT NULL DEFAULT 0,
	paymentDisc DECIMAL(5,2) NOT NULL DEFAULT 0,

	lastUpdated DATETIME NOT NULL DEFAULT CAST(CONVERT(VARCHAR(16), GETDATE(), 120) AS datetime),
	workstation VARCHAR(15) NOT NULL,
	userid VARCHAR(30) NOT NULL
) ON [PRIMARY];
GO
 --CREATE UNIQUE INDEX IX_mastcode_employee_phone_NotNull ON [mastcode].[LedgerCodes] (phone) WHERE phone IS NOT NULL;
 --CREATE UNIQUE INDEX IX_mastcode_employee_altphone_NotNull ON [mastcode].[LedgerCodes] (altPhone) WHERE altPhone IS NOT NULL;
 -- Import
 --SELECT lcode, lname, ltype, agCode, lstatus, lRemark,b.bpAdd [add],b.bpAdd1 add1,b.bpCity city,b.bpState Stcd,b.bpZipCode zipCode,b.bpDistance distance,b.bpCountry country, b.bpPhone phone,b.bpWhatsApp altPhone,b.bpEmail email, ti.crDays crDays, ti.paymentTerm paymentTerm, SupTyp,CASE WHEN b.bpGSTType = 'U' THEN 'URP' WHEN b.bpGSTType = 'R' THEN 'REG' END regId, b.bpGSTIN Gstin, rc, 'N' isEcom,b.tdsCode tdsCode,ti.bankAcNo bankAcNo,ti.bankName bankName, ti.bankAcName bankAcName,ti.ifscCode ifscCode, swiftCode, discType, discRate, loyaltyDisc, paymentDisc FROM [mastcode].[LedgerCodes] lc
 --INNER JOIN [mastcode].[bp] b ON lc.lCode = b.bpCode
 --LEFT OUTER JOIN [mastcode].[BPPayNTaxInfo] ti ON lc.lCode = ti.bpCode
 --where lType='C'
GO

IF OBJECT_ID(N'mastcode.ViLedgerCodes',N'V') IS NOT NULL
	DROP VIEW [mastcode].[ViLedgerCodes];
GO

CREATE VIEW [mastcode].[ViLedgerCodes]
AS
SELECT lcode, lname, ltype, lc.agCode, ag.agDescription, lstatus, remark, [add], add1, city, lc.Stcd, sta.sname stateName, zipCode, distance, lc.country, cou.cname countryName, phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin, rc, isEcom, lc.tdsCode, tds.[description], igstOnIntra, bankAcNo, bankName, bankAcName, ifscCode, swiftCode, discType, discRate, loyaltyDisc, paymentDisc, lc.lastUpdated, lc.workstation, lc.userid FROM [mastcode].[LedgerCodes] lc
INNER JOIN [mastcode].[AcGroups] ag ON lc.agCode = ag.agCode 
LEFT OUTER JOIN [mastcode].[States] sta ON lc.Stcd = sta.[sid]
LEFT OUTER JOIN [mastcode].[Countries] cou ON lc.country = cou.cid
LEFT OUTER JOIN [mastcode].[TdsType] tds ON lc.tdsCode = tds.tdsCode
GO

IF OBJECT_ID(N'mastcode.CustomerShipping',N'U') IS NOT NULL
	DROP TABLE [mastcode].[CustomerShipping];
GO

CREATE TABLE [mastcode].[CustomerShipping]
(
	shipCode BIGINT NOT NULL CONSTRAINT pk_mastcode_customershipping_shipcode PRIMARY KEY (shipCode) IDENTITY (1,1),
	lcode VARCHAR(10) NOT NULL, 
	Gstin VARCHAR(15) NULL,
	LglNm VARCHAR(100) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(50) NOT NULL,
	Stcd SMALLINT NOT NULL, -- Drop Down [mastcode].[States]
	Pin VARCHAR(6) NOT NULL,	
	CntCode VARCHAR(2) NOT NULL, -- Drop Down [mastcode].[Countries]
	Phone VARCHAR(10) NULL,
	CONSTRAINT fk_mastcode_customershipping_lcode FOREIGN KEY (lcode) REFERENCES [mastcode].[LedgerCodes](lcode),
	CONSTRAINT ck_mastcode_customershipping_stcd CHECK ([mastcode].[IsValidState]([Stcd]) > 0),
	CONSTRAINT ck_mastcode_customershipping_cntcode CHECK([mastcode].[IsValidCountries](CntCode) > 0),
	CONSTRAINT ck_mastcode_customershipping_gstin CHECK ([mastcode].[IsValidGSTIN](Gstin) > 0)
) ON [PRIMARY];
GO

CREATE OR ALTER VIEW [mastcode].[ViCustomerShipping]
AS
SELECT shipCode, lcode, Gstin, LglNm, Addr1, Addr2, Loc, States.Stcd, States.sname stateName, Pin, cs.CntCode, Countries.cname countryName, Phone FROM [mastcode].[CustomerShipping] cs
INNER JOIN [mastcode].[States] ON cs.Stcd = States.[sid]
INNER JOIN [mastcode].[Countries] ON cs.CntCode = Countries.cid
GO

IF OBJECT_ID(N'mastcode.Carrier',N'U') IS NOT NULL
	DROP TABLE [mastcode].[Carrier];
GO

CREATE TABLE [mastcode].[Carrier] 
(
    carId bigint NOT NULL PRIMARY KEY IDENTITY(1001,1),
    carName varchar(50) NOT NULL UNIQUE,
    carGSTIN varchar(15) NULL CHECK (carGSTIN IS NULL OR [mastcode].[IsValidGSTIN](carGSTIN) > 0),
    carAdd varchar(100) NOT NULL,
    carAdd1 varchar(100) NULL,
    carCity varchar(50) NOT NULL,
    carStateName varchar(50) NOT NULL,
    carZipCode varchar(6) NOT NULL,
    carCPerson varchar(50) NULL,
    carPhone varchar(30) NULL
)ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.Opening',N'U') IS NOT NULL
	DROP TABLE [fiac].[Opening];
GO

CREATE TABLE [fiac].[Opening]
(
    ObId BIGINT NOT NULL IDENTITY (1,1) PRIMARY KEY,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_Opening_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode),
    Fy   VARCHAR(9) NOT NULL CONSTRAINT fk_fiac_Opening_Fy FOREIGN KEY (Fy) REFERENCES [mastcode].[FinancialYear](Fy),
    DrAmt  DECIMAL(18,2) NOT NULL DEFAULT 0,
    CrAmt  DECIMAL(18,2) NOT NULL DEFAULT 0,
    CONSTRAINT fk_fiac_Opening_lcode_fy UNIQUE (lcode, Fy),
	CONSTRAINT ck_fiac_Opening_DrAmtCrAmt CHECK (
        (DrAmt > 0 AND CrAmt = 0) OR
        (CrAmt > 0 AND DrAmt = 0) OR
        (DrAmt = 0 AND CrAmt = 0)
    )
)ON [PRIMARY];
GO

CREATE FUNCTION [gl].[GlDateValidity](@fDt DATETIME,@tDt DATETIME)
RETURNS BIT
AS
BEGIN
	DECLARE @isValid BIT = 0

	IF EXISTS (SELECT 1 FROM [mastcode].[FinancialYear] WHERE @fDt BETWEEN SDate AND EDate 
				AND @tDt BETWEEN SDate AND EDate
				AND IsActive = 1)
		SET @isValid = 1;
	
	RETURN @isValid;
END
GO

IF OBJECT_ID(N'gl.GeneralLedger',N'U') IS NOT NULL
	DROP TABLE [gl].[GeneralLedger];
GO

CREATE TABLE [gl].[GeneralLedger]
(
    glId BIGINT IDENTITY(1,1) PRIMARY KEY,
    docId BIGINT NOT NULL,
    docType VARCHAR(3) NOT NULL,
    tranDate DATE NOT NULL,
    lcode VARCHAR(10) NOT NULL,
    drAmount DECIMAL(15,2) DEFAULT 0,
    crAmount  DECIMAL(15,2) DEFAULT 0,
    narration VARCHAR(100) NULL,
    createdBy NVARCHAR(50) DEFAULT SUSER_SNAME(),
    createdOn DATETIME DEFAULT GETDATE(),
	isBill BIT NOT NULL DEFAULT 0,
	adjusted DECIMAL(15,2) NOT NULL DEFAULT 0,
	unadjusted AS (CASE WHEN isBill = 1 AND docType IN ('INW','INV') THEN (ISNULL(crAmount,0) - ISNULL(adjusted,0)) ELSE 0 END)
	CONSTRAINT uk_gl_generalledger UNIQUE (docId,docType,lcode)
) ON [PRIMARY];
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspAddCompany]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
	IF @json IS NULL 
		OR LTRIM(RTRIM(@json)) = '' 
		OR ISJSON(@json) <> 1
		THROW 61001, 'Invalid or missing JSON input.', 1;


        DECLARE @Input TABLE (
			cid				 VARCHAR(10),
            compGstin        VARCHAR(15),
            legalName        VARCHAR(100),
            tradeName        VARCHAR(100),
            compAdd          VARCHAR(100),
            compAdd1         VARCHAR(100),
            compCity         VARCHAR(50),
            compStateCode    SMALLINT,
            compZipCode      VARCHAR(6),
            compCountryCode  VARCHAR(2),
            compPhone        VARCHAR(12),
            compEmail        VARCHAR(100),
            compCIN          VARCHAR(21),
            compPAN          VARCHAR(10),
            bankCode         VARCHAR(10),
            bankName         VARCHAR(50),
            accountNo        VARCHAR(20),
            ifscCode         VARCHAR(11),
            adCode           VARCHAR(15),
            swiftCode        VARCHAR(10),
            compMediaPath    VARCHAR(100),
            compLogo         VARCHAR(100),
            compBrandLogo    VARCHAR(100),
            compDocLogo      VARCHAR(100),
            compMedia        VARCHAR(100),
            signImage        VARCHAR(100),
            compDbName       VARCHAR(155),
            clientCode       VARCHAR(10),
            productCode      VARCHAR(10)
        );
		DECLARE @Inserted TABLE (cid VARCHAR(10));
        -- Parse JSON array
        INSERT INTO @Input (compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
			compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
			bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
			compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
			signImage, compDbName, clientCode, productCode)
        SELECT compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
			compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
			bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
			compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
			signImage, compDbName, clientCode, productCode
        FROM OPENJSON(@json)
        WITH (
            compGstin        VARCHAR(15),
            legalName        VARCHAR(100),
            tradeName        VARCHAR(100),
            compAdd          VARCHAR(100),
            compAdd1         VARCHAR(100),
            compCity         VARCHAR(50),
            compStateCode    SMALLINT,
            compZipCode      VARCHAR(6),
            compCountryCode  VARCHAR(2),
            compPhone        VARCHAR(12),
            compEmail        VARCHAR(100),
            compCIN          VARCHAR(21),
            compPAN          VARCHAR(10),
            bankCode         VARCHAR(10),
            bankName         VARCHAR(50),
            accountNo        VARCHAR(20),
            ifscCode         VARCHAR(11),
            adCode           VARCHAR(15),
            swiftCode        VARCHAR(10),
            compMediaPath    VARCHAR(100),
            compLogo         VARCHAR(100),
            compBrandLogo    VARCHAR(100),
            compDocLogo      VARCHAR(100),
            compMedia        VARCHAR(100),
            signImage        VARCHAR(100),
            compDbName       VARCHAR(155),
            clientCode       VARCHAR(10),
            productCode      VARCHAR(10)
        );

        -- Specific validations
        IF EXISTS (
            SELECT 1 FROM @Input
            GROUP BY compGstin,legalName HAVING COUNT(*) > 1
        )
            THROW 50014, 'Validation failed: Duplicate GSTIN and Leagal Name found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE compGstin IS NOT NULL AND [mastcode].[isValidGstin](compGstin) <= 0
        )
            THROW 50011, 'Validation failed: Invalid GSTIN found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE [mastcode].[isValidState](compStateCode) <= 0
        )
            THROW 50012, 'Validation failed: Invalid State Code found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE [mastcode].[isValidCountries](compCountryCode) <= 0
        )
            THROW 50013, 'Validation failed: Invalid Country Code found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE compPAN IS NOT NULL AND [mastcode].[isValidPAN](compPAN) <= 0
        )
            THROW 50014, 'Validation failed: Invalid PAN found.', 1;

        BEGIN TRANSACTION;
        -- Insert with auto-generated cid
        INSERT INTO [mastcode].[Company] (
			compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
            compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
            bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
            compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
            signImage, compDbName, clientCode, productCode
			) OUTPUT INSERTED.cid INTO @Inserted
        SELECT compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
            compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
            bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
            compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
            signImage, compDbName, clientCode, productCode
        FROM @Input;

        IF @@ROWCOUNT = 0
            THROW 50015, 'Insert failed: No rows inserted.', 1;

        COMMIT TRANSACTION;
		-- Return inserted cids
        SELECT cid FROM @Inserted;
    
	END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
			ROLLBACK;
        
		EXECUTE [dbo].[uspLogError];
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspUpdateCompany]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
		IF @json IS NULL 
			OR LTRIM(RTRIM(@json)) = '' 
			OR ISJSON(@json) <> 1
			THROW 61001, 'Invalid or missing JSON input.', 1;

        DECLARE @Input TABLE (
            cid              VARCHAR(10),
            compGstin        VARCHAR(15),
            legalName        VARCHAR(100),
            tradeName        VARCHAR(100),
            compAdd          VARCHAR(100),
            compAdd1         VARCHAR(100),
            compCity         VARCHAR(50),
            compStateCode    SMALLINT,
            compZipCode      VARCHAR(6),
            compCountryCode  VARCHAR(2),
            compPhone        VARCHAR(12),
            compEmail        VARCHAR(100),
            compCIN          VARCHAR(21),
            compPAN          VARCHAR(10),
            bankCode         VARCHAR(10),
            bankName         VARCHAR(50),
            accountNo        VARCHAR(20),
            ifscCode         VARCHAR(11),
            adCode           VARCHAR(15),
            swiftCode        VARCHAR(10),
            compMediaPath    VARCHAR(100),
            compLogo         VARCHAR(100),
            compBrandLogo    VARCHAR(100),
            compDocLogo      VARCHAR(100),
            compMedia        VARCHAR(100),
            signImage        VARCHAR(100),
            compDbName       VARCHAR(155),
            clientCode       VARCHAR(10),
            productCode      VARCHAR(10)
        );

        DECLARE @Updated TABLE (cid VARCHAR(10));

        -- Parse JSON array
        INSERT INTO @Input (
            cid, compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
            compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
            bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
            compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
            signImage, compDbName, clientCode, productCode
        )
        SELECT
            cid, compGstin, legalName, tradeName, compAdd, compAdd1, compCity, compStateCode,
            compZipCode, compCountryCode, compPhone, compEmail, compCIN, compPAN,
            bankCode, bankName, accountNo, ifscCode, adCode, swiftCode,
            compMediaPath, compLogo, compBrandLogo, compDocLogo, compMedia,
            signImage, compDbName, clientCode, productCode
        FROM OPENJSON(@json)
        WITH (
            cid              VARCHAR(10),
            compGstin        VARCHAR(15),
            legalName        VARCHAR(100),
            tradeName        VARCHAR(100),
            compAdd          VARCHAR(100),
            compAdd1         VARCHAR(100),
            compCity         VARCHAR(50),
            compStateCode    SMALLINT,
            compZipCode      VARCHAR(6),
            compCountryCode  VARCHAR(2),
            compPhone        VARCHAR(12),
            compEmail        VARCHAR(100),
            compCIN          VARCHAR(21),
            compPAN          VARCHAR(10),
            bankCode         VARCHAR(10),
            bankName         VARCHAR(50),
            accountNo        VARCHAR(20),
            ifscCode         VARCHAR(11),
            adCode           VARCHAR(15),
            swiftCode        VARCHAR(10),
            compMediaPath    VARCHAR(100),
            compLogo         VARCHAR(100),
            compBrandLogo    VARCHAR(100),
            compDocLogo      VARCHAR(100),
            compMedia        VARCHAR(100),
            signImage        VARCHAR(100),
            compDbName       VARCHAR(155),
            clientCode       VARCHAR(10),
            productCode      VARCHAR(10)
        );

        -- Specific validations
		IF EXISTS (
			SELECT cid FROM @Input
			EXCEPT
			SELECT cid FROM [mastcode].[Company]
		)
			THROW 50027, 'Update aborted: One or more cid values not found in target table.', 1;

		IF EXISTS (
            SELECT 1 FROM @Input
            GROUP BY compGstin, legalName HAVING COUNT(*) > 1
        )
            THROW 50024, 'Validation failed: Duplicate GSTIN and Legal Name found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE compGstin IS NOT NULL AND [mastcode].[isValidGstin](compGstin) <= 0
        )
            THROW 50021, 'Validation failed: Invalid GSTIN found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE [mastcode].[isValidState](compStateCode) <= 0
        )
            THROW 50022, 'Validation failed: Invalid State Code found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE [mastcode].[isValidCountries](compCountryCode) <= 0
        )
            THROW 50023, 'Validation failed: Invalid Country Code found.', 1;

        IF EXISTS (
            SELECT 1 FROM @Input
            WHERE compPAN IS NOT NULL AND [mastcode].[isValidPAN](compPAN) <= 0
        )
            THROW 50024, 'Validation failed: Invalid PAN found.', 1;

        BEGIN TRANSACTION;
		-- MERGE for bulk update
        MERGE [mastcode].[Company] AS Target
        USING @Input AS Source
        ON Target.cid = Source.cid
        WHEN MATCHED THEN
            UPDATE SET
                Target.compGstin       = Source.compGstin,
                Target.legalName       = Source.legalName,
                Target.tradeName       = Source.tradeName,
                Target.compAdd         = Source.compAdd,
                Target.compAdd1        = Source.compAdd1,
                Target.compCity        = Source.compCity,
                Target.compStateCode   = Source.compStateCode,
                Target.compZipCode     = Source.compZipCode,
                Target.compCountryCode = Source.compCountryCode,
                Target.compPhone       = Source.compPhone,
                Target.compEmail       = Source.compEmail,
                Target.compCIN         = Source.compCIN,
                Target.compPAN         = Source.compPAN,
                Target.bankCode        = Source.bankCode,
                Target.bankName        = Source.bankName,
                Target.accountNo       = Source.accountNo,
                Target.ifscCode        = Source.ifscCode,
                Target.adCode          = Source.adCode,
                Target.swiftCode       = Source.swiftCode,
                Target.compMediaPath   = COALESCE(Source.compMediaPath,Target.compMediaPath),
                Target.compLogo        = COALESCE(Source.compLogo,Target.compLogo),
                Target.compBrandLogo   = COALESCE(Source.compBrandLogo,Target.compBrandLogo),
                Target.compDocLogo     = COALESCE(Source.compDocLogo,Target.compDocLogo),
                Target.compMedia       = COALESCE(Source.compMedia,Target.compMedia),
                Target.signImage       = COALESCE(Source.signImage,Target.signImage),
                Target.compDbName      = Source.compDbName,
                Target.clientCode      = Source.clientCode,
                Target.productCode     = Source.productCode
        OUTPUT INSERTED.cid INTO @Updated;

        IF @@ROWCOUNT = 0
            THROW 50025, 'Update failed: No matching rows found.', 1;

        COMMIT TRANSACTION;

        -- Return updated cids
        SELECT cid FROM @Updated;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK;

        EXECUTE [dbo].[uspLogError];
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspDeleteCompany]
    @cid VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DELETE FROM [mastcode].[Company]
        WHERE cid = @cid;

        IF @@ROWCOUNT = 0
            THROW 50006, 'Delete failed: no matching cid found.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 
            ROLLBACK;

        EXEC [dbo].[uspLogError]
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspGetCompany]
    @json NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @cid VARCHAR(10),
		@legalName VARCHAR(100);

    -- Parse JSON input
    SET @cid = JSON_VALUE(@json,'$.cid')
    SET @legalName  = JSON_VALUE(@json,'$.legalName')

    -- Return matching companies
    SELECT
        cid,
        compGstin,
        legalName,
        tradeName,
        compAdd,
        compAdd1,
        compCity,
        compStateCode,
        compZipCode,
        compCountryCode,
        compPhone,
        compEmail,
        compCIN,
        compPAN,
        bankCode,
        bankName,
        accountNo,
        ifscCode,
        adCode,
        swiftCode,
        compMediaPath,
        compLogo,
        compBrandLogo,
        compDocLogo,
        compMedia,
        signImage,
        compDbName,
        clientCode,
        productCode
    FROM [mastcode].[Company]
    WHERE
        (@cid IS NULL OR cid = @cid) AND
        (@legalName IS NULL OR legalName LIKE '%'+@legalName+'%')
    ORDER BY legalName;
END;
GO

IF OBJECT_ID(N'mastcode.uspAddFinancialYear',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspAddFinancialYear];
GO

CREATE PROCEDURE [mastcode].[uspAddFinancialYear]
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 50001, 'Input JSON is required.', 1;

        IF ISJSON(@json) <> 1
            THROW 50002, 'Invalid JSON.', 1;

        DECLARE @Input TABLE
        (
            RowNo INT IDENTITY(1,1) PRIMARY KEY,
            Fy       VARCHAR(9)  NULL,
            SDate    DATE        NULL,
            EDate    DATE        NULL,
            IsActive BIT         NULL
        );

        INSERT INTO @Input (Fy, SDate, EDate, IsActive)
        SELECT  j.Fy,
                j.SDate,
                j.EDate,
                ISNULL(j.IsActive, 1)
        FROM OPENJSON(@json, '$')
        WITH (
            Fy       VARCHAR(9) '$.Fy',
            SDate    DATE       '$.SDate',
            EDate    DATE       '$.EDate',
            IsActive BIT        '$.IsActive'
        ) AS j;

        -- message variable
        DECLARE @msg NVARCHAR(MAX);
		-- NOT NULL CHECK
        IF EXISTS (SELECT 1 FROM @Input WHERE Fy IS NULL OR SDate IS NULL OR EDate IS NULL)
        BEGIN
            SET @msg = 'One or more rows are missing required fields (Fy, SDate, EDate).';
            THROW 50003, @msg, 1;
        END

        -- Duplicate FYs within payload
        IF EXISTS (
            SELECT Fy FROM @Input GROUP BY Fy HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dupInPayload NVARCHAR(MAX);
            SELECT @dupInPayload = STRING_AGG(Fy, ', ')
            FROM (
                SELECT DISTINCT Fy FROM @Input GROUP BY Fy
                HAVING COUNT(*) > 1
            ) d;

            SET @msg = 'Duplicate Fy : ' + ISNULL(@dupInPayload,'');
            THROW 50004, @msg, 1;
        END
		
        -- FYs Already exist in table
        IF EXISTS (SELECT 1 FROM @Input i JOIN [mastcode].[FinancialYear] f ON f.Fy = i.Fy)
        BEGIN
            DECLARE @existsList NVARCHAR(MAX);
            SELECT @existsList = STRING_AGG(x.Fy, ', ')
            FROM (
                SELECT DISTINCT i.Fy FROM @Input i
                JOIN [mastcode].[FinancialYear] f ON f.Fy = i.Fy
            ) x;

            SET @msg = 'Fy Already Exists: ' + ISNULL(@existsList,'');
            THROW 50005, @msg, 1;
        END

        BEGIN TRAN;

            INSERT INTO [mastcode].[FinancialYear] (Fy, SDate, EDate, IsActive)
            SELECT Fy, SDate, EDate, IsActive
            FROM @Input;

            SET @STATUS = @@ROWCOUNT;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
		-- Rollback any active or uncommittable transactions before  
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        
		-- inserting information in the ErrorLog
		EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		THROW 
    END CATCH
END
GO

IF OBJECT_ID(N'mastcode.uspUpdateFinancialYear',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspUpdateFinancialYear];
GO

CREATE PROCEDURE [mastcode].[uspUpdateFinancialYear]
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 50011, 'Input JSON is required.', 1;

        IF ISJSON(@json) <> 1
            THROW 50012, 'Invalid JSON.', 1;

        DECLARE @Input TABLE
        (
            RowNo INT IDENTITY(1,1) PRIMARY KEY,
            Fy       VARCHAR(9)  NULL,
            SDate    DATE        NULL,
            EDate    DATE        NULL,
            IsActive BIT         NULL
        );

        INSERT INTO @Input (Fy, SDate, EDate, IsActive)
        SELECT  j.Fy,
                j.SDate,
                j.EDate,
                j.IsActive
        FROM OPENJSON(@json, '$')
        WITH (
            Fy       VARCHAR(9) '$.Fy',
            SDate    DATE       '$.SDate',
            EDate    DATE       '$.EDate',
            IsActive BIT        '$.IsActive'
        ) AS j;

        DECLARE @msg NVARCHAR(MAX);

        IF EXISTS (SELECT 1 FROM @Input WHERE Fy IS NULL)
        BEGIN
            SET @msg = 'Fy is required for update.';
            THROW 50013, @msg, 1;
        END

        -- Duplicate FYs within request payload
        IF EXISTS (
            SELECT Fy FROM @Input GROUP BY Fy HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dupUpdPayload NVARCHAR(MAX);
            SELECT @dupUpdPayload = STRING_AGG(Fy, ', ')
            FROM (
                SELECT DISTINCT Fy
                FROM @Input
                GROUP BY Fy
                HAVING COUNT(*) > 1
            ) d;

            SET @msg = 'Duplicate Fy in update payload: ' + ISNULL(@dupUpdPayload,'');
            THROW 50014, @msg, 1;
        END

        -- FYs that do NOT exist in table → throw
        IF EXISTS (
            SELECT 1 FROM @Input i 
			LEFT JOIN [mastcode].[FinancialYear] f ON f.Fy = i.Fy
            WHERE f.Fy IS NULL
        )
        BEGIN
            DECLARE @missingList NVARCHAR(MAX);
            SELECT @missingList = STRING_AGG(m.Fy, ', ')
            FROM (
                SELECT DISTINCT i.Fy
                FROM @Input i
                LEFT JOIN [mastcode].[FinancialYear] f ON f.Fy = i.Fy
                WHERE f.Fy IS NULL
            ) m;

            SET @msg = 'Fy not found for update: ' + ISNULL(@missingList,'');
            THROW 50015, @msg, 1;
        END

        BEGIN TRAN;

            UPDATE f
            SET f.SDate   = COALESCE(i.SDate, f.SDate),
                f.EDate   = COALESCE(i.EDate, f.EDate),
                f.IsActive= COALESCE(i.IsActive, f.IsActive)
            FROM [mastcode].[FinancialYear] f
            JOIN @Input i ON i.Fy = f.Fy;

            SET @STATUS = @@ROWCOUNT;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;

        -- Throw original error
		EXECUTE [dbo].[uspLogError];  
		SET @STATUS = 0;  

        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'mastcode.uspDeleteFinancialYear',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspDeleteFinancialYear];
GO

CREATE PROCEDURE [mastcode].[uspDeleteFinancialYear]
    @Fy VARCHAR(9),
    @STATUS SMALLINT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
	SET XACT_ABORT ON;
    
	BEGIN TRY
        BEGIN TRAN;
		DELETE [mastcode].[FinancialYear]
        WHERE Fy = @Fy;

		DECLARE @rowAffected INT = @@ROWCOUNT;
        IF @rowAffected > 0
		BEGIN 
			COMMIT;
			SET @status = 1;
		END
		ELSE
		BEGIN
			ROLLBACK;
			SET @status = 0;
			THROW 50003, 'No new records were inserted.', 1;
		END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        EXECUTE [dbo].[uspLogError];
        SET @status = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'mastcode.uspGetFinancialYear',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetFinancialYear];
GO

CREATE PROCEDURE [mastcode].[uspGetFinancialYear]
	@json NVARCHAR(100) = null
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Fy VARCHAR(9) = NULL,
		@IsActive BIT = NULL

	IF @json IS NOT NULL
    BEGIN
		SELECT @Fy = Fy,@IsActive = IsActive FROM OPENJSON(@json,'$')
		WITH (Fy VARCHAR(9) '$.Fy',
			IsActive BIT '$.IsActive') j
	END	
	SELECT fyn.* FROM [mastcode].[FinancialYear] fyn 
		WHERE (@Fy IS NULL OR fyn.Fy = @Fy) AND (@IsActive IS NULL OR fyn.IsActive = @IsActive)
			ORDER BY Fy;

END
GO

IF OBJECT_ID(N'mastcode.tr_FinancialYear',N'TR') IS NOT NULL
	DROP TRIGGER [mastcode].[tr_FinancialYear];
GO

CREATE TRIGGER [mastcode].[tr_FinancialYear] ON [mastcode].[FinancialYear]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM inserted
        WHERE 
            DATEPART(DAY, SDate) <> 1 OR DATEPART(MONTH, SDate) <> 4 OR
            DATEPART(DAY, EDate) <> 31 OR DATEPART(MONTH, EDate) <> 3 OR
            (CAST(LEFT(Fy,4) AS INT) + 1) <> CAST(RIGHT(Fy,4) AS INT) OR
            YEAR(SDate) <> CAST(LEFT(Fy,4) AS INT) OR
            YEAR(EDate) <> CAST(RIGHT(Fy,4) AS INT)
    )
    BEGIN
        RAISERROR('Invalid Financial Year: Must be 1-Apr to 31-Mar and match FinYearCode (YYYY-YYYY)', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    IF EXISTS (
        SELECT 1
        FROM deleted d
        WHERE d.IsActive = 1
          AND NOT EXISTS (
              SELECT 1 FROM [mastcode].[FinancialYear]
              WHERE IsActive = 1
          )
    )
    BEGIN
        RAISERROR('Cannot delete the last active financial year.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END

    DECLARE @LatestActivated VARCHAR(9);
    SELECT @LatestActivated = MAX(Fy)
    FROM inserted
    WHERE IsActive = 1;

    IF @LatestActivated IS NOT NULL
    BEGIN
        UPDATE [mastcode].[FinancialYear]
        SET IsActive = CASE WHEN Fy = @LatestActivated THEN 1 ELSE 0 END;
    END

    IF NOT EXISTS (SELECT 1 FROM [mastcode].[FinancialYear] WHERE IsActive = 1)
    BEGIN
        RAISERROR('At least one financial year must be active.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

IF OBJECT_ID(N'mastcode.IsValidFinYearDate',N'FN') IS NOT NULL
	DROP FUNCTION [mastcode].[IsValidFinYearDate];
GO

CREATE FUNCTION [mastcode].[IsValidFinYearDate]
(
    @tranDate DATE
)
RETURNS BIT
AS
BEGIN
    DECLARE @result BIT = 0;

    IF EXISTS (SELECT 'X' FROM [mastcode].[FinancialYear] 
		WHERE IsActive = 1 AND @TranDate BETWEEN SDate AND EDate)
        SET @result = 1;

    RETURN @result;
END;
GO

IF OBJECT_ID('[mastcode].[uspAddAcGroups]', 'P') IS NOT NULL
    DROP PROCEDURE [mastcode].[uspAddAcGroups];
GO

CREATE PROCEDURE [mastcode].[uspAddAcGroups]
    @json NVARCHAR(MAX),
    @status SMALLINT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @now DATETIME = GETDATE();
    DECLARE @clientIP VARCHAR(15);
	SELECT @clientIP = client_net_address
		FROM sys.dm_exec_connections WHERE session_id = @@SPID;

    DECLARE @errorMessage NVARCHAR(4000);

    BEGIN TRY
        DECLARE @Input TABLE (
            agCode VARCHAR(5),
            agDescription VARCHAR(50),
            mgcode VARCHAR(5),
            isTr VARCHAR(1),
            isPl VARCHAR(1),
            isBl VARCHAR(1),
            lastUpdated DATETIME,
            workstation VARCHAR(15)
        );

        INSERT INTO @Input (agCode, agDescription, mgcode, isTr, isPl, isBl, lastUpdated, workstation)
        SELECT agCode, agDescription, mgcode, isTr, isPl, isBl, @now, @clientIP FROM OPENJSON(@json)
        WITH (
            agCode VARCHAR(5),
            agDescription VARCHAR(50),
            mgcode VARCHAR(5),
            isTr VARCHAR(1),
            isPl VARCHAR(1),
            isBl VARCHAR(1)
        );

		-- Check Not Null
		SET @errorMessage = NULL;
		SELECT @errorMessage = STRING_AGG(agCode, ', ')
		FROM @Input
			WHERE agCode IS NULL 
			OR agDescription IS NULL 
			OR isTr IS NULL 
			OR isPl IS NULL 
			OR isBl IS NULL;

		IF @errorMessage IS NOT NULL
		BEGIN
			SET @errorMessage = 'Missing required fields for agCodes: ' + @errorMessage;
			THROW 50011, @errorMessage, 1;
		END

        -- Already Exists
		SET @errorMessage = NULL;
		SELECT @errorMessage = STRING_AGG(i.agCode, ', ')
        FROM @Input i
        INNER JOIN [mastcode].[AcGroups] a ON i.agCode = a.agCode;

        IF @errorMessage IS NOT NULL
        BEGIN
            SET @errorMessage = 'Ac Group: ' + @errorMessage + ' already exists';
            THROW 50001, @errorMessage, 1;
        END

        SET @errorMessage = NULL;

        SELECT @errorMessage = STRING_AGG(agCode, ', ')
        FROM @Input
        GROUP BY agCode
        HAVING COUNT(*) > 1;

        IF @errorMessage IS NOT NULL
        BEGIN
            SET @errorMessage = 'Ac Group: ' + @errorMessage + ' are duplicate';
            THROW 50001, @errorMessage, 1;
        END
        
		BEGIN TRANSACTION;
        
		INSERT INTO [mastcode].[AcGroups] (agCode, agDescription, mgcode, isTr, isPl, isBl, lastUpdated, workstation)
        SELECT agCode, agDescription, mgcode, isTr, isPl, isBl, lastUpdated, workstation FROM @Input;

		DECLARE @rowAffected INT = @@ROWCOUNT;
        IF @rowAffected > 0
		BEGIN 
			COMMIT;
			SET @status = 1;
		END
		ELSE
		BEGIN
			ROLLBACK;
			SET @status = 0;
			THROW 50003, 'No new records were inserted.', 1;
		END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        EXECUTE [dbo].[uspLogError];
        SET @status = 0;
        THROW;
    END CATCH
END;
GO

--Test Case
--DECLARE @status SMALLINT;
--EXEC [mastcode].[uspAddAcGroups]
--    @json = N'[
--        {"agCode":"A001","agDescription":"Parent Group","mgcode":null,"isTr":"Y","isPl":"N","isBl":"Y"},
--        {"agCode":"A002","agDescription":"Child Group","mgcode":"A001","isTr":"N","isPl":"Y","isBl":"N"}
--    ]',
--    @status = @status OUTPUT;

--SELECT @status AS ResultStatus;
--SELECT * from [mastcode].[AcGroups]
--GO

IF OBJECT_ID('[mastcode].[uspUpdateAcGroups]', 'P') IS NOT NULL
    DROP PROCEDURE [mastcode].[uspUpdateAcGroups];
GO

CREATE PROCEDURE [mastcode].[uspUpdateAcGroups]
    @json NVARCHAR(MAX),
    @status SMALLINT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errorMessage NVARCHAR(4000);
    DECLARE @rowAffected INT;

    BEGIN TRY
        BEGIN TRANSACTION;

		DECLARE @now DATETIME = GETDATE();
		DECLARE @clientIP VARCHAR(15);
		SELECT @clientIP = client_net_address
		FROM sys.dm_exec_connections WHERE session_id = @@SPID;

        DECLARE @Input TABLE (
            agCode VARCHAR(5),
            agDescription VARCHAR(50),
            mgcode VARCHAR(5),
            isTr VARCHAR(1),
            isPl VARCHAR(1),
            isBl VARCHAR(1),
            lastUpdated DATETIME,
            workstation VARCHAR(15)
        );

        INSERT INTO @Input (agCode, agDescription, mgcode, isTr, isPl, isBl, lastUpdated, workstation)
        SELECT agCode, agDescription, mgcode, isTr, isPl, isBl, @now, @clientIP FROM OPENJSON(@json)
        WITH (
            agCode VARCHAR(5),
            agDescription VARCHAR(50),
            mgcode VARCHAR(5),
            isTr VARCHAR(1),
            isPl VARCHAR(1),
            isBl VARCHAR(1)
        );

		-- Check Not Null
		SET @errorMessage = NULL;
		SELECT @errorMessage = STRING_AGG(agCode, ', ')
		FROM @Input
			WHERE agCode IS NULL 
			OR agDescription IS NULL 
			OR isTr IS NULL 
			OR isPl IS NULL 
			OR isBl IS NULL;

		IF @errorMessage IS NOT NULL
		BEGIN
			SET @errorMessage = 'Missing required fields for agCodes: ' + @errorMessage;
			THROW 50011, @errorMessage, 1;
		END

        -- Validate existence
		SET @errorMessage = NULL;
        SELECT @errorMessage = STRING_AGG(i.agCode, ', ')
        FROM @Input i
        WHERE NOT EXISTS (
            SELECT 1 FROM [mastcode].[AcGroups] a WHERE a.agCode = i.agCode
        );

        IF @errorMessage IS NOT NULL
        BEGIN
            SET @errorMessage = 'Ac Group: ' + @errorMessage + ' not found for update';
            THROW 50004, @errorMessage, 1;
        END
		
		-- Check Duplicate
		SET @errorMessage = NULL;
		SELECT @errorMessage = STRING_AGG(agCode, ', ')
        FROM @Input
        GROUP BY agCode
        HAVING COUNT(*) > 1;

        IF @errorMessage IS NOT NULL
        BEGIN
            SET @errorMessage = 'Ac Group: ' + @errorMessage + ' are duplicate';
            THROW 50001, @errorMessage, 1;
        END

        -- Perform update
        UPDATE a
        SET 
            agDescription = i.agDescription,
            mgcode = i.mgcode,
            isTr = i.isTr,
            isPl = i.isPl,
            isBl = i.isBl,
			lastUpdated = i.lastUpdated,
			workstation = i.workstation
        FROM [mastcode].[AcGroups] a
        INNER JOIN @Input i ON a.agCode = i.agCode;

        SET @rowAffected = @@ROWCOUNT;

        IF @rowAffected > 0
        BEGIN
            COMMIT;
            SET @status = 1;
        END
        ELSE
        BEGIN
            ROLLBACK;
            SET @status = 0;
            THROW 50005, 'No records were updated.', 1;
        END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        EXECUTE [dbo].[uspLogError];
        SET @status = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('[mastcode].[uspDeleteAcGroups]', 'P') IS NOT NULL
    DROP PROCEDURE [mastcode].[uspDeleteAcGroups];
GO

CREATE PROCEDURE [mastcode].[uspDeleteAcGroups]
    @agCode VARCHAR(5),
    @status SMALLINT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @errorMessage NVARCHAR(4000);
    DECLARE @rowAffected INT;

    BEGIN TRY
        BEGIN TRANSACTION;

		-- Check Not Null
		IF @agCode IS NULL OR @agCode = ''
		BEGIN
			SET @errorMessage = 'Agcode Should be Valid : ';
			THROW 50011, @errorMessage, 1;
		END

		-- Validate existence
        IF NOT EXISTS (
            SELECT 1 FROM [mastcode].[AcGroups] a WHERE a.agCode = @agCode
        )
		BEGIN
            SET @errorMessage = 'Ac Group: ' + @agCode + ' not found for deletion';
            THROW 50006, @errorMessage, 1;
        END
        -- Perform delete
        DELETE a
        FROM [mastcode].[AcGroups] a
        WHERE a.agCode = @agCode;

        SET @rowAffected = @@ROWCOUNT;

        IF @rowAffected > 0
        BEGIN
            COMMIT;
            SET @status = 1;
        END
        ELSE
        BEGIN
            ROLLBACK;
            SET @status = 0;
            THROW 50007, 'No records were deleted.', 1;
        END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        EXECUTE [dbo].[uspLogError];
        SET @status = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID('[mastcode].[uspGetAcGroups]', 'P') IS NOT NULL
    DROP PROCEDURE [mastcode].[uspGetAcGroups];
GO

CREATE PROCEDURE [mastcode].[uspGetAcGroups]
    @json NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
	IF ISJSON(TRIM(@json)) <> 1
		THROW 50000, 'Invalid JSON input.', 1;

	DECLARE @agCode VARCHAR(5) = JSON_VALUE(@json,'$.agCode');

	SELECT agCode, agDescription, mgcode, isTr, isPl, isBl, lastUpdated, workstation FROM [mastcode].[AcGroups]
	WHERE @agCode IS NULL OR agCode = @agCode;
END;
GO

IF OBJECT_ID(N'mastcode.uspGetLedgerCodesDropDown',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetLedgerCodesDropDown];
GO

CREATE PROCEDURE [mastcode].[uspGetLedgerCodesDropDown]  
AS  
BEGIN  
    SET NOCOUNT ON;  
	SELECT lcode,LEFT(rtrim(lcode)+REPLICATE(CHAR(175),12 - LEN(lCode)),12)+lName FROM [mastcode].[LedgerCodes] WHERE lstatus='A';  
END;
GO

IF OBJECT_ID(N'mastcode.uspGetLedgerCodesById',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetLedgerCodesById];
GO

CREATE PROCEDURE [mastcode].[uspGetLedgerCodesById]
( 
	@lcode varchar(10)
)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT lcode,lname,ltype,agCode,lstatus,remark,[add],add1,city,Stcd,zipCode,distance,country,phone,altPhone,email,crDays,paymentTerm,SupTyp,regId,Gstin,rc,isEcom,tdsCode,igstOnIntra,bankAcNo,bankName,bankAcName,ifscCode,swiftCode,discType,discRate,loyaltyDisc,paymentDisc FROM [mastcode].[LedgerCodes]
	WHERE lcode = @lcode;
END;
GO

IF OBJECT_ID(N'mastcode.uspAddLedgerCodes', N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspAddLedgerCodes];
GO

CREATE PROCEDURE [mastcode].[uspAddLedgerCodes]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 50001, 'Invalid JSON input.', 1;

        DECLARE @now DATETIME = GETDATE();
		DECLARE @clientIP VARCHAR(15);

		SELECT @clientIP = client_net_address
		FROM sys.dm_exec_connections
		WHERE session_id = @@SPID;



        DECLARE @Ledger TABLE (
            rowId INT IDENTITY(1,1),
            lcode VARCHAR(10),
            lname VARCHAR(50),
            ltype VARCHAR(1),
            agCode VARCHAR(5),
            lstatus VARCHAR(1),
            remark VARCHAR(100),
            [add] VARCHAR(100),
            add1 VARCHAR(100),
            city VARCHAR(50),
            Stcd SMALLINT,
            zipCode VARCHAR(6),
            distance INT,
            country VARCHAR(2),
            phone VARCHAR(10),
            altPhone VARCHAR(10),
            email VARCHAR(50),
            crDays SMALLINT,
            paymentTerm VARCHAR(100),
            SupTyp VARCHAR(10),
            regId VARCHAR(3),
            Gstin VARCHAR(15),
            rc VARCHAR(1),
            isEcom VARCHAR(1),
            tdsCode VARCHAR(10),
            igstOnIntra VARCHAR(1),
            bankAcNo VARCHAR(20),
            bankName VARCHAR(50),
            bankAcName VARCHAR(50),
            ifscCode VARCHAR(11),
            swiftCode VARCHAR(20),
            discType VARCHAR(1),
            discRate DECIMAL(5,2),
            loyaltyDisc DECIMAL(5,2),
            paymentDisc DECIMAL(5,2),
            workstation VARCHAR(15),
            userid VARCHAR(30)
        );

		INSERT INTO @Ledger (
			lcode, lname, ltype, agCode, lstatus, remark,
			[add], add1, city, Stcd, zipCode, distance, country,
			phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin,
			rc, isEcom, tdsCode, igstOnIntra,
			bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
			discType, discRate, loyaltyDisc, paymentDisc,
			workstation, userid
		)
		SELECT
			lcode, lname, ltype, agCode, lstatus, remark,
			[add], add1, city, Stcd, zipCode, distance, country,
			phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin,
			rc, isEcom, tdsCode, igstOnIntra,
			bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
			discType, discRate, loyaltyDisc, paymentDisc,
			@clientIP, userid
		FROM OPENJSON(@json)
		WITH (
			lcode VARCHAR(10),
			lname VARCHAR(50),
			ltype VARCHAR(1),
			agCode VARCHAR(5),
			lstatus VARCHAR(1),
			remark VARCHAR(100),
			[add] VARCHAR(100),
			add1 VARCHAR(100),
			city VARCHAR(50),
			Stcd SMALLINT,
			zipCode VARCHAR(6),
			distance INT,
			country VARCHAR(2),
			phone VARCHAR(10),
			altPhone VARCHAR(10),
			email VARCHAR(50),
			crDays SMALLINT,
			paymentTerm VARCHAR(100),
			SupTyp VARCHAR(10),
			regId VARCHAR(3),
			Gstin VARCHAR(15),
			rc VARCHAR(1),
			isEcom VARCHAR(1),
			tdsCode VARCHAR(10),
			igstOnIntra VARCHAR(1),
			bankAcNo VARCHAR(20),
			bankName VARCHAR(50),
			bankAcName VARCHAR(50),
			ifscCode VARCHAR(11),
			swiftCode VARCHAR(20),
			discType VARCHAR(1),
			discRate DECIMAL(5,2),
			loyaltyDisc DECIMAL(5,2),
			paymentDisc DECIMAL(5,2),
			userid VARCHAR(30)
		);

        DECLARE @ValidationErrors TABLE (
            rowId INT,
            lcode VARCHAR(10),
            errorMessage NVARCHAR(200)
        );

        DECLARE @rowId INT = 1, @max INT = (SELECT COUNT(*) FROM @Ledger);

        WHILE @rowId <= @max
        BEGIN
            DECLARE
                @lcode VARCHAR(10),
				@lname VARCHAR(50),
				@ltype VARCHAR(1),
                @country VARCHAR(2),
                @Stcd SMALLINT,
                @lstatus VARCHAR(1),
				@userid VARCHAR(30),
                @SupTyp VARCHAR(10),
                @regId VARCHAR(3),
                @Gstin VARCHAR(15),
                @tdsCode VARCHAR(10),
                @agCode VARCHAR(5),
                @discType VARCHAR(1),
				@rc VARCHAR(1),
				@isEcom VARCHAR(1),
				@discRate DECIMAL(5,2),
				@loyaltyDisc DECIMAL(5,2),
				@paymentDisc DECIMAL(5,2);

            SELECT
                @lcode = lcode,
				@lname = lname,
				@ltype = ltype,
                @country = country,
                @Stcd = Stcd,
                @lstatus = lstatus,
				@userid = userid,
                @SupTyp = SupTyp,
                @regId = regId,
                @Gstin = Gstin,
                @tdsCode = tdsCode,
                @agCode = agCode,
                @discType = discType,
				@rc = rc,
				@isEcom = isEcom,
				@discRate = discRate,
				@loyaltyDisc = loyaltyDisc,
				@paymentDisc = paymentDisc
            FROM @Ledger WHERE rowId = @rowId;

			IF @lcode IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: lcode');

			IF @lname IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: lname');

			IF @ltype IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: ltype');

			IF @agCode IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: agCode');

			IF @lstatus IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lstatus, 'Missing required field: lstatus');

            IF EXISTS (SELECT 1 FROM [mastcode].[LedgerCodes] WHERE lcode = @lcode)
                INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Duplicate lcode');

            IF [mastcode].[IsValidLedgerStatus](@lstatus) <= 0
                INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Ledger Status');

            IF NOT EXISTS (SELECT 1 FROM [mastcode].[AcGroups] WHERE agCode = @agCode)
                INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Account Group Code');
			
			IF @userid IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: userid');

			IF @ltype != 'O' 
			BEGIN
				IF @rc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: rc');

				IF @isEcom IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: isEcom');

				IF @discRate IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: discRate');

				IF @loyaltyDisc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: loyaltyDisc');

				IF @paymentDisc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: paymentDisc');

				IF @Stcd IS NOT NULL AND [mastcode].[IsValidState](@Stcd) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid State Code');

				IF @country IS NOT NULL AND [mastcode].[IsValidCountries](@country) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Country Code');

				IF @SupTyp IS NOT NULL AND [mastcode].[IsValidGstSupplyType](@SupTyp) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Supply Type');

				IF @regId IS NOT NULL AND [mastcode].[IsValidGSTRegnType](@regId) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid GST Registration Type');

				IF @Gstin IS NOT NULL AND [mastcode].[isValidGSTIN](@Gstin) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid GSTIN');

				IF @tdsCode IS NOT NULL AND [mastcode].[IsValidTdsType](@tdsCode) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid TDS Code');

				IF @discType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [mastcode].[SaleDiscountType] WHERE discType = @discType)
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Discount Type');
			END
            SET @rowId += 1;
        END

        IF EXISTS (SELECT 1 FROM @ValidationErrors)
        BEGIN
            DECLARE @errorText NVARCHAR(MAX) = '';

            SELECT @errorText = @errorText + 'Row ' + CAST(rowId AS NVARCHAR) + ' (lcode=' + lcode + '): ' + errorMessage + CHAR(13)
            FROM @ValidationErrors;

            THROW 51000, @errorText, 1;
        END

        -- All rows validated, insert in bulk
        INSERT INTO [mastcode].[LedgerCodes] (
            lcode, lname, ltype, agCode, lstatus, remark,
            [add], add1, city, Stcd, zipCode, distance, country,
            phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin,
            rc, isEcom, tdsCode, igstOnIntra,
            bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
            discType, discRate, loyaltyDisc, paymentDisc,
            lastUpdated, workstation, userid
        )
        SELECT
            lcode, lname, ltype, agCode,
            ISNULL(lstatus, 'A'), remark,
            [add], add1, city, Stcd, zipCode, ISNULL(distance, 0), country,
            phone, altPhone, email, ISNULL(crDays, 0), paymentTerm, SupTyp, regId, Gstin,
            ISNULL(rc, 'N'), ISNULL(isEcom, 'N'), tdsCode, igstOnIntra,
            bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
            ISNULL(discType, 'Z'), ISNULL(discRate, 0), ISNULL(loyaltyDisc, 0), ISNULL(paymentDisc, 0),
            @now, workstation, userid
        FROM @Ledger;

		SELECT rowId, lcode, 'Inserted successfully' AS status FROM @Ledger;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        EXECUTE [dbo].[uspLogError];

        DECLARE @STATUS INT = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'mastcode.uspUpdateLedgerCodes', N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspUpdateLedgerCodes];
GO

CREATE PROCEDURE [mastcode].[uspUpdateLedgerCodes]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 50001, 'Invalid JSON input.', 1;

        DECLARE @now DATETIME = GETDATE();
		DECLARE @clientIP VARCHAR(15);

		SELECT @clientIP = client_net_address
		FROM sys.dm_exec_connections
		WHERE session_id = @@SPID;



        DECLARE @Ledger TABLE (
            rowId INT IDENTITY(1,1),
            lcode VARCHAR(10),
            lname VARCHAR(50),
            ltype VARCHAR(1),
            agCode VARCHAR(5),
            lstatus VARCHAR(1),
            remark VARCHAR(100),
            [add] VARCHAR(100),
            add1 VARCHAR(100),
            city VARCHAR(50),
            Stcd SMALLINT,
            zipCode VARCHAR(6),
            distance INT,
            country VARCHAR(2),
            phone VARCHAR(10),
            altPhone VARCHAR(10),
            email VARCHAR(50),
            crDays SMALLINT,
            paymentTerm VARCHAR(100),
            SupTyp VARCHAR(10),
            regId VARCHAR(3),
            Gstin VARCHAR(15),
            rc VARCHAR(1),
            isEcom VARCHAR(1),
            tdsCode VARCHAR(10),
            igstOnIntra VARCHAR(1),
            bankAcNo VARCHAR(20),
            bankName VARCHAR(50),
            bankAcName VARCHAR(50),
            ifscCode VARCHAR(11),
            swiftCode VARCHAR(20),
            discType VARCHAR(1),
            discRate DECIMAL(5,2),
            loyaltyDisc DECIMAL(5,2),
            paymentDisc DECIMAL(5,2),
            workstation VARCHAR(15),
            userid VARCHAR(30)
        );

		INSERT INTO @Ledger (
			lcode, lname, ltype, agCode, lstatus, remark,
			[add], add1, city, Stcd, zipCode, distance, country,
			phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin,
			rc, isEcom, tdsCode, igstOnIntra,
			bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
			discType, discRate, loyaltyDisc, paymentDisc,
			workstation, userid
		)
		SELECT
			lcode, lname, ltype, agCode, lstatus, remark,
			[add], add1, city, Stcd, zipCode, distance, country,
			phone, altPhone, email, crDays, paymentTerm, SupTyp, regId, Gstin,
			rc, isEcom, tdsCode, igstOnIntra,
			bankAcNo, bankName, bankAcName, ifscCode, swiftCode,
			discType, discRate, loyaltyDisc, paymentDisc,
			@clientIP, userid
		FROM OPENJSON(@json)
		WITH (
			lcode VARCHAR(10),
			lname VARCHAR(50),
			ltype VARCHAR(1),
			agCode VARCHAR(5),
			lstatus VARCHAR(1),
			remark VARCHAR(100),
			[add] VARCHAR(100),
			add1 VARCHAR(100),
			city VARCHAR(50),
			Stcd SMALLINT,
			zipCode VARCHAR(6),
			distance INT,
			country VARCHAR(2),
			phone VARCHAR(10),
			altPhone VARCHAR(10),
			email VARCHAR(50),
			crDays SMALLINT,
			paymentTerm VARCHAR(100),
			SupTyp VARCHAR(10),
			regId VARCHAR(3),
			Gstin VARCHAR(15),
			rc VARCHAR(1),
			isEcom VARCHAR(1),
			tdsCode VARCHAR(10),
			igstOnIntra VARCHAR(1),
			bankAcNo VARCHAR(20),
			bankName VARCHAR(50),
			bankAcName VARCHAR(50),
			ifscCode VARCHAR(11),
			swiftCode VARCHAR(20),
			discType VARCHAR(1),
			discRate DECIMAL(5,2),
			loyaltyDisc DECIMAL(5,2),
			paymentDisc DECIMAL(5,2),
			userid VARCHAR(30)
		);

        DECLARE @ValidationErrors TABLE (
            rowId INT,
            lcode VARCHAR(10),
            errorMessage NVARCHAR(200)
        );

        DECLARE @rowId INT = 1, @max INT = (SELECT COUNT(*) FROM @Ledger);

        WHILE @rowId <= @max
        BEGIN
            DECLARE
                @lcode VARCHAR(10),
				@lname VARCHAR(50),
				@ltype VARCHAR(1),
                @country VARCHAR(2),
                @Stcd SMALLINT,
                @lstatus VARCHAR(1),
				@userid VARCHAR(30),
                @SupTyp VARCHAR(10),
                @regId VARCHAR(3),
                @Gstin VARCHAR(15),
                @tdsCode VARCHAR(10),
                @agCode VARCHAR(5),
                @discType VARCHAR(1),
				@rc VARCHAR(1),
				@isEcom VARCHAR(1),
				@discRate DECIMAL(5,2),
				@loyaltyDisc DECIMAL(5,2),
				@paymentDisc DECIMAL(5,2);

            SELECT
                @lcode = lcode,
				@lname = lname,
				@ltype = ltype,
                @country = country,
                @Stcd = Stcd,
                @lstatus = lstatus,
				@userid = userid,
                @SupTyp = SupTyp,
                @regId = regId,
                @Gstin = Gstin,
                @tdsCode = tdsCode,
                @agCode = agCode,
                @discType = discType,
				@rc = rc,
				@isEcom = isEcom,
				@discRate = discRate,
				@loyaltyDisc = loyaltyDisc,
				@paymentDisc = paymentDisc
            FROM @Ledger WHERE rowId = @rowId;

			IF NOT EXISTS (SELECT 1 FROM [mastcode].[LedgerCodes] WHERE lcode = @lcode)
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Record not found for update: lcode');

			IF @lcode IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: lcode');

			IF @lname IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: lname');

			IF @ltype IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: ltype');

			IF @agCode IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: agCode');

			IF @lstatus IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: lstatus');

			IF [mastcode].[IsValidLedgerStatus](@lstatus) <= 0
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Ledger Status');

            IF NOT EXISTS (SELECT 1 FROM [mastcode].[AcGroups] WHERE agCode = @agCode)
                INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Account Group Code');
			
			IF @userid IS NULL
				INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: userid');

			IF @ltype != 'O' 
			BEGIN
				IF @rc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: rc');

				IF @isEcom IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: isEcom');

				IF @discRate IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: discRate');

				IF @loyaltyDisc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: loyaltyDisc');

				IF @paymentDisc IS NULL
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Missing required field: paymentDisc');

				IF @Stcd IS NOT NULL AND [mastcode].[IsValidState](@Stcd) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid State Code');

				IF @country IS NOT NULL AND [mastcode].[IsValidCountries](@country) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Country Code');

				IF @SupTyp IS NOT NULL AND [mastcode].[IsValidGstSupplyType](@SupTyp) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Supply Type');

				IF @regId IS NOT NULL AND [mastcode].[IsValidGSTRegnType](@regId) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid GST Registration Type');

				IF @Gstin IS NOT NULL AND [mastcode].[isValidGSTIN](@Gstin) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid GSTIN');

				IF @tdsCode IS NOT NULL AND [mastcode].[IsValidTdsType](@tdsCode) <= 0
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid TDS Code');

				IF @discType IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [mastcode].[SaleDiscountType] WHERE discType = @discType)
					INSERT INTO @ValidationErrors VALUES (@rowId, @lcode, 'Invalid Discount Type');
			END
            SET @rowId += 1;
        END

        IF EXISTS (SELECT 1 FROM @ValidationErrors)
        BEGIN
            DECLARE @errorText NVARCHAR(MAX) = '';

            SELECT @errorText = @errorText + 'Row ' + CAST(rowId AS NVARCHAR) + ' (lcode=' + lcode + '): ' + errorMessage + CHAR(13)
            FROM @ValidationErrors;

            THROW 51000, @errorText, 1;
        END

        -- All rows validated, insert in bulk
        UPDATE L SET
            lname = S.lname,
            ltype = S.ltype,
            agCode = S.agCode,
            lstatus = S.lstatus,
            remark = S.remark,
            [add] = S.[add],
            add1 = S.add1,
            city = S.city,
            Stcd = S.Stcd,
            zipCode = S.zipCode,
            distance = S.distance,
            country = S.country,
            phone = S.phone,
            altPhone = S.altPhone,
            email = S.email,
            crDays = S.crDays,
            paymentTerm = S.paymentTerm,
            SupTyp = S.SupTyp,
            regId = S.regId,
            Gstin = S.Gstin,
            rc = S.rc,
            isEcom = S.isEcom,
            tdsCode = S.tdsCode,
            igstOnIntra = S.igstOnIntra,
            bankAcNo = S.bankAcNo,
            bankName = S.bankName,
            bankAcName = S.bankAcName,
            ifscCode = S.ifscCode,
            swiftCode = S.swiftCode,
            discType = S.discType,
            discRate = S.discRate,
            loyaltyDisc = S.loyaltyDisc,
            paymentDisc = S.paymentDisc,
            lastUpdated = @now,
            workstation = S.workstation,
            userid = S.userid
        FROM [mastcode].[LedgerCodes] L
        INNER JOIN @Ledger S ON L.lcode = S.lcode;

		SELECT rowId, lcode, 'Updated successfully' AS status FROM @Ledger;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;

        EXECUTE [dbo].[uspLogError];

        DECLARE @STATUS INT = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'mastcode.uspDeleteLedgerCodes', N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspDeleteLedgerCodes];
GO

CREATE PROC [mastcode].[uspDeleteLedgerCodes]
(	
	@lcode VARCHAR(10), -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		
		SET NOCOUNT ON;
		SET XACT_ABORT ON;
		
		BEGIN TRANSACTION;
		
		DECLARE @rowaffected int
		
		DELETE [mastcode].[LedgerCodes] WHERE lcode = @lcode;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
		SET @STATUS = 0;
        THROW;
    END CATCH;
END;
GO

IF OBJECT_ID(N'mastcode.uspGetLedgerCodes',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetLedgerCodes];
GO

CREATE PROCEDURE [mastcode].[uspGetLedgerCodes]
(
	@json NVARCHAR(max)
)
AS
BEGIN

	DECLARE @lcode VARCHAR(10),
	@lname VARCHAR(50),
	@stateCode INT,
	@supplyType VARCHAR(10),
	@lstatus VARCHAR(1)

	SELECT @lcode = lcode,@lname = lname,@stateCode = stateCode,@supplyType = supplyType,@lstatus = lstatus FROM OPENJSON(@json,'$')
	WITH (
	lcode VARCHAR(10),
	lname VARCHAR(50),
	stateCode INT,
	supplyType VARCHAR(10),
	lstatus VARCHAR(1)) q

	IF @lstatus IS NULL
		SET @lstatus = 'A';
	
	SELECT lcode, lname, ltype, agCode, agDescription, lstatus, remark, 
		[add], add1, city, Stcd, stateName, zipCode, distance, country, countryName, phone, altPhone, email, 
		crDays, paymentTerm, SupTyp, regId, Gstin, rc, isEcom, tdsCode, [description], igstOnIntra, 
		bankAcNo, bankName, bankAcName, ifscCode, swiftCode, 
		discType, discRate, loyaltyDisc, paymentDisc, 
		lastUpdated, workstation, userid FROM [mastcode].[ViLedgerCodes]
		WHERE (@lcode IS NULL or lcode = @lcode)
		AND (@lname IS NULL OR lname LIKE '%' + @lname + '%')
		AND (@stateCode IS NULL OR Stcd = @stateCode)
		AND (@supplyType IS NULL OR SupTyp = @supplyType)
		AND (@lstatus IS NULL OR lstatus = @lstatus)
END
GO

IF OBJECT_ID(N'fiac.uspAddOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspAddOpening];
GO

CREATE PROCEDURE [fiac].[uspAddOpening]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;

        DECLARE @Opening TABLE (
			lcode VARCHAR(10),
            Fy VARCHAR(9),
            DrAmt DECIMAL(18,2),
            CrAmt DECIMAL(18,2)
        );

        INSERT INTO @Opening (lcode, Fy, DrAmt, CrAmt)
        SELECT lcode, Fy, DrAmt, CrAmt
        FROM OPENJSON(@json)
        WITH (
			lcode VARCHAR(10) '$.lcode',
            Fy VARCHAR(9) '$.Fy',
            DrAmt DECIMAL(18,2) '$.DrAmt',
            CrAmt DECIMAL(18,2) '$.CrAmt'
        );

        DECLARE @ValidationError NVARCHAR(MAX)

		-- Validate foreign keys
        SELECT @ValidationError = STRING_AGG(lcode,',')
		FROM (SELECT o.lcode FROM @Opening o
				LEFT JOIN mastcode.LedgerCodes l ON o.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

        -- Validate Dr/Cr constraint
		SET @ValidationError = NULL;
		SELECT @ValidationError = STRING_AGG(CAST(DrAmt AS varchar) + '-' + CAST(CrAmt AS VARCHAR),',')
		FROM (SELECT DrAmt,CrAmt FROM @Opening WHERE 
            NOT ((DrAmt > 0 AND CrAmt = 0) OR 
                 (CrAmt > 0 AND DrAmt = 0) OR 
                 (DrAmt = 0 AND CrAmt = 0))) drcr;
		
		IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'DrAmt and CrAmt violate Dr/Cr rule. '+ @ValidationError;
			THROW 61003, @ValidationError, 1;
		END

        SET @ValidationError = NULL;
		SELECT @ValidationError = STRING_AGG(Fy,',')
		FROM (SELECT o.Fy FROM @Opening o
                   LEFT JOIN mastcode.FinancialYear f ON f.Fy = o.Fy
                   WHERE f.Fy IS NULL OR f.isActive = 0) fy
		IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Financial Year(s) Or Not Active. '+ @ValidationError;
			THROW 61004, @ValidationError, 1;
		END

        -- Validate duplicates in input
        SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(lcode + '-' + Fy, ',')
        FROM (SELECT lcode, Fy FROM @Opening
            GROUP BY lcode, Fy
            HAVING COUNT(*) > 1) x;
        IF @ValidationError IS NOT NULL
        BEGIN
            SET @ValidationError = 'Duplicate entries in input: ' + @ValidationError;
            THROW 61005, @ValidationError, 1;
        END;

        BEGIN TRANSACTION;
        INSERT INTO [fiac].[Opening] (lcode, Fy, DrAmt, CrAmt)
        SELECT lcode, Fy, DrAmt, CrAmt FROM @Opening;

        IF @@ROWCOUNT = 0
            THROW 61006, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspUpdateOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspUpdateOpening];
GO

CREATE PROCEDURE [fiac].[uspUpdateOpening]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;

        DECLARE @t TABLE (
            obId BIGINT,
			lcode VARCHAR(10),
            Fy VARCHAR(9),
            DrAmt DECIMAL(18,2),
            CrAmt DECIMAL(18,2)
        );

        INSERT INTO @t(obId, lcode, Fy, DrAmt, CrAmt)
        SELECT obId, lcode, Fy, DrAmt, CrAmt
        FROM OPENJSON(@json)
        WITH (
            ObId BIGINT,
			lcode VARCHAR(10) '$.lcode',
            Fy VARCHAR(9) '$.Fy',
            DrAmt DECIMAL(18,2) '$.DrAmt',
            CrAmt DECIMAL(18,2) '$.CrAmt'
        );

        -- Validate required fields
        IF EXISTS (SELECT 1 FROM @t WHERE obId IS NULL OR lcode IS NULL OR Fy IS NULL)
            THROW 61002, 'lcode and Fy are required.', 1;

        -- Validate Dr/Cr constraint
        IF EXISTS (SELECT 1 FROM @t WHERE 
            NOT ((DrAmt > 0 AND CrAmt = 0) OR 
                 (CrAmt > 0 AND DrAmt = 0) OR 
                 (DrAmt = 0 AND CrAmt = 0)))
            THROW 61003, 'DrAmt and CrAmt violate Dr/Cr rule.', 1;

        -- Validate foreign keys
        IF EXISTS (SELECT 1 FROM @t t
                   LEFT JOIN mastcode.LedgerCodes l ON l.lcode = t.lcode
                   WHERE l.lcode IS NULL)
            THROW 61004, 'Invalid Ledger Code(s) found.', 1;

        IF EXISTS (SELECT 1 FROM @t t
                   LEFT JOIN mastcode.FinancialYear f ON f.Fy = t.Fy
                   WHERE f.Fy IS NULL OR f.isActive = 0)
            THROW 61005, 'Invalid Financial Year(s) Or Not Active.', 1;

        -- Validate duplicates in input
        DECLARE @dup NVARCHAR(MAX);
        SELECT @dup = STRING_AGG(lcode + '-' + Fy, ',')
        FROM (
            SELECT lcode, Fy
            FROM @t
            GROUP BY lcode, Fy
            HAVING COUNT(*) > 1
        ) x;

        IF @dup IS NOT NULL
        BEGIN
            SET @dup = 'Duplicate entries in input: ' + @dup;
            THROW 61006, @dup, 1;
        END;

        -- Validate existence of target rows
        IF EXISTS (
            SELECT 1 FROM @t t
            LEFT JOIN fiac.Opening o ON o.ObId = t.obId
            WHERE o.ObId IS NULL
        )
            THROW 61007, 'Target rows for update not found.', 1;

        BEGIN TRANSACTION;
        UPDATE o
        SET o.Fy = t.Fy,
			o.lcode = t.lcode,
			o.DrAmt = t.DrAmt,
            o.CrAmt = t.CrAmt
        FROM fiac.Opening o
        INNER JOIN @t t ON o.ObId = t.obId;
        
		IF @@ROWCOUNT = 0
            THROW 61008, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;        
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspDeleteOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspDeleteOpening];
GO
CREATE PROCEDURE [fiac].[uspDeleteOpening]
    @obId BIGINT,
    @STATUS smallint = NULL OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Ensure ObId exists
        IF NOT EXISTS (
            SELECT 1 FROM fiac.Opening o
            WHERE o.ObId = @obId
        )
            THROW 63003, 'ObId does not exist.', 1;

        BEGIN TRANSACTION;
        DELETE o
        FROM fiac.Opening o
        WHERE o.ObId = @obId;

        IF @@ROWCOUNT = 0
            THROW 63004, 'Delete failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetOpening]
    @json NVARCHAR(MAX) = NULL  -- optional filters
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @lcode VARCHAR(10) = NULL;
    DECLARE @Fy VARCHAR(9) = NULL;

    IF @json IS NOT NULL AND ISJSON(@json) = 1
    BEGIN
        SET @lcode = JSON_VALUE(@json,'$.lcode');
        SET @Fy    = JSON_VALUE(@json,'$.Fy');
    END

    SELECT o.*
    FROM fiac.Opening o
	CROSS JOIN mastcode.CFY f
    WHERE o.Fy = f.Fy 
	AND (
	(@lcode IS NULL OR o.lcode = @lcode)
      AND (@Fy IS NULL OR o.Fy = @Fy)
	  )
    ORDER BY o.Fy, o.lcode;
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspAddCustomerShipping] 
( 
	@json NVARCHAR(max),
	@STATUS SMALLINT = 0 output 
)
AS
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @rowaffected INT

		INSERT INTO [mastcode].[CustomerShipping] (lcode,
			Gstin,
			LglNm,
			Addr1,
			Addr2,
			Loc,
			Stcd,
			Pin,
			CntCode,
			Phone)
		SELECT lcode, Gstin, LglNm, Addr1, Addr2, Loc, Stcd, Pin, CntCode, Phone FROM   Openjson(@json,'$') 
		WITH (			
			lcode VARCHAR(10) '$.lcode',
			Gstin VARCHAR(15) '$.Gstin',
			LglNm VARCHAR(100) '$.LglNm',
			Addr1 VARCHAR(100) '$.Addr1',
			Addr2 VARCHAR(100) '$.Addr2',
			Loc VARCHAR(50) '$.Loc',
			Stcd SMALLINT '$.Stcd',
			Pin VARCHAR(6) '$.Pin',
			CntCode VARCHAR(2) '$.CntCode',
			Phone VARCHAR(10) '$.Phone');

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
			ROLLBACK TRANSACTION;
		END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
        BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);      
	END catch;
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspUpdateCustomerShipping] 
( 
	@json NVARCHAR(max),
	@STATUS SMALLINT = 0 output 
)
AS
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @rowaffected INT

		UPDATE [mastcode].[CustomerShipping] SET lcode = u.lcode,
			Gstin = u.Gstin,
			LglNm = u.LglNm,
			Addr1 = u.Addr1,
			Addr2 = u.Addr2,
			Loc = u.Loc,
			Stcd = u.Stcd,
			Pin = u.Pin,
			CntCode = u.CntCode,
			Phone = u.Phone
		FROM Openjson(@json,'$') 
		WITH (			
			shipCode BIGINT '$.shipCode',
			lcode VARCHAR(10) '$.lcode',
			Gstin VARCHAR(15) '$.Gstin',
			LglNm VARCHAR(100) '$.LglNm',
			Addr1 VARCHAR(100) '$.Addr1',
			Addr2 VARCHAR(100) '$.Addr2',
			Loc VARCHAR(50) '$.Loc',
			Stcd SMALLINT '$.Stcd',
			Pin VARCHAR(6) '$.Pin',
			CntCode VARCHAR(2) '$.CntCode',
			Phone VARCHAR(10) '$.Phone') u WHERE CustomerShipping.shipCode = u.shipCode;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
			ROLLBACK TRANSACTION;
		END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
        BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);      
	END catch;
END;
GO

CREATE OR ALTER PROC [mastcode].[uspDeleteCustomerShipping]
(	
	@shipCode BIGINT, -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		
		DECLARE @rowaffected int
		
		DELETE [mastcode].[CustomerShipping] WHERE shipCode = @shipCode;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspGetCustomerShippingBylcode]
( 
	@lcode VARCHAR(10)
)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT shipCode, lcode, Gstin, LglNm, Addr1, Addr2, Loc, Stcd, stateName, Pin, CntCode, countryName, Phone FROM [mastcode].[ViCustomerShipping]
 	WHERE lcode = @lcode;
END;
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspGetCustomerShippingById]
( 
	@shipCode bigint
)
AS
BEGIN
	SET NOCOUNT ON;
	SELECT shipCode, lcode, Gstin, LglNm, Addr1, Addr2, Loc, Stcd, stateName, Pin, CntCode, countryName, Phone FROM [mastcode].[ViCustomerShipping]
 	WHERE shipCode = @shipCode; 	
END;
GO

IF OBJECT_ID(N'mastcode.uspAddCarrier',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspAddCarrier];
GO

CREATE PROCEDURE [mastcode].[uspAddCarrier] 
( 
	@json NVARCHAR(max),
	@STATUS SMALLINT = 0 output 
)
AS
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @rowaffected INT,
		@message NVARCHAR(4000) = NULL

		-- Duplicate check
		SELECT @message = STUFF((SELECT ', ' + carName FROM [mastcode].[Carrier] WHERE carName IN (
		SELECT carName FROM OPENJSON(@json,'$') WITH (carName VARCHAR(50))) FOR XML PATH('')),1,1,'')

		IF @message IS NOT NULL
		BEGIN
			SET @message = 'Carrier Name ' + @message + ' Already Exists'
			RAISERROR(@message,16,1)
			RETURN
		END

		INSERT INTO [mastcode].[Carrier] (carName,
			carGSTIN,
			carAdd,
			carAdd1,
			carCity,
			carStateName,
			carZipCode,
			carCPerson,
			carPhone)
		SELECT carName, carGSTIN, carAdd, carAdd1, carCity, carStateName, carZipCode, carCPerson, carPhone FROM   Openjson(@json,'$') 
		WITH (			
			carName VARCHAR(50) '$.carName',
			carGSTIN VARCHAR(15) '$.carGSTIN',
			carAdd VARCHAR(100) '$.carAdd',
			carAdd1 VARCHAR(100) '$.carAdd1',
			carCity VARCHAR(50) '$.carCity',
			carStateName VARCHAR(50) '$.carStateName',
			carZipCode VARCHAR(6) '$.carZipCode',
			carCPerson VARCHAR(50) '$.carCPerson',
			carPhone VARCHAR(30) '$.carPhone');

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
			ROLLBACK TRANSACTION;
		END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
        BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);      
	END catch;
END;
GO

IF OBJECT_ID(N'mastcode.uspUpdateCarrier',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspUpdateCarrier];
GO

CREATE PROCEDURE [mastcode].[uspUpdateCarrier] 
( 
	@json NVARCHAR(max),
	@STATUS SMALLINT = 0 output 
)
AS
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @rowaffected INT

		UPDATE [mastcode].[Carrier] SET carName = u.carName,
			carGSTIN = u.carGSTIN,
			carAdd = u.carAdd,
			carAdd1 = u.carAdd1,
			carCity = u.carCity,
			carStateName = u.carStateName,
			carZipCode = u.carZipCode,
			carCPerson = u.carCPerson,
			carPhone = u.carPhone
		FROM (SELECT carId, carName, carGSTIN, carAdd, carAdd1, carCity, carStateName, carZipCode, carCPerson, carPhone FROM   Openjson(@json,'$') 
		WITH (
			carId BIGINT '$.carId',
			carName VARCHAR(50) '$.carName',
			carGSTIN VARCHAR(15) '$.carGSTIN',
			carAdd VARCHAR(100) '$.carAdd',
			carAdd1 VARCHAR(100) '$.carAdd1',
			carCity VARCHAR(50) '$.carCity',
			carStateName VARCHAR(50) '$.carStateName',
			carZipCode VARCHAR(6) '$.carZipCode',
			carCPerson VARCHAR(50) '$.carCPerson',
			carPhone VARCHAR(30) '$.carPhone')) u WHERE Carrier.carId = u.carId;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
			ROLLBACK TRANSACTION;
		END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
        BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);      
	END catch;
END;
GO

IF OBJECT_ID(N'mastcode.uspDeleteCarrier',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspDeleteCarrier];
GO

CREATE PROC [mastcode].[uspDeleteCarrier]
(	
	@carId BIGINT, -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		BEGIN TRANSACTION;
		
		DECLARE @rowaffected int
		
		DELETE [mastcode].[Carrier] WHERE carId = @carId;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'mastcode.uspGetCarrier',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetCarrier];
GO

CREATE PROCEDURE [mastcode].[uspGetCarrier]
(
	@json NVARCHAR(max) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	IF @json IS NULL
	BEGIN
		SELECT carId,carName,carGSTIN,carAdd,carAdd1,carCity,carStateName,carZipCode,carCPerson,carPhone FROM [mastcode].[Carrier] car;
		RETURN;
	END

	-- Extract filter
	DECLARE @carId bigint,
		@carName varchar(50);
   
    IF @json IS NOT NULL
    BEGIN
        SELECT @carId = carId,@carName = carName FROM OPENJSON(@json, '$')
        WITH (
			carId BIGINT '$.carId',
			carName VARCHAR(50) '$.carName');
    END

	IF @carName IS NULL
		SELECT carId,carName,carGSTIN,carAdd,carAdd1,carCity,carStateName,carZipCode,carCPerson,carPhone FROM [mastcode].[Carrier] car
		WHERE car.carId = @carId OR carId IS NULL;
	ELSE
		SELECT carId,carName,carGSTIN,carAdd,carAdd1,carCity,carStateName,carZipCode,carCPerson,carPhone FROM [mastcode].[Carrier] car
		WHERE carName LIKE '%'+@carName+'%';
END;
GO

CREATE OR ALTER PROCEDURE [gl].[uspGetLedger]
(
    @json NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate JSON input
    IF ISJSON(@json) != 1 
        THROW 50001, 'Invalid Parameter', 1;

    -- Extract parameters from JSON
    DECLARE @lcode VARCHAR(10) = JSON_VALUE(@json, '$.lcode'),
        @fromDate DATETIME = JSON_VALUE(@json, '$.fromDate'),
        @toDate DATETIME = JSON_VALUE(@json, '$.toDate'),
        @fy VARCHAR(9),
        @lname VARCHAR(100),
        @legalName VARCHAR(100),
        @compAdd VARCHAR(100),
        @compAdd1 VARCHAR(100),
        @compCity VARCHAR(50);

    -- Validate date range
    IF [gl].[GlDateValidity](@fromDate, @toDate) != 1
        THROW 50002, 'Date is Out of Financial Year Range', 1;

    -- Validate ledger code
    IF NOT EXISTS (SELECT 1 FROM [mastcode].[LedgerCodes] WHERE lcode = @lcode)
        THROW 50002, 'Invalid Ledger Code', 1;

    -- Get active financial year
    SELECT @fy = fy FROM [mastcode].[FinancialYear] WHERE IsActive = 1;

    -- Get ledger and company details
	SELECT @lname = lc.lName FROM [mastcode].[LedgerCodes] lc
	WHERE lc.lcode = @lcode;

	SELECT @legalName = legalName, @compAdd = compAdd, @compAdd1 = compAdd1, @compCity = compCity FROM [mastcode].[Company];

    -- CTE chain for ledger processing
    WITH OpeningBalance AS (
        SELECT 
            NULL AS billDate,
            'Opening Balance' AS lname,
            NULL AS naration,
            CASE WHEN SUM(drAmount) - SUM(crAmount) > 0 THEN ABS(SUM(drAmount) - SUM(crAmount)) ELSE 0 END AS dbamount,
            CASE WHEN SUM(drAmount) - SUM(crAmount) <= 0 THEN ABS(SUM(drAmount) - SUM(crAmount)) ELSE 0 END AS cramount
        FROM (
            SELECT ISNULL(DrAmt, 0) AS drAmount, ISNULL(CrAmt, 0) AS crAmount
            FROM [fiac].[Opening]
            WHERE lcode = @lcode AND Fy = @fy
            UNION ALL
            SELECT ISNULL(DrAmount, 0), ISNULL(CrAmount, 0)
            FROM [gl].[GeneralLedger]
            WHERE lcode = @lcode AND tranDate < @fromDate
        ) AS OB
    ),
    LedgerEntries AS (
        SELECT 
            tranDate AS billDate,
            lc.lName AS lname,
            narration AS naration,
            drAmount AS dbamount,
            crAmount AS cramount
        FROM [gl].[GeneralLedger] lgr
        LEFT JOIN [mastcode].[LedgerCodes] lc ON lgr.lcode = lc.lcode
        WHERE lgr.lcode = @lcode AND tranDate BETWEEN @fromDate AND @toDate
    ),
    CombinedLedger AS (
        SELECT * FROM OpeningBalance
        UNION ALL
        SELECT * FROM LedgerEntries
    ),
    LedgerWithTotals AS (
        SELECT 
            billDate,
            lname,
            naration,
            dbamount,
            cramount,
            SUM(dbamount - cramount) OVER (ORDER BY billDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS rowtotal
        FROM CombinedLedger
    ),
    FinalLedger AS (
        SELECT 
            billDate,
            lname,
            naration,
            dbamount,
            cramount,
            ABS(rowtotal) AS rowtotal,
            CASE WHEN rowtotal >= 0 THEN 'DB' ELSE 'CR' END AS ty
        FROM LedgerWithTotals
    )

    -- Final JSON output using CTE directly
    SELECT 
        @lcode AS lcode,
        [mastcode].[ufGetIDate](@fromDate) AS fromDate,
        [mastcode].[ufGetIDate](@toDate) AS toDate,
        @lname AS lname,
        @legalName AS legalName,
        @compAdd AS compAdd,
        @compAdd1 AS compAdd1,
        @compCity AS compCity,
        (
            SELECT 
                [mastcode].[ufGetIDate](billDate) AS billDate,
                lname,
                naration,
                dbamount,
                cramount,
                rowtotal,
                ty
            FROM FinalLedger
            ORDER BY billDate
            FOR JSON PATH, INCLUDE_NULL_VALUES
        ) AS ledgerdet,
        (
            SELECT 
                SUM(dbamount) AS totdbAmount,
                SUM(cramount) AS totcrAmount,
                ABS(SUM(dbamount) - SUM(cramount)) AS balAmount,
                CASE WHEN SUM(dbamount) - SUM(cramount) >= 0 THEN 'DB' ELSE 'CR' END AS ty
            FROM FinalLedger
            FOR JSON PATH
        ) AS ledgersum
    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER;
END
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetTrial]
(
    @json NVARCHAR(MAX)
)
AS
BEGIN
    SET NOCOUNT ON;

    /*-----------------------------
      Variable declarations
    ------------------------------*/
    DECLARE 
        @agCode        VARCHAR(5)   = JSON_VALUE(@json,'$.agCode'),
        @fDate         DATE         = JSON_VALUE(@json,'$.fDate'),
        @toDate        DATE         = JSON_VALUE(@json,'$.toDate'),
        @legalName     VARCHAR(100),
        @compAdd       VARCHAR(100),
        @compAdd1      VARCHAR(100),
        @compCity      VARCHAR(50),
        @totdbAmount   DECIMAL(12,2),
        @totcrAmount   DECIMAL(12,2);

    /*-----------------------------
      Company information
    ------------------------------*/
    SELECT  
        @legalName = co.legalName,
        @compAdd   = co.compAdd,
        @compAdd1  = co.compAdd1,
        @compCity  = co.compCity
    FROM [mastcode].[Company] co;

    /*-----------------------------
      Temp table creation
    ------------------------------*/
    CREATE TABLE #trial
    (
        agCode        VARCHAR(5),
        agDescription VARCHAR(100),
        lcode         VARCHAR(10),
        lname         VARCHAR(100),
        drAmount      DECIMAL(12,2),
        crAmount      DECIMAL(12,2)
    );

    /*-----------------------------
      Trial balance aggregation
    ------------------------------*/
    INSERT INTO #trial (agCode, agDescription, lcode, lname, drAmount, crAmount)
    SELECT  
        ag.agCode,
        ag.agDescription,
        lc.lcode,
        lc.lName,
        CASE WHEN bal.balance > 0 THEN bal.balance ELSE 0 END,
        CASE WHEN bal.balance < 0 THEN ABS(bal.balance) ELSE 0 END
    FROM (
        SELECT  
            lcode,
            SUM(ISNULL(dramount,0)) - SUM(ISNULL(cramount,0)) AS balance
        FROM (
			SELECT lcode,drAmt AS dramount,crAmt AS cramount FROM [fiac].[Opening]
				INNER JOIN [mastcode].[FinancialYear] fy ON Opening.Fy = Fy.Fy WHERE fy.IsActive = 1
			UNION ALL SELECT lcode,dramount,cramount FROM [gl].[GeneralLedger] WHERE tranDate <= @toDate
			) AS gl GROUP BY lcode
        HAVING SUM(ISNULL(dramount,0)) - SUM(ISNULL(cramount,0)) <> 0
    ) bal
    JOIN [mastcode].[LedgerCodes] lc ON bal.lcode = lc.lcode
    JOIN [mastcode].[AcGroups] ag    ON lc.agCode = ag.agCode;

    /*-----------------------------
      Index for performance
    ------------------------------*/
    CREATE NONCLUSTERED INDEX IX_trial_agCode
        ON #trial (agCode)
        INCLUDE (drAmount, crAmount, lcode, lname);

    /*-----------------------------
      Totals calculation
    ------------------------------*/
    SELECT  
        @totdbAmount = SUM(drAmount),
        @totcrAmount = SUM(crAmount)
    FROM #trial
    WHERE @agCode IS NULL OR agCode = @agCode;

    /*-----------------------------
      Final JSON output
    ------------------------------*/
    SELECT  
        [mastcode].[ufGetIDate](@fDate) AS fDate,
		[mastcode].[ufGetIDate](@toDate) AS toDate,
        @totdbAmount AS totdbAmount,
        @totcrAmount AS totcrAmount,
        @legalName AS legalName,
        @compAdd AS compAdd,
        @compAdd1 AS compAdd1,
        @compCity AS compCity,
        (
            SELECT  
                b.agCode,
                b.agDescription,
                SUM(b.drAmount) AS dbAmount,
                SUM(b.crAmount) AS crAmount,
                (
                    SELECT  
                        d.lcode,
                        d.lname,
                        d.drAmount,
                        d.crAmount
                    FROM #trial d
                    WHERE d.agCode = b.agCode
                    FOR JSON PATH, INCLUDE_NULL_VALUES
                ) AS trialdet
            FROM #trial b
            WHERE @agCode IS NULL OR b.agCode = @agCode
            GROUP BY b.agCode, b.agDescription
            FOR JSON PATH, INCLUDE_NULL_VALUES
        ) AS trial
    FOR JSON PATH, INCLUDE_NULL_VALUES, WITHOUT_ARRAY_WRAPPER;

    DROP TABLE #trial;
END;
GO

IF OBJECT_ID(N'mastcode.HSN',N'U') IS NOT NULL
	DROP TABLE [mastcode].[HSN];
GO

CREATE TABLE [mastcode].[HSN]
(
	hsnCode VARCHAR(10) NOT NULL CONSTRAINT pk_mastcode_hsn_hsncode PRIMARY KEY (hsnCode),
	hsnShortDescription VARCHAR(50) NOT NULL,
	hsnDescription VARCHAR(500) NULL,	
	isService VARCHAR(1) NOT NULL CONSTRAINT ck_mastcode_hsn_isservice CHECK (isService IN ('Y','N')), -- Drop Down Proc [mastcode].[uspGetYesNo]
	gstTaxRate DECIMAL(6,3) NOT NULL, -- Drop Down Proc [mastcode].[uspGetGstRate]
	cesRt DECIMAL(6,3) NOT NULL DEFAULT 0,
	cesNonAdvl DECIMAL(6,3) NOT NULL  DEFAULT 0,
	CONSTRAINT ck_mastcode_hsn_hsncode CHECK ([mastcode].[IsValidHSN](hsnCode) > 0),
	CONSTRAINT ck_mastcode_hsn_gsttaxrate CHECK ([mastcode].[isValidGstRate](gstTaxRate) > 0)
) ON [PRIMARY];
GO

IF OBJECT_ID(N'mastcode.uspAddHSN',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspAddHSN];
GO

CREATE PROCEDURE [mastcode].[uspAddHSN]
(
	@json NVARCHAR(MAX), 	
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected INT = 0,
		@message NVARCHAR(4000) = NULL
	
		-- Duplicate check
		SELECT @message = STUFF((SELECT ', ' + hsnCode FROM [mastcode].[HSN] WHERE hsnCode IN (
		SELECT hsnCode FROM OPENJSON(@json,'$') WITH (hsnCode VARCHAR(10))) FOR XML PATH('')),1,1,'')
		
		IF @message IS NOT NULL
		BEGIN
			SET @message = 'HSN Codes ' + @message + ' Already Exists'
			RAISERROR(@message,16,1)
			RETURN
		END

		INSERT INTO [mastcode].[HSN] (hsnCode,
			hsnShortDescription,
			hsnDescription,
			isService,
			gstTaxRate)
		SELECT hsnCode,hsnShortDescription,hsnDescription,isService,gstTaxRate FROM OPENJSON(@json,'$')
		WITH (
			hsnCode VARCHAR(10) '$.hsnCode',
			hsnShortDescription VARCHAR(50) '$.hsnShortDescription',
			hsnDescription VARCHAR(500) '$.hsnDescription',	
			isService VARCHAR(1) '$.isService',
			gstTaxRate DECIMAL(5,2) '$.gstTaxRate') hsn;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'mastcode.uspUpdateHSN',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspUpdateHSN];
GO

CREATE PROCEDURE [mastcode].[uspUpdateHSN]
(
	@json NVARCHAR(MAX), 	
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected int

		UPDATE [mastcode].[HSN] SET hsnShortDescription = u.hsnShortDescription,
			hsnDescription = u.hsnDescription,
			isService = u.isService,
			gstTaxRate = u.gstTaxRate
		FROM OPENJSON(@json,'$')
		WITH (
			hsnCode VARCHAR(10) '$.hsnCode',
			hsnShortDescription VARCHAR(50) '$.hsnShortDescription',
			hsnDescription VARCHAR(500) '$.hsnDescription',	
			isService VARCHAR(1) '$.isService',
			gstTaxRate DECIMAL(5,2) '$.gstTaxRate') u WHERE HSN.hsnCode = u.hsnCode;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'mastcode.uspDeleteHSN',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspDeleteHSN];
GO

CREATE OR ALTER PROCEDURE [mastcode].[uspDeleteHSN]
(
	@hsnCode VARCHAR(10), -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected int;
		
		DELETE [mastcode].[HSN] WHERE hsnCode = @hsnCode;
		
		SET @rowaffected = @@ROWCOUNT;
		
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'mastcode.uspGetHSN',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetHSN];
GO

CREATE PROCEDURE [mastcode].[uspGetHSN]
AS
BEGIN
    SET NOCOUNT ON;
	SELECT hsnCode,LEFT(rtrim(hsnCode) +REPLICATE(CHAR(175),12 - LEN(hsnCode)),12) + hsnShortDescription AS hsnShortDescription,hsnDescription,isService,gstTaxRate FROM [mastcode].[HSN]
END;
GO

IF OBJECT_ID(N'mastcode.uspGetHSNById',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetHSNById];
GO

CREATE PROCEDURE [mastcode].[uspGetHSNById]
	@hsnCode VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
	SELECT hsnCode,hsnShortDescription,hsnDescription,isService,gstTaxRate FROM [mastcode].[HSN] WHERE hsnCode = @hsnCode
	IF @@ROWCOUNT <= 0
	BEGIN
		RAISERROR ('Invalid HSN Code', 16, 1);
	END
END;
GO

IF OBJECT_ID(N'purchase.Material',N'U') IS NOT NULL
	DROP TABLE [purchase].[Material];
GO

CREATE TABLE [purchase].[Material]
(
	matno VARCHAR(15) NOT NULL CONSTRAINT pk_purchase_material_matno PRIMARY KEY (matno),
	hsnCode VARCHAR(10) NOT NULL CONSTRAINT fk_purchase_material_hsncode FOREIGN KEY (hsnCode) REFERENCES [mastcode].[HSN](hsnCode), -- DROP DOWN PROC EXEC [mastcode].[uspGetHSN]
	gstTaxRate DECIMAL(5,2) NOT NULL, -- Auto Populated from hsnCode
	isService VARCHAR(1) NOT NULL, -- Auto Populated from hsnCode
	matDescription VARCHAR(100) NOT NULL CONSTRAINT ck_purchase_material_matdescription CHECK ([mastcode].[IsValidDescription](matDescription) > 0),
	prate DECIMAL(12,3) NOT NULL CHECK(prate > 0), -- Purchase Rate
	unit VARCHAR(8) NOT NULL CONSTRAINT ck_purchase_material_unit CHECK ([mastcode].[IsValidUnit](unit) > 0), -- DROP DOWN PROC [mastcode].[uspGetMaterialUnit]
	saleDescription VARCHAR(50) NOT NULL,
	mrp DECIMAL(12,2) CHECK (mrp >= 0) DEFAULT 0, -- Maximum Retail Price 
	listPrice DECIMAL(12,2) CHECK (listPrice >= 0) DEFAULT 0, -- Billing Rate
	discRate DECIMAL(5,2) NOT NULL DEFAULT 0, -- In Case of Discount Type Material Then it will be Greater Than 0 and Less than 100
	smargin DECIMAL(5,2) NOT NULL DEFAULT 0, -- Margin % on prate
	srate DECIMAL(12,3) NOT NULL CHECK(srate > 0), -- Sale Rate
	wef DATETIME NOT NULL DEFAULT (CAST(GETDATE() AS date)),
	mst VARCHAR(1) NOT NULL CONSTRAINT ck_purchase_material_mst CHECK ([mastcode].[IsValidMaterialStatus](mst) > 0), -- DROP DOWN PROC [mastcode].[uspGetMaterialStatus]
	CesRt DECIMAL(6,2) NOT NULL DEFAULT 0, -- Auto Populated from hsnCode
	StateCesRt DECIMAL(6,2) NOT NULL DEFAULT 0 -- Input Required Base on matDescription
)ON [Primary];
GO

IF OBJECT_ID(N'purchase.uspAddMaterial',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspAddMaterial];
GO

CREATE PROCEDURE [purchase].[uspAddMaterial]
(
	@json NVARCHAR(MAX), 	
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected INT = 0,
		@message NVARCHAR(4000) = NULL,
		@hsnmessage NVARCHAR(4000) = NULL,
		@unitmessage NVARCHAR(4000) = NULL
	
		-- Duplicate check
		SELECT @message = STUFF((SELECT ', ' + matno FROM [purchase].[Material] WHERE matno IN (
		SELECT matno FROM OPENJSON(@json,'$') WITH (matno VARCHAR(15))) FOR XML PATH('')),1,1,'')

		SELECT @hsnmessage = STUFF((SELECT ', ' + hsnCode FROM OPENJSON(@json,'$') WITH (hsnCode VARCHAR(10)) WHERE hsnCode NOT IN (
		SELECT hsnCode FROM [mastcode].[HSN] ) FOR XML PATH('')),1,1,'')

		SELECT @unitmessage = STUFF((SELECT ', ' + unit FROM OPENJSON(@json,'$') WITH (unit VARCHAR(10)) WHERE unit NOT IN (
		SELECT [key] FROM [mastcode].[MaterialUnit]) FOR XML PATH('')),1,1,'')
		
		IF @message IS NOT NULL OR @hsnmessage IS NOT NULL OR @unitmessage IS NOT NULL
		BEGIN
			IF @message IS NOT NULL
				SET @message = 'Material No. ' + @message + ' Already Exists';
			IF @hsnmessage IS NOT NULL
				SET @message = ISNULL(@message,'') + ' HSN Code ' + @hsnmessage + ' Does Not Exists'; 
			IF @unitmessage IS NOT NULL
				SET @message = ISNULL(@message,'') + ' Material Unit ' + @unitmessage + ' Does Not Exists';
				
			RAISERROR(@message,16,1)
			RETURN
		END

		INSERT INTO [purchase].[Material] (matno,
			hsnCode,
			gstTaxRate,
			isService,
			matDescription,
			prate,
			unit,
			saleDescription,
			mrp,
			listPrice,
			discRate,
			smargin,
			srate,
			mst)
		SELECT matno, ins.hsnCode, HSN.gstTaxRate, HSN.isService, matDescription, prate, unit, ISNULL(saleDescription,matDescription) saleDescription, ISNULL(mrp,0) mrp, ISNULL(listPrice,0) listPrice, ISNULL(discRate,0) discRate, ISNULL(smargin,0) smargin, srate,mst FROM OPENJSON(@json,'$')
		WITH (
			matno VARCHAR(15) '$.matno',
			hsnCode VARCHAR(10) '$.hsnCode',
			matDescription VARCHAR(100) '$.matDescription',
			prate DECIMAL(12,3) '$.prate',
			unit VARCHAR(8) '$.unit',
			saleDescription VARCHAR(50) '$.saleDescription',
			mrp DECIMAL(12,2) '$.mrp',
			listPrice DECIMAL(12,2) '$.listPrice',
			discRate DECIMAL(5,2) '$.discRate',
			smargin DECIMAL(5,2) '$.smargin',
			srate DECIMAL(12,3) '$.srate',
			mst VARCHAR(1) '$.mst') ins INNER JOIN [mastcode].[HSN] ON ins.hsnCode = HSN.hsnCode;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'purchase.uspUpdateMaterial',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspUpdateMaterial];
GO

CREATE PROCEDURE [purchase].[uspUpdateMaterial]
(
	@json NVARCHAR(MAX), 	
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected INT = 0,
		@message NVARCHAR(4000) = NULL,
		@hsnmessage NVARCHAR(4000) = NULL,
		@unitmessage NVARCHAR(4000) = NULL
	
		-- Duplicate check
		SELECT @message = STUFF((SELECT ', ' + matno FROM OPENJSON(@json,'$') WITH (matno VARCHAR(15)) WHERE matno NOT IN (
		SELECT matno FROM [purchase].[Material]) FOR XML PATH('')),1,1,'')

		SELECT @hsnmessage = STUFF((SELECT ', ' + hsnCode FROM OPENJSON(@json,'$') WITH (hsnCode VARCHAR(10)) WHERE hsnCode NOT IN (
		SELECT hsnCode FROM [mastcode].[HSN] ) FOR XML PATH('')),1,1,'')
		
		SELECT @unitmessage = STUFF((SELECT ', ' + unit FROM OPENJSON(@json,'$') WITH (unit VARCHAR(10)) WHERE unit NOT IN (
		SELECT [key] FROM [mastcode].[MaterialUnit]) FOR XML PATH('')),1,1,'')
		
		IF @message IS NOT NULL OR @hsnmessage IS NOT NULL OR @unitmessage IS NOT NULL
		BEGIN
			IF @message IS NOT NULL
				SET @message = 'Material No. ' + @message + ' Already Exists';
			IF @hsnmessage IS NOT NULL
				SET @message = ISNULL(@message,'') + ' HSN Code ' + @hsnmessage + ' Does Not Exists'; 
			IF @unitmessage IS NOT NULL
				SET @message = ISNULL(@message,'') + ' Material Unit ' + @unitmessage + ' Does Not Exists';
				
			RAISERROR(@message,16,1)
			RETURN
		END

		UPDATE [purchase].[Material] SET hsnCode = u.hsnCode,
			gstTaxRate = u.gstTaxRate,
			isService = u.isService,
			matDescription = u.matDescription,
			prate = u.prate,
			unit = u.unit,
			saleDescription = u.saleDescription,
			mrp = u.mrp,
			listPrice = u.listPrice,
			discRate = u.discRate,
			smargin = u.smargin,
			srate = u.srate,
			mst = u.mst
		FROM (SELECT matno, ins.hsnCode, HSN.gstTaxRate, HSN.isService, matDescription, prate, unit, ISNULL(saleDescription,matDescription) saleDescription, ISNULL(mrp,0) mrp, ISNULL(listPrice,0) listPrice, ISNULL(discRate,0) discRate, ISNULL(smargin,0) smargin, srate, mst FROM OPENJSON(@json,'$')
		WITH (
			matno VARCHAR(15) '$.matno',
			hsnCode VARCHAR(10) '$.hsnCode',
			matDescription VARCHAR(100) '$.matDescription',
			prate DECIMAL(12,3) '$.prate',
			unit VARCHAR(8) '$.unit',
			saleDescription VARCHAR(50) '$.saleDescription',
			mrp DECIMAL(12,2) '$.mrp',
			listPrice DECIMAL(12,2) '$.listPrice',
			discRate DECIMAL(5,2) '$.discRate',
			smargin DECIMAL(5,2) '$.smargin',
			srate DECIMAL(12,3) '$.srate',
			mst VARCHAR(1) '$.mst') ins INNER JOIN [mastcode].[HSN] ON ins.hsnCode = HSN.hsnCode) u WHERE Material.matno = u.matno;

		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'purchase.uspDeleteMaterial',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspDeleteMaterial];
GO

CREATE PROCEDURE [purchase].[uspDeleteMaterial]
(
	@matno VARCHAR(15), -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
		
		DECLARE @rowaffected int;
		
		DELETE [purchase].[Material] WHERE matno = @matno;
		
		SET @rowaffected = @@ROWCOUNT;
		
		IF @rowaffected > 0
		BEGIN
			COMMIT TRANSACTION;
			SET @STATUS = @rowaffected;			
		END
		ELSE
		BEGIN
			SET @STATUS = 0;
            ROLLBACK TRANSACTION;
        END
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID(N'purchase.uspGetMaterial',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspGetMaterial];
GO

CREATE PROCEDURE [purchase].[uspGetMaterial]
AS
BEGIN
    SET NOCOUNT ON;
	SELECT matno, hsnCode, gstTaxRate, isService, matDescription, prate, unit, saleDescription, mrp, listPrice, discRate, smargin, srate, wef, mst FROM [purchase].[Material];
END;
GO

IF OBJECT_ID(N'purchase.uspGetMaterialById',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspGetMaterialById];
GO

CREATE PROCEDURE [purchase].[uspGetMaterialById]
	@matno VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
	SELECT matno, hsnCode, gstTaxRate, isService, matDescription, prate, unit, saleDescription, mrp, listPrice, discRate, smargin, srate, wef, mst FROM [purchase].[Material] WHERE matno = @matno AND mst = 'A'
	IF @@ROWCOUNT <= 0
	BEGIN
		RAISERROR ('Invalid Material No.', 16, 1);
	END
END;
GO

IF OBJECT_ID(N'purchase.uspGetMaterialRep',N'P') IS NOT NULL
	DROP PROCEDURE [purchase].[uspGetMaterialRep];
GO

CREATE PROCEDURE [purchase].[uspGetMaterialRep]
(
	@json NVARCHAR(max)
)
AS
BEGIN

	DECLARE @fmatno VARCHAR(15),
	@tmatno VARCHAR(50),
	@mst VARCHAR(1)

	SELECT @fmatno = fmatno,@tmatno = tmatno,@mst = mst FROM OPENJSON(@json,'$')
	WITH (
	fmatno VARCHAR(15),
	tmatno VARCHAR(15),
	mst VARCHAR(1)) q
	
	IF @mst IS NULL
		SET @mst = 'A';

	DECLARE @qf NVARCHAR(MAX) = ' WHERE mst = ''' + @mst + '''';
	IF @fmatno IS NOT NULL
		SET @qf += ' AND matno >= ''' + @fmatno + '''';
	IF @tmatno IS NOT NULL
		SET @qf += ' AND matno <= ''' + @tmatno + '''';
	IF @mst != 'A'
		SET @qf += ' AND mst = ''' + @mst + '''';

	SET @qf = 'SELECT matno, hsnCode, gstTaxRate, isService, matDescription, prate, unit, saleDescription, mrp, listPrice, discRate, smargin, srate, wef, mst FROM [purchase].[Material]'+@qf

	EXECUTE sp_executesql @qf;
END
GO

IF OBJECT_ID (N'sales.ufGetMaterialRate', N'IF') IS NOT NULL  
    DROP FUNCTION [sales].[ufGetMaterialRate];  
GO  

CREATE FUNCTION [sales].[ufGetMaterialRate](@lcode VARCHAR(10),@matno VARCHAR(15)) 
RETURNS TABLE
AS
RETURN (
SELECT mt.matno,mt.saleDescription,mt.unit,mt.hsnCode,mt.gstTaxRate,mt.mrp,mt.listPrice,mt.srate,lc.igstOnIntra,lc.discType,lc.discRate,lc.loyaltyDisc,lc.paymentDisc FROM [mastcode].[LedgerCodes] lc
CROSS APPLY  [purchase].[Material] mt WHERE lc.lcode = @lcode AND mt.matno = @matno AND mt.mst = 'A');
GO

IF OBJECT_ID (N'docen.Br', N'U') IS NOT NULL  
    DROP TABLE [docen].[Br];  
GO

CREATE TABLE [docen].[Br] -- Bill Receipt
(
	brId BIGINT NOT NULL CONSTRAINT pk_docen_br_brid PRIMARY KEY (brId) DEFAULT LEFT(CAST(CAST(NEWID() AS VARBINARY(10)) AS Bigint),10),
	tranDate DATETIME NOT NULL DEFAULT [mastcode].[ufCDateTime](),
	bt VARCHAR(1) NOT NULL CONSTRAINT ck_docen_br_bt CHECK ([mastcode].[IsValidBillType](bt) > 0), -- DROP DOWN PROC [mastcode].[uspGetBillType]	
	bpName VARCHAR(100) NOT NULL,
	billNo VARCHAR(16) NULL, -- In Case of Billtype 'D' it should be null
	billDate DATETIME NULL, -- In Case of Billtype 'D' it should be null
	billAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
	transmode VARCHAR(1) NOT NULL, -- Drop Down from PROC [mastcode].[uspGetTransportMode]
	carrierName VARCHAR(50), -- Carrier Name
	vehicleNo VARCHAR(20),
	dcgrNo VARCHAR(16), -- Docket/GR No.
	dcgrDate DATETIME, -- Docket/GR Date
	ewaybillno VARCHAR(15),
	nopkt INT NOT NULL, -- No. of Packet Default 0
	docImage VARCHAR(100) NOT NULL, -- Document Proof
	posted tinyint NOT NULL DEFAULT 0
) ON [PRIMARY];
GO

IF OBJECT_ID (N'docen.uspAddBr', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspAddBr];  
GO

CREATE PROCEDURE [docen].[uspAddBr]    
(    
	@json NVARCHAR(MAX),     
	@STATUS SMALLINT = 0 OUTPUT    
)    
AS    
BEGIN    
	SET NOCOUNT ON;    
    BEGIN TRY    
		BEGIN TRANSACTION;  
		
		DECLARE @rowaffected INT = 0
		
		INSERT INTO [docen].[Br] (bt,
			bpName,
			billNo,
			billDate,
			billAmount,
			transmode,
			carrierName,
			vehicleNo,
			dcgrNo,
			dcgrDate,
			ewaybillno,
			nopkt,
			docImage)    
		SELECT bt, bpName, billNo, billDate, billAmount, transmode, carrierName, vehicleNo, dcgrNo, dcgrDate, ewaybillno, nopkt, docImage FROM OPENJSON(@json,'$')  
		WITH (  
			bt VARCHAR(1) '$.bt',
			bpName VARCHAR(100) '$.bpName',
			billNo VARCHAR(16) '$.billNo',
			billDate DATETIME '$.billDate',
			billAmount DECIMAL(12,2) '$.billAmount',
			transmode VARCHAR(1) '$.transmode',
			carrierName VARCHAR(50) '$.carrierName',
			vehicleNo VARCHAR(20) '$.vehicleNo',
			dcgrNo VARCHAR(16) '$.dcgrNo',
			dcgrDate DATETIME '$.dcgrDate',
			ewaybillno VARCHAR(15) '$.ewaybillno',
			nopkt INT '$.nopkt',
			docImage VARCHAR(100) '$.docImage') i;  
  
		SET @rowaffected = @@ROWCOUNT;
		IF @rowaffected > 0    
		BEGIN       
			COMMIT TRANSACTION;    
			SET @STATUS = @rowaffected;    
		END    
		ELSE    
		BEGIN    
			ROLLBACK TRANSACTION;    
			RAISERROR ('Check No. of parameters and data type', 16, 1);    
		END    
	END TRY    
	BEGIN CATCH    
		-- Rollback any active or uncommittable transactions before    
		-- inserting information in the ErrorLog    
		DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;    
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();    
    
		IF @@TRANCOUNT > 0    
		BEGIN    
			ROLLBACK TRANSACTION;    
		END    
    
		EXECUTE [dbo].[uspLogError];    
      
		SET @STATUS = 0;    
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);    
	END CATCH;    
END;
GO

IF OBJECT_ID (N'docen.uspUpdateBr', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspUpdateBr];  
GO

CREATE PROCEDURE [docen].[uspUpdateBr]
(    
	@json NVARCHAR(MAX),     
	@STATUS SMALLINT = 0 OUTPUT    
)    
AS    
BEGIN    
	SET NOCOUNT ON;    
    BEGIN TRY    
		BEGIN TRANSACTION;  
  		
		DECLARE @rowaffected INT = 0
		UPDATE [docen].[Br] SET bt = u.bt,
			bpName = u.bpName,
			billNo = u.billNo,
			billDate = u.billDate,
			billAmount = u.billAmount,
			transmode = u.transmode,
			carrierName = u.carrierName,
			vehicleNo = u.vehicleNo,
			dcgrNo = u.dcgrNo,
			dcgrDate = u.dcgrDate,
			ewaybillno = u.ewaybillno,
			nopkt = u.nopkt,
			docImage = COALESCE(u.docImage,Br.docImage) 
		FROM OPENJSON(@json,'$')  
		WITH (  
			brId BIGINT '$.brId',
			bt VARCHAR(1) '$.bt',
			bpName VARCHAR(100) '$.bpName',
			billNo VARCHAR(16) '$.billNo',
			billDate DATETIME '$.billDate',
			billAmount DECIMAL(12,2) '$.billAmount',
			transmode VARCHAR(1) '$.transmode',
			carrierName VARCHAR(50) '$.carrierName',
			vehicleNo VARCHAR(20) '$.vehicleNo',
			dcgrNo VARCHAR(16) '$.dcgrNo',
			dcgrDate DATETIME '$.dcgrDate',
			ewaybillno VARCHAR(15) '$.ewaybillno',
			nopkt INT '$.nopkt',
			docImage VARCHAR(100) '$.docImage') u WHERE Br.brId = u.brId;  
  
	  SET @rowaffected = @@ROWCOUNT;    
    
	  IF @rowaffected > 0    
	  BEGIN       
		COMMIT TRANSACTION;    
		SET @STATUS = @rowaffected;    
	  END    
	  ELSE    
	  BEGIN    
		ROLLBACK TRANSACTION;    
		RAISERROR ('Check No. of parameters and data type', 16, 1);    
	  END    
	  END TRY    
	BEGIN CATCH    
		-- Rollback any active or uncommittable transactions before    
		-- inserting information in the ErrorLog    
		DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;    
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();    
    
		IF @@TRANCOUNT > 0    
		BEGIN    
			ROLLBACK TRANSACTION;    
		END    
    
		EXECUTE [dbo].[uspLogError];    
      
		SET @STATUS = 0;    
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);    
	END CATCH;    
END;
GO

IF OBJECT_ID (N'docen.uspDeleteBr', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspDeleteBr];  
GO

CREATE PROCEDURE [docen].[uspDeleteBr]
(
	@brId BIGINT, -- NOT NULL
	@STATUS SMALLINT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
			DECLARE @rowaffected INT = 0
			DELETE [docen].[Br] WHERE brId = @brId;

			SET @rowaffected = @@ROWCOUNT;    
    
			IF @rowaffected > 0    
			BEGIN       
				COMMIT TRANSACTION;    
				SET @STATUS = @rowaffected;    
			END    
			ELSE    
			BEGIN    
				ROLLBACK TRANSACTION;    
				RAISERROR ('Check No. of parameters and data type', 16, 1);    
			END    
    END TRY
    BEGIN CATCH
        -- Rollback any active or uncommittable transactions before
        -- inserting information in the ErrorLog
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();

		IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END

        EXECUTE [dbo].[uspLogError];
		
		SET @STATUS = 0;
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;
GO

IF OBJECT_ID (N'docen.uspGetBr', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspGetBr];  
GO

CREATE OR ALTER PROCEDURE [docen].[uspGetBr]
AS
BEGIN
    SET NOCOUNT ON;
	SELECT [brId],[b].[tranDate],[b].[bt],[BillType].[btDescription],bpName,billNo,[mastcode].[ufGetIDate](billDate) As billDate,billAmount,[b].[transmode],[TransportMode].transDescription,carrierName,vehicleNo,dcgrNo,ewaybillno, [mastcode].[ufGetIDate](dcgrDate) dcgrDate,nopkt,docImage FROM [docen].[Br] AS [b]
	INNER JOIN [mastcode].[BillType] ON [b].[bt] = [BillType].[bt]
	INNER JOIN [mastcode].[TransportMode] ON [b].[transmode] = [TransportMode].[transmode]
	WHERE posted = 0 ORDER BY [b].[tranDate]
END;
GO

IF OBJECT_ID (N'docen.uspGetBrById', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspGetBrById];  
GO

CREATE OR ALTER PROCEDURE [docen].[uspGetBrById]
(
	@brId BIGINT
)
AS
BEGIN
    SET NOCOUNT ON;
	SELECT [brId],[b].[tranDate],[b].[bt],[BillType].[btDescription],bpName,billNo,[mastcode].[ufGetIDate](billDate) As billDate,billAmount,[b].[transmode],[TransportMode].transDescription,carrierName,vehicleNo,dcgrNo,ewaybillno, [mastcode].[ufGetIDate](dcgrDate) dcgrDate,nopkt,docImage FROM [docen].[Br] AS [b]
	INNER JOIN [mastcode].[BillType] ON [b].[bt] = [BillType].[bt]
	INNER JOIN [mastcode].[TransportMode] ON [b].[transmode] = [TransportMode].[transmode]	
	WHERE [b].[brid] = @brid;
END;
GO

IF OBJECT_ID (N'docen.uspGetBrRep', N'P') IS NOT NULL  
    DROP PROCEDURE [docen].[uspGetBrRep];  
GO

CREATE OR ALTER PROCEDURE [docen].[uspGetBr]
(
	@json NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	IF ISJSON(@json)<> 1
		THROW 5001,'Invalid JSON',1;

	DECLARE @brid BIGINT = JSON_VALUE(@json,'$.brid'),
	@bt VARCHAR(1)  = JSON_VALUE(@json,'$.bt'),
	@fromDate DATE = JSON_VALUE(@json,'$.fromDate'),
	@toDate DATE = JSON_VALUE(@json,'$.toDate'),
	@repType VARCHAR(1) = JSON_VALUE(@json,'$.repType');
	
	IF @repType NOT IN ('R','P')  
		THROW 5002,'Report Type Should be R OR P',1;

	SELECT [brId],[b].[tranDate],[b].[bt],[BillType].[btDescription],bpName,billNo,[mastcode].[ufGetIDate](billDate) As billDate,billAmount,[b].[transmode],[TransportMode].transDescription,carrierName,vehicleNo,dcgrNo,ewaybillno, [mastcode].[ufGetIDate](dcgrDate) dcgrDate,nopkt,docImage FROM [docen].[Br] AS [b]
			INNER JOIN [mastcode].[BillType] ON [b].[bt] = [BillType].[bt]
			INNER JOIN [mastcode].[TransportMode] ON [b].[transmode] = [TransportMode].[transmode]	
	WHERE (@repType = 'R'
		AND (@brid IS NULL OR [b].[brId] = @brid)
		AND (@bt   IS NULL OR [b].[bt]  = @bt)
		AND (@fromDate IS NULL OR CAST([b].[tranDate] AS DATE) >= @fromDate)
		AND (@toDate   IS NULL OR CAST([b].[tranDate] AS DATE) <= @toDate)
		)
		OR
		(@repType = 'P'
		AND [b].[posted] = 0
		);
END
GO

IF OBJECT_ID (N'fiac.Inward', N'U') IS NOT NULL  
    DROP TABLE [fiac].[Inward];  
GO 

CREATE TABLE [fiac].[Inward]
(
	transId BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_inward_lcode FOREIGN KEY (lcode) REFERENCES [mastcode].[LedgerCodes](lcode),
	billNo VARCHAR(16) NOT NULL,
	billDate DATETIME NOT NULL,
	naration VARCHAR(255) NULL,
	tdsCode VARCHAR(10) NULL CHECK (tdsCode IS NULL OR [mastcode].[IsValidTdsType](tdsCode) > 0),
	rtds DECIMAL(5,2) NOT NULL DEFAULT 0, 
	dbCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_inward_dbcode FOREIGN KEY (dbCode) REFERENCES [mastcode].[LedgerCodes](lcode),
	rc VARCHAR(1) NOT NULL CHECK (rc IN ('Y','N')) DEFAULT 'N', -- Drop Down [mastcode].[YesNo](yn)
	igstOnIntra VARCHAR(1) NOT NULL CHECK (igstOnIntra IN ('Y','N')), 
	qty DECIMAL(12, 3) NOT NULL DEFAULT 0,
	amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	discountAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	AssAmt AS amount - discountAmount,	
	tdsAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	gstAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
	CesAmt	DECIMAL (15,2) NOT NULL DEFAULT 0,
	Bcd	DECIMAL (15,2) NOT NULL DEFAULT 0,
	roff DECIMAL(5, 2) NOT NULL DEFAULT 0,	
	tamount DECIMAL(12,2) NOT NULL DEFAULT 0,
	payAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	bamount AS (tamount) - (payAmount + tdsAmount),
	docProof VARCHAR(100),
	brId BIGINT NULL CONSTRAINT fk_fiac_inward_brid FOREIGN KEY (brId) REFERENCES [docen].[Br](brId),
	grno BIGINT NULL,
	-- This will be implemented in special condition
	
	CesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	StateCesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	StateCesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	CONSTRAINT ck_fiac_inward_TDSCODE CHECK (CASE WHEN tdsCode IS NULL AND rtds > 0 THEN 0 WHEN tdsCode IS NOT NULL AND rtds < 0 THEN 0 ELSE 1 END > 0),
	CONSTRAINT ck_fiac_inward_TAMOUNT_PAYAMOUNT CHECK (tamount  >= (payAmount+tdsAmount)),
	--CONSTRAINT fk_fiac_inward_grno FOREIGN KEY (grno) REFERENCES [purchase].[Gr](grno),
) ON [PRIMARY];
GO

IF OBJECT_ID (N'fiac.InwardDetails', N'U') IS NOT NULL  
    DROP TABLE [fiac].[InwardDetails];  
GO 

CREATE TABLE [fiac].[InwardDetails]
(
	idId BIGINT NOT NULL CONSTRAINT fk_fiac_inwarddetails_idid PRIMARY KEY (idId) DEFAULT LEFT(ABS(CAST(CAST(NEWID() AS VARBINARY) AS BIGINT)),10),
	transId BIGINT NOT NULL CONSTRAINT fk_fiac_inwarddetails_transid FOREIGN KEY (transId) REFERENCES [fiac].[inward](transId) ON DELETE CASCADE,
	matno VARCHAR(15) NOT NULL CONSTRAINT fk_fiac_inwarddetails_matno FOREIGN KEY (matno) REFERENCES [purchase].[Material](matno),
	naration VARCHAR(50) NULL,
	hsnCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_inwarddetails_hsncode FOREIGN KEY (hsnCode) REFERENCES [mastcode].[HSN](hsnCode),
	qty DECIMAL(12,3) NOT NULL CHECK (QTY >= 0),
	unit VARCHAR(8) NOT NULL CONSTRAINT ck_mastcode_inwarddetails_unit CHECK ([mastcode].[IsValidUnit](unit) > 0), -- DROP DOWN PROC EXEC [mastcode].[uspGetUnit]
	rate DECIMAL(12,3) NOT NULL CHECK (RATE >= 0),
	amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	discountAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	AssAmt AS amount - discountAmount,
	GstRt DECIMAL(5,2) NOT NULL,
	GstAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
	roff DECIMAL(5, 2) NOT NULL DEFAULT 0,
	CesRt   DECIMAL (6,3) NULL DEFAULT 0,	
	CesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	Bcd	DECIMAL (15,3) NULL DEFAULT 0,

	tamount AS ((amount + gstAmount + roff)-discountAmount),	
	-- This will be implemented in special condition

	CesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	StateCesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	StateCesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
) ON [PRIMARY];
GO

IF OBJECT_ID (N'fiac.InwardVoucher', N'U') IS NOT NULL  
    DROP TABLE [fiac].[InwardVoucher];  
GO 

CREATE TABLE [fiac].[InwardVoucher]
(
	transId BIGINT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_inwardvoucher_lcode FOREIGN KEY (lcode) REFERENCES [mastcode].[LedgerCodes](lcode),
	billNo VARCHAR(16) NULL,
	billDate DATETIME NOT NULL,
	naration VARCHAR(255) NULL,
	tdsCode VARCHAR(10) NULL CHECK (tdsCode IS NULL OR [mastcode].[IsValidTdsType](tdsCode) > 0),
	rtds DECIMAL(5,2) NOT NULL DEFAULT 0, 
	dbCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_inwardvoucher_dbcode FOREIGN KEY (dbCode) REFERENCES [mastcode].[LedgerCodes](lcode),
	rc VARCHAR(1) NOT NULL CHECK (rc IN ('Y','N')) DEFAULT 'N', -- Drop Down [mastcode].[YesNo](yn)
	igstOnIntra VARCHAR(1) NOT NULL CHECK (igstOnIntra IN ('Y','N')), 
	qty DECIMAL(12,3) NULL DEFAULT 0,
	amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	discountAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	AssAmt AS amount - discountAmount,	
	tdsAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	GstAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
	roff DECIMAL(5, 2) NOT NULL DEFAULT 0,
	tamount DECIMAL(12,2) NOT NULL DEFAULT 0,	
	payAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	bamount AS (tamount) - (payAmount + tdsAmount),
	DocProof VARCHAR(100),
	brId BIGINT NULL CONSTRAINT fk_fiac_inwardvoucher_brid FOREIGN KEY (brId) REFERENCES [docen].[Br](brId),

	-- This will be implemented in special condition
	CesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	CesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	StateCesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	StateCesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	CONSTRAINT ck_fiac_inwardvoucher_TDSCODE CHECK (CASE WHEN tdsCode IS NULL AND rtds > 0 THEN 0 WHEN tdsCode IS NOT NULL AND rtds < 0 THEN 0 ELSE 1 END > 0),
	CONSTRAINT ck_fiac_inwardvoucher_TAMOUNT_PAYAMOUNT CHECK (tamount  >= (payAmount+tdsAmount)),
	--CONSTRAINT uk_fiac_inwardvoucher_lcode_billno UNIQUE (lcode,billNo)
	--CONSTRAINT fk_fiac_inward_grno FOREIGN KEY (grno) REFERENCES [purchase].[Gr](grno),
) ON [PRIMARY];
GO

IF OBJECT_ID (N'fiac.InwardVoucherDetails', N'U') IS NOT NULL  
    DROP TABLE [fiac].[InwardVoucherDetails];  
GO 

CREATE TABLE [fiac].[InwardVoucherDetails]
(
	idId BIGINT NOT NULL CONSTRAINT fk_fiac_inwardvoucherdetails_idid PRIMARY KEY (idId) DEFAULT LEFT(ABS(CAST(CAST(NEWID() AS VARBINARY) AS BIGINT)),10),
	transId BIGINT NOT NULL CONSTRAINT fk_fiac_inwardvoucherdetails_transid FOREIGN KEY (transId) REFERENCES [fiac].[InwardVoucher](transId) ON DELETE CASCADE,
	matno VARCHAR(15) NULL CONSTRAINT fk_fiac_inwardvoucherdetails_matno FOREIGN KEY (matno) REFERENCES [purchase].[Material](matno),
	naration VARCHAR(50) NULL,
	hsnCode VARCHAR(10) NULL CONSTRAINT fk_fiac_inwardvoucherdetails_hsncode FOREIGN KEY (hsnCode) REFERENCES [mastcode].[HSN](hsnCode),
	qty DECIMAL(12,3) NOT NULL CHECK (QTY >= 0),
	unit VARCHAR(8) NOT NULL CONSTRAINT ck_mastcode_inwardvoucherdetails_unit CHECK ([mastcode].[IsValidUnit](unit) > 0), -- DROP DOWN PROC EXEC [mastcode].[uspGetUnit]
	rate DECIMAL(12,3) NOT NULL CHECK (RATE >= 0),
	amount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	discountAmount DECIMAL(12, 2) NOT NULL DEFAULT 0,
	AssAmt AS amount - discountAmount,
	GstRt DECIMAL(5,2) NOT NULL,
	GstAmount DECIMAL(12,2) NOT NULL DEFAULT 0,
	roff DECIMAL(5, 2) NOT NULL DEFAULT 0,
	tamount AS ((amount + gstAmount + roff)-discountAmount),	
	-- This will be implemented in special condition
	CesRt   DECIMAL (6,3) NULL DEFAULT 0,	
	CesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	CesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
	StateCesAmt	DECIMAL (15,3) NULL DEFAULT 0,
	StateCesNonAdvlAmt DECIMAL (15,3) NULL DEFAULT 0,
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.TrInwardDetailsIns',N'TR') IS NOT NULL 
	DROP TRIGGER [fiac].[TrInwardDetailsIns];
GO

CREATE TRIGGER [fiac].[TrInwardDetailsIns] 
ON [fiac].[InwardDetails] 
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Delta AS (
        SELECT 
            ISNULL(i.transId, d.transId) AS transId,
            SUM(ISNULL(i.qty,0) - ISNULL(d.qty,0)) AS sumQty,
            SUM(ISNULL(i.amount,0) - ISNULL(d.amount,0)) AS sumAmount,
            SUM(ISNULL(i.discountAmount,0) - ISNULL(d.discountAmount,0)) AS sumDiscountAmount,
            SUM(ISNULL(i.gstAmount,0) - ISNULL(d.gstAmount,0)) AS sumGstAmount,
			SUM(ISNULL(i.CesAmt,0) - ISNULL(d.CesAmt,0)) AS sumCesAmt,
			SUM(ISNULL(i.Bcd,0) - ISNULL(d.Bcd,0)) AS sumBcd,
            SUM(ISNULL(i.roff,0) - ISNULL(d.roff,0)) AS sumRoff,
            SUM(ISNULL(i.tamount,0) - ISNULL(d.tamount,0)) AS sumTamount
        FROM inserted i
        FULL JOIN deleted d ON i.transId = d.transId
        GROUP BY ISNULL(i.transId, d.transId)
    )
    UPDATE iw
    SET 
        iw.qty            = iw.qty + d.sumQty,
        iw.amount         = iw.amount + d.sumAmount,
        iw.discountAmount = iw.discountAmount + d.sumDiscountAmount,
        iw.gstAmount      = iw.gstAmount + d.sumGstAmount,
		iw.CesAmt		  = iw.CesAmt + d.sumCesAmt,
		iw.Bcd			  = iw.Bcd + d.sumBcd,
        iw.roff           = iw.roff + d.sumRoff,
        iw.tamount        = iw.tamount + d.sumTamount,
        iw.tdsAmount      = CEILING(((iw.amount + d.sumAmount - (iw.discountAmount + d.sumDiscountAmount)) * iw.rtds * 0.01))
    FROM fiac.inward iw
    JOIN Delta d ON iw.transId = d.transId;
END;
GO

IF OBJECT_ID(N'fiac.uspAddInward',N'P') IS NOT NULL 
	DROP PROCEDURE [fiac].[uspAddInward];
GO

CREATE PROCEDURE [fiac].[uspAddInward]
(
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
	SET XACT_ABORT ON;

    IF ISJSON(@json) <> 1
        THROW 50001, 'Invalid JSON (root must be a JSON array)', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @Header TABLE
        (
            rn INT IDENTITY(1,1) PRIMARY KEY,
			lcode VARCHAR(10),
			billNo VARCHAR(16),
			billDate DATETIME,
			naration VARCHAR(255) NULL,
			tdsCode VARCHAR(10),
			rtds DECIMAL(5,2), 
			dbCode VARCHAR(10),
			rc VARCHAR(1),
			igstOnIntra VARCHAR(1),
			docProof VARCHAR(100),
			brId BIGINT,
			grno BIGINT,
            InwardDetails NVARCHAR(MAX)
        );

        INSERT INTO @Header (lcode, billNo, billDate, naration, tdsCode, dbCode, rc, igstOnIntra, docProof, brId, grno, InwardDetails)
        SELECT
            h.lcode,
            h.billNo,
            h.billDate,
			h.naration,
            ISNULL(h.tdsCode,'NA'),            
            h.dbCode,
            h.rc,
			lc.igstOnIntra,
			h.docProof,
            h.brId,
            h.grno,
            h.InwardDetails
        FROM OPENJSON(@json)
        WITH
        (
            lcode VARCHAR(10) '$.lcode',
            billNo VARCHAR(16) '$.billNo',
            billDate DATE '$.billDate',
			naration VARCHAR(255) '$.naration',
            tdsCode VARCHAR(10) '$.tdsCode',
            dbCode VARCHAR(10) '$.dbCode',
            rc VARCHAR(1) '$.rc',
			docProof VARCHAR(100) '$.docProof',
            brId BIGINT '$.brId',
            grno BIGINT '$.grno',
            InwardDetails NVARCHAR(MAX) '$.InwardDetails' AS JSON 
        ) AS h LEFT OUTER JOIN mastcode.LedgerCodes lc ON h.lcode = lc.lcode;

		UPDATE h SET rtds = t.rtds
		FROM @Header h
		INNER JOIN [mastcode].[TdsType] t ON h.tdsCode = t.tdsCode;

        DECLARE @errMsg NVARCHAR(4000);

        -- InwardDetails must be valid JSON array and not empty
        IF EXISTS (
            SELECT 1 FROM @Header h
            WHERE ISNULL(h.InwardDetails,'') = ''
               OR ISJSON(h.InwardDetails) <> 1
               OR NOT EXISTS (SELECT 1 FROM OPENJSON(h.InwardDetails))
        )
        BEGIN
            SELECT TOP 1 @errMsg = CONCAT('Header has missing or empty InwardDetails at Row No. ', rn)
            FROM @Header h
            WHERE ISNULL(h.InwardDetails,'') = ''
               OR ISJSON(h.InwardDetails) <> 1
               OR NOT EXISTS (SELECT 1 FROM OPENJSON(h.InwardDetails));
            THROW 50002, @errMsg, 1;
        END

        -- missing lcode
		SET @errMsg = NULL
		SELECT @errMsg = STRING_AGG(CONCAT(lcode, ' @row ', rn),', ')
		FROM (SELECT h.lcode,h.rn FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @errMsg IS NOT NULL
		BEGIN
			SET @errMsg = 'Invalid Ledger Code(s) '+ @errMsg;
			THROW 50003, @errMsg, 1;
		END

		-- missing dbCode
		SET @errMsg = NULL
		SELECT @errMsg = STRING_AGG(CONCAT(dbCode, ' @row ', rn),', ')
		FROM (SELECT h.dbCode,h.rn FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.dbCode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @errMsg IS NOT NULL
		BEGIN
			SET @errMsg = 'Invalid DbCode Code(s) '+ @errMsg;
			THROW 50004, @errMsg, 1;
		END
		
		-- missing tdsCode
		SET @errMsg = NULL
		SELECT @errMsg = STRING_AGG(CONCAT(tdsCode, ' @row ', rn),', ')
		FROM (SELECT h.tdsCode,h.rn FROM @Header h
				LEFT JOIN mastcode.TdsType t ON h.tdsCode = t.tdsCode
                WHERE t.tdsCode IS NULL)fk;
        IF @errMsg IS NOT NULL
		BEGIN
			SET @errMsg = 'Invalid TdsCode Code(s) '+ @errMsg;
			THROW 50005, @errMsg, 1;
		END

        -- missing billNo
        IF EXISTS (SELECT 1 FROM @Header WHERE ISNULL(LTRIM(RTRIM(billNo)), '') = '')
        BEGIN
            SELECT TOP 1 @errMsg = CONCAT('Missing billNo @row ', rn)
            FROM @Header WHERE ISNULL(LTRIM(RTRIM(billNo)), '') = '';
            THROW 50006, @errMsg, 1;
        END

        -- invalid/unparsed billDate
		IF EXISTS (SELECT 1 FROM @Header WHERE billDate IS NULL)
		BEGIN
			SELECT TOP 1 @errMsg = CONCAT('Missing billDate @row ', rn)
			FROM @Header WHERE billDate IS NULL;
			THROW 50007, @errMsg, 1;
		END
		
		-- Bill Calculation check
		IF EXISTS (
			SELECT 1 FROM @Header h
			CROSS APPLY OPENJSON(h.InwardDetails) 
			WITH (
			qty DECIMAL(12,3) '$.qty', 
			rate DECIMAL(12,3) '$.rate', 
			amount DECIMAL(12,2) '$.amount',
			discountAmount DECIMAL(12,2) '$.discountAmount',
			GstRt DECIMAL(5,2) '$.GstRt',
			GstAmount DECIMAL(12,2) '$.GstAmount') d
			WHERE d.qty <= 0 OR d.qty IS NULL 
			OR d.rate < 0 OR d.rate IS NULL 
			OR d.amount < 0 OR d.amount IS NULL
			OR d.GstRt IS NULL
			OR d.GstAmount IS NULL
			OR ABS(CEILING(d.qty * d.rate) - d.amount) > 1
			OR ABS(CEILING(((d.qty * d.rate) - ISNULL(d.discountAmount,0)) * d.GstRt * 0.01) - d.GstAmount) > 1
			) THROW 50008, 'Invalid Amount or GstRate or GstAmount in InwardDetails', 1;

		CREATE TABLE #Map (rn INT, transId BIGINT PRIMARY KEY);

		MERGE INTO fiac.inward as tgt
		USING @Header AS h
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT (
			lcode, billNo, billDate,naration, tdsCode, rtds,
			dbCode, rc, igstOnIntra, DocProof, brId, grno
		)
		VALUES (  
			h.lcode,
			h.billNo,
			h.billDate,
			h.naration,
			NULLIF(h.tdsCode,'NA'),
			ISNULL(h.rtds,0),
			h.dbCode,
			h.rc,
			h.igstOnIntra,
			h.docProof,
			h.brId,
			h.grno
		)
		OUTPUT inserted.transId, h.rn INTO #Map (transId, rn);
        INSERT INTO fiac.InwardDetails
        (
            transId, matno, naration, hsnCode, qty,
            unit, rate, amount, discountAmount, GstRt, GstAmount, CesRt, CesAmt, Bcd, roff
        )
        SELECT
            m.transId,
            d.matno,
            d.naration,
            d.hsnCode,
            d.qty,
            d.unit,
            d.rate,
            d.amount,
            d.discountAmount,
            d.GstRt,
            d.GstAmount,
			d.CesRt,	
			d.CesAmt,
			d.Bcd,
            d.roff
        FROM @Header h
        INNER JOIN #Map m ON h.rn = m.rn
        CROSS APPLY OPENJSON(h.InwardDetails)
        WITH
        (
            naration VARCHAR(200) '$.naration',
            matno VARCHAR(50) '$.matno',
            hsnCode VARCHAR(50) '$.hsnCode',
            qty DECIMAL(12,3) '$.qty',
            unit VARCHAR(20) '$.unit',
            rate DECIMAL(12,3) '$.rate',
            amount DECIMAL(12,2) '$.amount',
            discountAmount DECIMAL(18,2) '$.discountAmount',
            roff DECIMAL(12,2) '$.roff',
            GstRt DECIMAL(5,2) '$.GstRt',
            GstAmount DECIMAL(12,2) '$.GstAmount',
			CesRt   DECIMAL (6,3) '$.CesRt',	
			CesAmt	DECIMAL (15,3) '$.CesAmt',
			Bcd	DECIMAL (15,3) '$.Bcd'
        ) AS d;
		-- Ledger Posting
		;WITH Inw AS
		(    
			SELECT i.transId, i.BILLNO, i.billDate, i.igstOnIntra, i.lcode, i.dbCode, i.AssAmt, i.roff, i.GstAmount, i.CesAmt, i.TDSCODE, i.TDSAMOUNT,i.tamount,i.Bcd,i.naration FROM [fiac].[Inward] i
			INNER JOIN #Map m ON m.transId = i.transId
		)
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, drAmount, crAmount, narration,isBill,adjusted)
		SELECT Inw.transId      AS docId,
			'INW' AS docType,
			Inw.billDate AS tranDate,
			X.lcode,
			X.drAmount,
			X.crAmount,
			X.narration,
			X.isBill,
			X.adjusted
		FROM Inw
		CROSS APPLY
		(
			SELECT Inw.lcode, 0 AS drAmount, Inw.tamount AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO) AS narration,1 AS isBill,Inw.TDSAMOUNT AS adjusted
			UNION ALL SELECT Inw.dbCode, Inw.AssAmt + Inw.roff + Inw.Bcd AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.AssAmt > 0
			UNION ALL SELECT 'IGST', Inw.GstAmount AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'Y' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'SGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CESS', Inw.CesAmt AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.CesAmt > 0
			UNION ALL SELECT Inw.TDSCODE, 0 AS drAmount, Inw.TDSAMOUNT AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
			UNION ALL SELECT Inw.lcode, Inw.TDSAMOUNT AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
		) X;

        SET @STATUS = @@ROWCOUNT;
        IF @STATUS > 0
        BEGIN
            COMMIT TRANSACTION;
            RETURN;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            THROW 50009, 'No detail rows inserted. Check InwardDetails payload and data types.', 1;
        END

    END TRY
    BEGIN CATCH
		IF XACT_STATE() <> 0  
		BEGIN  
			ROLLBACK TRANSACTION;  
		END 

        DECLARE @ErrMsg1 NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrState INT = ERROR_STATE();

        SET @STATUS = 0;
		EXECUTE [dbo].[uspLogError]; 
        -- optionally log error here
        RAISERROR(@ErrMsg1, @ErrSeverity, @ErrState);
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspDeleteInward',N'P') IS NOT NULL 
	DROP PROCEDURE [fiac].[uspDeleteInward];
GO

CREATE PROCEDURE [fiac].[uspDeleteInward]  
(  
	@transId BIGINT,   
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
	SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowsAffected int
		
		DELETE [gl].[GeneralLedger] WHERE docId = @transId AND docType = 'INW'
		DELETE [fiac].[Inward] WHERE transId = @transId;

		SET @rowsAffected = @@ROWCOUNT;
		IF @rowsAffected > 0  
		BEGIN     
			COMMIT TRANSACTION;  
			SET @STATUS = @rowsAffected;  
		END  
		ELSE  
		BEGIN  
			ROLLBACK TRANSACTION;  
			RAISERROR ('Check No. of parameters and data type', 16, 1);  
		END  
		END TRY  
	BEGIN CATCH  
			-- Rollback any active or uncommittable transactions before  
			-- inserting information in the ErrorLog  
			DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
			SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
			IF @@TRANCOUNT > 0  
			BEGIN  
				ROLLBACK TRANSACTION;  
			END  
  
			EXECUTE [dbo].[uspLogError];  
    
			SET @STATUS = 0;  
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH;  
END;
-- Sample JSON
-- DECLARE @json NVARCHAR(MAX) = '{"ty":"M","lcode":"LT105","billNo":"2","billDate":"08/11/2025","naration":"Purchase Against. Bill No 1","hsnCode":null,"tdsCode":null,"rtds":0,"dbCode":"LT451","rc":"N","qty":10,"amount":100,"discountAmount":0,"tdsAmount":0,"GstRt":18,"GstAmount":18,"roff":0,"tamount":118,"DocProof":"","brId":5763649772,"grno":""}'
GO

IF OBJECT_ID(N'fiac.TrInwardVoucherDetailsIns',N'TR') IS NOT NULL 
	DROP TRIGGER [fiac].[TrInwardVoucherDetailsIns];
GO

CREATE TRIGGER [fiac].[TrInwardVoucherDetailsIns] 
ON [fiac].[InwardVoucherDetails] 
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH Delta AS (
        SELECT 
            ISNULL(i.transId, d.transId) AS transId,
            SUM(ISNULL(i.qty,0) - ISNULL(d.qty,0)) AS sumQty,
            SUM(ISNULL(i.amount,0) - ISNULL(d.amount,0)) AS sumAmount,
            SUM(ISNULL(i.discountAmount,0) - ISNULL(d.discountAmount,0)) AS sumDiscountAmount,
            SUM(ISNULL(i.gstAmount,0) - ISNULL(d.gstAmount,0)) AS sumGstAmount,
            SUM(ISNULL(i.roff,0) - ISNULL(d.roff,0)) AS sumRoff,
            SUM(ISNULL(i.tamount,0) - ISNULL(d.tamount,0)) AS sumTamount
        FROM inserted i
        FULL JOIN deleted d ON i.transId = d.transId
        GROUP BY ISNULL(i.transId, d.transId)
    )
    UPDATE iw
    SET 
        iw.qty            = iw.qty + d.sumQty,
        iw.amount         = iw.amount + d.sumAmount,
        iw.discountAmount = iw.discountAmount + d.sumDiscountAmount,
        iw.gstAmount      = iw.gstAmount + d.sumGstAmount,
        iw.roff           = iw.roff + d.sumRoff,
        iw.tamount        = iw.tamount + d.sumTamount,
        iw.tdsAmount      = CEILING(((iw.amount + d.sumAmount - (iw.discountAmount + d.sumDiscountAmount)) * iw.rtds * 0.01))
    FROM fiac.InwardVoucher iw
    JOIN Delta d ON iw.transId = d.transId;
END;
GO

IF OBJECT_ID(N'fiac.uspAddInwardVoucher',N'P') IS NOT NULL 
	DROP PROCEDURE [fiac].[uspAddInwardVoucher];
GO

CREATE PROCEDURE [fiac].[uspAddInwardVoucher]  
(  
	@json NVARCHAR(MAX),   
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN
	SET XACT_ABORT ON;
	SET NOCOUNT ON;  

	IF ISJSON(@json) !=1 
		THROW 50001,'Invalid JSON Input',1;

	DECLARE @Header TABLE
	(
		rn BIGINT NOT NULL IDENTITY(1,1),
		lcode VARCHAR(10),
		billNo VARCHAR(16),
		billDate DATETIME,
		naration VARCHAR(255),
		tdsCode VARCHAR(10),
		rtds DECIMAL(5,2), 
		dbCode VARCHAR(10),
		rc VARCHAR(1),
		igstOnIntra VARCHAR(1),
		DocProof VARCHAR(100),
		brId BIGINT,
		InwardVoucherDetails NVARCHAR(MAX)
	)
	INSERT INTO @Header (lcode,billNo,billDate,naration,tdsCode,dbCode,rc,igstOnIntra,DocProof,brId,InwardVoucherDetails)
	SELECT ijson.lcode,billNo,billDate,naration, ISNULL(ijson.tdsCode,'NA') AS tdsCode,dbCode,ijson.rc,lc.igstOnIntra,DocProof,brId,InwardVoucherDetails FROM OPENJSON (@json,'$')
	WITH (
			lcode VARCHAR(10),
			billNo VARCHAR(16),
			billDate DATETIME,
			naration VARCHAR(255),
			tdsCode VARCHAR(10),
			dbCode VARCHAR(10),
			rc VARCHAR(1),
			igstOnIntra VARCHAR(1),
			DocProof VARCHAR(100),
			brId BIGINT,
			InwardVoucherDetails NVARCHAR(MAX) '$.InwardVoucherDetails' AS JSON
		) ijson 
		LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON ijson.lcode = lc.lcode
	
		UPDATE h SET rtds = t.rtds
		FROM @Header h
		INNER JOIN [mastcode].[TdsType] t ON h.tdsCode = t.tdsCode;
		
		DECLARE @ErrorInput NVARCHAR(4000)
		
		-- InwardDetails must be valid JSON array and not empty
        IF EXISTS (
            SELECT 1 FROM @Header h
            WHERE ISNULL(h.InwardVoucherDetails,'') = ''
               OR ISJSON(h.InwardVoucherDetails) <> 1
			   OR NOT EXISTS (SELECT 1 FROM OPENJSON(h.InwardVoucherDetails))               
        )
        BEGIN
            SELECT TOP 1 @ErrorInput = CONCAT('Header has missing or empty InwardVoucherDetails at Row No. ', rn)
            FROM @Header h
            WHERE ISNULL(h.InwardVoucherDetails,'') = ''
               OR ISJSON(h.InwardVoucherDetails) <> 1
               OR NOT EXISTS (SELECT 1 FROM OPENJSON(h.InwardVoucherDetails));
            THROW 50002, @ErrorInput, 1;
        END

		-- checking missing lcode 
		SELECT @ErrorInput = STRING_AGG(CONCAT(lcode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.lcode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON h.lcode = lc.lcode
			WHERE lc.lcode IS NULL) fklcode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Ledger Code(s) : ' + @ErrorInput;
			THROW 50003,@ErrorInput,1;
		END
		-- checking missing dbCode 
		SET @ErrorInput = NULL;
		SELECT @ErrorInput = STRING_AGG(CONCAT(dbCode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.dbCode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON h.dbCode = lc.lcode
			WHERE lc.lcode IS NULL) fkdbcode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Ledger Code(s) : ' + @ErrorInput;
			THROW 50004,@ErrorInput,1;
		END
		
		-- checking tdsCode 
		SET @ErrorInput = NULL;
		SELECT @ErrorInput = STRING_AGG(CONCAT(tdsCode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.tdsCode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[TdsType] tt ON h.tdsCode = tt.tdsCode
			WHERE tt.tdsCode IS NULL) fktdsCode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Tds Code(s) : ' + @ErrorInput;
			THROW 50005,@ErrorInput,1;
		END

		IF EXISTS (
			SELECT 1 FROM @Header h
			CROSS APPLY OPENJSON(h.InwardVoucherDetails) 
			WITH (
			qty DECIMAL(12,3) '$.qty', 
			rate DECIMAL(12,3) '$.rate', 
			amount DECIMAL(12,2) '$.amount',
			discountAmount DECIMAL(12,2) '$.discountAmount',
			GstRt DECIMAL(5,2) '$.GstRt',
			GstAmount DECIMAL(12,2) '$.GstAmount') d
			WHERE d.qty <= 0 OR d.rate < 0 OR d.amount < 0
			OR ABS(CEILING(d.qty * d.rate) - d.amount) > 1
			OR ABS(CEILING(((d.qty * d.rate) - discountAmount) * d.GstRt * 0.01) - d.GstAmount) > 1
			) THROW 50006, 'Invalid Amount or GstRate or GstAmount in InwardVoucherDetails', 1;

    BEGIN TRY  
		BEGIN TRANSACTION;
			

		DECLARE @rowsAffected int

		CREATE TABLE #Map (rn INT, transId BIGINT);

		MERGE INTO [fiac].[InwardVoucher] AS tgt
		USING @Header AS h1 ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT (lcode, billNo, billDate,naration, tdsCode, rtds, dbCode, rc,	igstOnIntra, DocProof, brId)
		VALUES (lcode, billNo, billDate,naration, tdsCode, rtds, dbCode, rc,	igstOnIntra, DocProof, brId)
		OUTPUT inserted.transId, h1.rn INTO #Map (transId, rn);
		INSERT INTO [fiac].[InwardVoucherDetails] (transId,
			matno,
			naration,
			hsnCode,
			qty,
			unit,
			rate,
			amount,
			discountAmount,
			GstRt,
			GstAmount,
			roff)
		SELECT m.transId, [mastcode].[IsNullOrEmpty](matno) matno, [mastcode].[IsNullOrEmpty](d.naration) naration, [mastcode].[IsNullOrEmpty](hsnCode) hsnCode, qty, unit, rate, amount, discountAmount, GstRt, GstAmount, roff 
		FROM @Header h
        INNER JOIN #Map m ON h.rn = m.rn
        CROSS APPLY OPENJSON(h.InwardVoucherDetails)
       	WITH (
			matno VARCHAR(15) '$.matno',
			naration VARCHAR(50) '$.naration',
			hsnCode VARCHAR(10) '$.hsnCode',
			qty DECIMAL(12,3) '$.qty',
			unit VARCHAR(8) '$.unit',
			rate DECIMAL(12,3) '$.rate',
			amount DECIMAL(12,2) '$.amount',
			discountAmount DECIMAL(12,2) '$.discountAmount',
			GstRt DECIMAL(5,2) '$.GstRt',
			GstAmount DECIMAL(12,2) '$.GstAmount',
			roff DECIMAL(5,2) '$.roff') AS d	
 		
		-- Ledger Posting
		;WITH Inw AS
		(    
			SELECT i.transId, i.BILLNO, i.billDate, i.igstOnIntra, i.lcode, i.dbCode, i.AssAmt, i.roff, i.GstAmount, i.CesAmt, i.TDSCODE, i.TDSAMOUNT,i.tamount, i.naration FROM [fiac].[InwardVoucher] i
			INNER JOIN #Map m ON m.transId = i.transId
		)
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, drAmount, crAmount, narration,isBill,adjusted)
		SELECT Inw.transId      AS docId,
			'INV' AS docType,
			Inw.billDate AS tranDate,
			X.lcode,
			X.drAmount,
			X.crAmount,
			X.narration,
			X.isBill,
			X.adjusted
		FROM Inw
		CROSS APPLY
		(
			SELECT Inw.lcode, 0 AS drAmount, Inw.tamount AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO) AS narration,1 AS isBill,Inw.TDSAMOUNT AS adjusted
			UNION ALL SELECT Inw.dbCode, Inw.AssAmt + Inw.roff AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.AssAmt > 0
			UNION ALL SELECT 'IGST', Inw.GstAmount AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'Y' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'SGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CESS', Inw.CesAmt AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.CesAmt > 0
			UNION ALL SELECT Inw.TDSCODE, 0 AS drAmount, Inw.TDSAMOUNT AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
			UNION ALL SELECT Inw.lcode, Inw.TDSAMOUNT AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
		) X;

		SET @rowsAffected = @@ROWCOUNT;

		IF @rowsAffected > 0  
		BEGIN     
			COMMIT TRANSACTION;  
			SET @STATUS = @rowsAffected;  
		END  
		ELSE  
		BEGIN  
			ROLLBACK TRANSACTION;  
			RAISERROR ('Check No. of parameters and data type', 16, 1);  
		END  
		END TRY  
	BEGIN CATCH  
			-- Rollback any active or uncommittable transactions before  
			-- inserting information in the ErrorLog  
			DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
			SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
			IF XACT_STATE() <> 0  
			BEGIN  
				ROLLBACK TRANSACTION;  
			END  
  
			EXECUTE [dbo].[uspLogError];  

			SET @STATUS = 0;  
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH;  
END;
GO


IF OBJECT_ID(N'fiac.uspDeleteInwardVoucher',N'P') IS NOT NULL 
	DROP PROCEDURE [fiac].[uspDeleteInwardVoucher];
GO

CREATE PROCEDURE [fiac].[uspDeleteInwardVoucher]  
(  
	@transId BIGINT,   
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
	SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowsAffected int
		
		DELETE [fiac].[InwardVoucher] WHERE transId = @transId;

		SET @rowsAffected = @@ROWCOUNT;
		IF @rowsAffected > 0  
		BEGIN     
			COMMIT TRANSACTION;  
			SET @STATUS = @rowsAffected;  
		END  
		ELSE  
		BEGIN  
			ROLLBACK TRANSACTION;  
			RAISERROR ('Check No. of parameters and data type', 16, 1);  
		END  
		END TRY  
	BEGIN CATCH  
			-- Rollback any active or uncommittable transactions before  
			-- inserting information in the ErrorLog  
			DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
			SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
			IF @@TRANCOUNT > 0  
			BEGIN  
				ROLLBACK TRANSACTION;  
			END  
  
			EXECUTE [dbo].[uspLogError];  
    
			SET @STATUS = 0;  
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH;  
END;
-- Sample JSON
-- DECLARE @json NVARCHAR(MAX) = '{"ty":"M","lcode":"LT105","billNo":"2","billDate":"08/11/2025","naration":"Purchase Against. Bill No 1","hsnCode":null,"tdsCode":null,"rtds":0,"dbCode":"LT451","rc":"N","qty":10,"amount":100,"discountAmount":0,"tdsAmount":0,"GstRt":18,"GstAmount":18,"roff":0,"tamount":118,"DocProof":"","brId":5763649772,"grno":""}'
GO

IF OBJECT_ID(N'fiac.uspAddInwardVoucherSingle',N'P') IS NOT NULL 
	DROP PROCEDURE [fiac].[uspAddInwardVoucherSingle];
GO

CREATE PROCEDURE [fiac].[uspAddInwardVoucherSingle]  
(  
	@json NVARCHAR(MAX),   
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN
	SET XACT_ABORT ON;
	SET NOCOUNT ON;  

	IF ISJSON(@json) !=1 
		THROW 50001,'Invalid JSON Input',1;

	DECLARE @Header TABLE
	(
		rn BIGINT NOT NULL IDENTITY(1,1),
		lcode VARCHAR(10),
		billNo VARCHAR(16),
		billDate DATETIME,
		naration VARCHAR(255),
		tdsCode VARCHAR(10),
		rtds DECIMAL(5,2), 
		dbCode VARCHAR(10),
		rc VARCHAR(1),
		igstOnIntra VARCHAR(1),
		matno VARCHAR(15),
		hsnCode VARCHAR(10),
		qty DECIMAL(12,2) NOT NULL DEFAULT 1,
		unit VARCHAR(8) NOT NULL DEFAULT 'PCS',
		rate DECIMAL(12,2) NOT NULL DEFAULT 1,
		amount DECIMAL(18,2),
		discountAmount DECIMAL(18,2),
		GstRt DECIMAL(5,2),
		GstAmount DECIMAL(18,2),
		roff DECIMAL(10,2),
		tamount DECIMAL(18,2)		
	);

	INSERT INTO @Header (lcode,billNo,billDate,naration,tdsCode,dbCode,rc,igstOnIntra,amount,discountAmount,GstRt,GstAmount,roff,tamount)
	SELECT ijson.lcode,billNo,billDate,naration, ISNULL(ijson.tdsCode,'NA') AS tdsCode,dbCode,ijson.rc,lc.igstOnIntra,amount,discountAmount,GstRt,GstAmount,roff,tamount FROM OPENJSON (@json,'$')
	WITH (
			lcode VARCHAR(10),
			billNo VARCHAR(16),
			billDate DATETIME,
			naration VARCHAR(255),
			tdsCode VARCHAR(10),
			dbCode VARCHAR(10),
			rc VARCHAR(1),
			igstOnIntra VARCHAR(1),			
			amount DECIMAL(12,2),
			discountAmount DECIMAL(12,2),
			GstRt DECIMAL(5,2),
			GstAmount DECIMAL(12,2),
			roff DECIMAL(5, 2),
			tamount  DECIMAL(12,2)			
		) ijson 
		LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON ijson.lcode = lc.lcode
	
		UPDATE h SET rtds = t.rtds
		FROM @Header h
		INNER JOIN [mastcode].[TdsType] t ON h.tdsCode = t.tdsCode;
		
		DECLARE @ErrorInput NVARCHAR(4000)

		-- checking missing lcode 
		SELECT @ErrorInput = STRING_AGG(CONCAT(lcode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.lcode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON h.lcode = lc.lcode
			WHERE lc.lcode IS NULL) fklcode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Ledger Code(s) : ' + @ErrorInput;
			THROW 50003,@ErrorInput,1;
		END
		-- checking missing dbCode 
		SET @ErrorInput = NULL;
		SELECT @ErrorInput = STRING_AGG(CONCAT(dbCode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.dbCode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[LedgerCodes] lc ON h.dbCode = lc.lcode
			WHERE lc.lcode IS NULL) fkdbcode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Ledger Code(s) : ' + @ErrorInput;
			THROW 50004,@ErrorInput,1;
		END
		
		-- checking tdsCode 
		SET @ErrorInput = NULL;
		SELECT @ErrorInput = STRING_AGG(CONCAT(tdsCode, ' @row no. ', CAST(rn AS VARCHAR)),',') 
		FROM (SELECT h.tdsCode,h.rn FROM @Header h
			LEFT OUTER JOIN [mastcode].[TdsType] tt ON h.tdsCode = tt.tdsCode
			WHERE tt.tdsCode IS NULL) fktdsCode
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput = 'Invalid Tds Code(s) : ' + @ErrorInput;
			THROW 50005,@ErrorInput,1;
		END
		
		SET @ErrorInput = NULL;
		SELECT @ErrorInput = STRING_AGG(CONCAT('Calculation Error @row no. ', CAST(rn AS VARCHAR)),',') 		
		FROM (SELECT rn FROM @Header h
				WHERE amount < 0			
				OR ABS(CEILING((amount - discountAmount) * GstRt * 0.01) - GstAmount) > 1
				OR ABS(tamount - ((amount - discountAmount) + CEILING((amount - discountAmount) * GstRt * 0.01))) > 1
			) calcheck;
		IF @ErrorInput IS NOT NULL
		BEGIN
			SET @ErrorInput =  @ErrorInput;
			THROW 50005,@ErrorInput,1;
		END
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowsAffected int

		CREATE TABLE #Map (rn INT, transId BIGINT);
		
		MERGE [fiac].[InwardVoucher]
		USING @Header AS h
		ON 1 = 0
		WHEN NOT MATCHED THEN
		INSERT (lcode, billNo, billDate,naration, tdsCode, rtds, dbCode, rc, igstOnIntra)
		VALUES (lcode, billNo, billDate,naration, tdsCode, rtds, dbCode, rc, igstOnIntra)
		OUTPUT inserted.transId, h.rn INTO #Map (transId, rn);

		INSERT INTO [fiac].[InwardVoucherDetails] (transId,
			matno,
			naration,
			hsnCode,
			qty,
			unit,
			rate,
			amount,
			discountAmount,
			GstRt,
			GstAmount,
			roff)
		SELECT m.transId, matno, NULL naration,hsnCode, qty, unit, rate, amount, discountAmount, GstRt, GstAmount, roff	FROM @Header h
        INNER JOIN #Map m ON h.rn = m.rn
 		
		-- Ledger Posting
		;WITH Inw AS
		(    
			SELECT i.transId, i.BILLNO, i.billDate, i.igstOnIntra, i.lcode, i.dbCode, i.AssAmt, i.roff, i.GstAmount, i.CesAmt, i.TDSCODE, i.TDSAMOUNT,i.tamount, i.naration FROM [fiac].[InwardVoucher] i
			INNER JOIN #Map m ON m.transId = i.transId
		)
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, drAmount, crAmount, narration,isBill,adjusted)
		SELECT Inw.transId      AS docId,
			'INV' AS docType,
			Inw.billDate AS tranDate,
			X.lcode,
			X.drAmount,
			X.crAmount,
			X.narration,
			X.isBill,
			X.adjusted
		FROM Inw
		CROSS APPLY
		(
			SELECT Inw.lcode, 0 AS drAmount, Inw.tamount AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO) AS narration,1 AS isBill,Inw.TDSAMOUNT AS adjusted
			UNION ALL SELECT Inw.dbCode, Inw.AssAmt + Inw.roff AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.AssAmt > 0
			UNION ALL SELECT 'IGST', Inw.GstAmount AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'Y' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'SGST', Inw.GstAmount / 2.0 AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmount > 0
			UNION ALL SELECT 'CESS', Inw.CesAmt AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.CesAmt > 0
			UNION ALL SELECT Inw.TDSCODE, 0 AS drAmount, Inw.TDSAMOUNT AS crAmount, CONCAT(naration, ' BY BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
			UNION ALL SELECT Inw.lcode, Inw.TDSAMOUNT AS drAmount, 0 AS crAmount, CONCAT(naration, ' TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.TDSAMOUNT > 0
		) X;

		SET @rowsAffected = @@ROWCOUNT;

		IF @rowsAffected > 0  
		BEGIN     
			COMMIT TRANSACTION;  
			SET @STATUS = @rowsAffected;  
		END  
		ELSE  
		BEGIN  
			ROLLBACK TRANSACTION;  
			RAISERROR ('Check No. of parameters and data type', 16, 1);  
		END  
		END TRY  
	BEGIN CATCH  
			-- Rollback any active or uncommittable transactions before  
			-- inserting information in the ErrorLog  
			DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
			SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
			IF XACT_STATE() <> 0  
			BEGIN  
				ROLLBACK TRANSACTION;  
			END  
  
			EXECUTE [dbo].[uspLogError];  

			SET @STATUS = 0;  
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
	END CATCH;  
END;
GO

IF OBJECT_ID(N'fiac.SumInwardDetails',N'V') IS NOT NULL
	DROP VIEW [fiac].[SumInwardDetails];
GO

CREATE VIEW [fiac].[SumInwardDetails]
AS
SELECT transId, SUM(qty) sumQty, SUM(amount) sumAmount, SUM(discountAmount) sumDiscountAmount, SUM(AssAmt) sumAssAmt, SUM(GstAmount) sumGstAmount, SUM(roff) sumRoff, SUM(tamount) sumtamount FROM [fiac].[InwardDetails] GROUP BY transId
GO

IF OBJECT_ID(N'fiac.ViInward',N'V') IS NOT NULL
	DROP VIEW [fiac].[ViInward];
GO

CREATE VIEW [fiac].[ViInward]
AS
SELECT inw.transId,'B' AS vtype, inw.lcode, vlc.lname,vlc.city,vlc.stateName,vlc.Gstin,vlc.SupTyp,billNo, billDate, inw.tdsCode, rtds, dbCode, lc.lname dblname, inw.rc, inw.igstOnIntra, inw.Qty qty, inw.Amount amount, inw.discountAmount discountAmount, inw.AssAmt AssAmt, inw.tdsAmount, inw.GstAmount GstAmount, 
CASE WHEN inw.igstOnIntra = 'Y' THEN GstAmount ELSE 0 END igstAmount,
CASE WHEN inw.igstOnIntra = 'N' THEN GstAmount / 2.0 ELSE 0 END cgstAmount, 
CASE WHEN inw.igstOnIntra = 'N' THEN GstAmount / 2.0 ELSE 0 END sgstAmount,
inw.CesAmt,
inw.Bcd,
inw.roff roff, inw.tamount, inw.payAmount, inw.bamount, inw.DocProof, inw.brId, inw.grno FROM [fiac].[Inward] inw 
INNER JOIN [mastcode].[ViLedgerCodes] vlc ON inw.lcode = vlc.lcode
INNER JOIN [mastcode].[LedgerCodes] lc ON inw.dbCode = lc.lcode
UNION ALL SELECT inwv.transId, 'V' AS vtype, inwv.lcode, vlc.lname,vlc.city,vlc.stateName,vlc.Gstin,vlc.SupTyp, inwv.billNo, inwv.billDate, inwv.tdsCode, inwv.rtds, inwv.dbCode, lc.lname dblname, inwv.rc, inwv.igstOnIntra, inwv.qty, inwv.amount, inwv.discountAmount, inwv.AssAmt, inwv.tdsAmount, inwv.GstAmount, 
CASE WHEN inwv.igstOnIntra = 'Y' THEN GstAmount ELSE 0 END igstAmount,
CASE WHEN inwv.igstOnIntra = 'N' THEN GstAmount / 2.0 ELSE 0 END cgstAmount, 
CASE WHEN inwv.igstOnIntra = 'N' THEN GstAmount / 2.0 ELSE 0 END sgstAmount,
0 AS CesAmt,
0 AS Bcd,
inwv.roff, inwv.tamount AS tamount, inwv.payAmount, inwv.bamount, inwv.DocProof, inwv.brId,null grno FROM [fiac].[InwardVoucher] inwv
INNER JOIN [mastcode].[ViLedgerCodes] vlc ON inwv.lcode = vlc.lcode
INNER JOIN [mastcode].[LedgerCodes] lc ON inwv.dbCode = lc.lcode
GO

CREATE VIEW [fiac].[Purchase]
AS
SELECT transId,vtype, lcode,lname,city,stateName,billNo,billDate,tamount,tdsAmount,payAmount As paid,bamount FROM [fiac].[ViInward] 
GO

IF OBJECT_ID(N'fiac.uspGetInwardRep',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspGetInwardRep];
GO

CREATE PROCEDURE [fiac].[uspGetInwardRep]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @vtype VARCHAR(1) = JSON_VALUE(@json,'$.vtype'),
		@rc VARCHAR(1) = JSON_VALUE(@json,'$.rc'),
		@tds VARCHAR(10) = JSON_VALUE(@json,'$.tds'),
		@igstOnIntra VARCHAR(1) = JSON_VALUE(@json,'$.igstOnIntra'),		
		@lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode'),
		@fdate DATETIME = JSON_VALUE(@json,'$.fdate'),
		@tdate DATETIME = JSON_VALUE(@json,'$.tdate')

	SELECT transId, vtype, lcode, lname, city, stateName,Gstin,SupTyp,billNo, billDate,[mastcode].[ufGetIDate](billDate) dbillDate, tdsCode, rtds, dbCode, dblname, rc, igstOnIntra, qty, amount, discountAmount, AssAmt, tdsAmount, GstAmount, igstAmount, cgstAmount, sgstAmount,CesAmt,Bcd,roff, tamount, payAmount, bamount, DocProof, brId, grno FROM [fiac].[ViInward] 
	WHERE billDate >= @fdate AND billDate <= @tdate
	AND	(@vtype IS NULL OR vtype = @vtype)
	AND (@rc IS NULL or rc = @rc)
	AND (@igstOnIntra IS NULL OR igstOnIntra = @igstOnIntra)
	AND (@tds IS NULL OR tdsCode != 'NA')
	AND (@lcode IS NULL OR lcode = @lcode)
	ORDER BY billDate;	
END;
GO

IF OBJECT_ID(N'sales.Sale', N'U') IS NOT NULL
	DROP TABLE [sales].[Sale];
GO

CREATE TABLE [sales].[Sale]
(
	docId BIGINT NOT NULL IDENTITY (1,1) PRIMARY KEY,
	[No] VARCHAR(16) NOT NULL CONSTRAINT ck_sales_sale_no CHECK ([mastcode].[IsValidDocno]([No]) > 0),
	Dt DATE NOT NULL,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_sales_sale_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode), -- DROP DOWN PROC EXEC [mastcode].[uspGetLedgerCodesDropDown]
	crCode VARCHAR(10) NOT NULL CONSTRAINT fk_sales_saled_crcode FOREIGN KEY (crCode) REFERENCES [mastcode].[LedgerCodes](lcode),
	curCode VARCHAR(7) NULL DEFAULT 'INR', -- DROP Down from [mastcode].[Currency](curCode)
	conRate DECIMAL(6,2) NOT NULL DEFAULT 1,
	
	orderId BIGINT NULL,
	poNo VARCHAR(30) NULL,
	poDate DATETIME NULL,
	privateMark VARCHAR(20) NULL,
	-- IF shipId IS NOT NULL then Shipping Details Required
	shipId BIGINT NULL,
	
	-- Below is Auto Populated from lcode [NO INPUT REQUIRED]
	TaxSch VARCHAR(10) DEFAULT 'GST', -- Tax Scheme [NOT FOR INPUT]
	-- IF SupTyp is not B2B Then Export Details Required
	IgstOnIntra VARCHAR(1) NOT NULL CHECK (IgstOnIntra IN ('Y','N')),
	SupTyp VARCHAR(10) NOT NULL CHECK ([mastcode].[IsValidGstSupplyType](SupTyp)>0), -- DROP DOWN PROC [mastcode].[uspGetGstSupplyType] [NOT FOR INPUT]
	RegRev VARCHAR(1) NOT NULL DEFAULT 'N' CHECK (RegRev IN ('Y','N')), -- Reverse Charges	[NOT FOR INPUT]
	Typ VARCHAR(3) NOT NULL DEFAULT 'INV', -- DROP DOWN PROC [mastcode].[uspGetDocType] [NOT FOR INPUT]
	EcmGstin VARCHAR(15) NULL CHECK(EcmGstin IS NULL OR [mastcode].[IsValidGSTIN](EcmGstin) > 0), -- Selling to ECOM Operator [NOT FOR INPUT]

	-- Buyer Details 
	Gstin VARCHAR(15) NOT NULL CHECK ([mastcode].[IsValidGSTIN](Gstin)>0),
	LglNm VARCHAR(100) NOT NULL,
	Pos VARCHAR(2) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(100) NOT NULL,
	Stcd VARCHAR(2) NOT NULL,
	StName VARCHAR(50) NOT NULL,
	Pin BIGINT NOT NULL CHECK (Pin >= 100000 AND Pin <= 999999),
	Ph VARCHAR(12) NULL CHECK (Ph IS NULL OR [mastcode].[IsValidPhone](Ph) > 0),
	Em VARCHAR(100) NULL, -- Email

	-- Item Summary 
	Qty	DECIMAL (15,3) NOT NULL DEFAULT 0,
	TotAmt DECIMAL (15,3) NOT NULL DEFAULT 0,
	Discount DECIMAL (15,3) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,3) NOT NULL DEFAULT 0,
	GstAmt DECIMAL (15,3) NOT NULL DEFAULT 0,
	TotVal DECIMAL (15,3) NOT NULL DEFAULT 0,
	adjAmount DECIMAL (15,3) NOT NULL DEFAULT 0,
	unadjusted AS TotVal - adjAmount PERSISTED,
	CONSTRAINT uk_sales_sale_no UNIQUE([No]), 
	CONSTRAINT ck_sales_sale_shipid CHECK (shipId IS NULL OR [mastcode].[IsValidShippingId](lcode,shipId) > 0)
) ON [PRIMARY];
GO

-- Shiping Details Required, If Buyer Address and Shiping address is not same
IF OBJECT_ID(N'sales.SaleShipping',N'U') IS NOT NULL
	DROP TABLE [sales].[SaleShipping];
GO

CREATE TABLE [sales].[SaleShipping]
(
	docId BIGINT NOT NULL CONSTRAINT pk_sales_saleshipping_docid PRIMARY KEY
		CONSTRAINT fk_sales_saleshipping_docid REFERENCES [sales].[Sale](docId) ON DELETE CASCADE,
	LglNm VARCHAR(100) NOT NUll,
	Addr1 VARCHAR(100) NOT NULL	,
	Addr2  VARCHAR(100) NULL,
	Loc	VARCHAR(100) NOT NULL,
	Pin	BIGINT NOT NULL CONSTRAINT ck_sales_saleshipping_pin CHECK (Pin >= 100000 AND Pin <= 999999),	
	Stcd VARCHAR(2) NOT NULL,
	Gstin VARCHAR(15) NULL CONSTRAINT ck_sales_saleshipping_gstin CHECK (Gstin IS NULL OR [mastcode].[IsValidGSTIN](Gstin) > 0),
) ON [PRIMARY];
GO

IF OBJECT_ID(N'sales.SaleGoodsDispatch',N'U') IS NOT NULL
	DROP TABLE [sales].[SaleGoodsDispatch];
GO

CREATE TABLE [sales].[SaleGoodsDispatch]
(
	docId BIGINT NOT NULL CONSTRAINT pk_sales_salegoodsdispatch_no PRIMARY KEY CONSTRAINT fk_sales_salegoodsdispatch_docid REFERENCES [sales].[Sale](docId),
	Dt DATE NOT NULL,
	carId BIGINT NULL, -- Drop Down from [mastcode].[Carrier](carId)
	mof VARCHAR(1) NOT NULL, -- Drop down PROC [mastcode].[uspGetModeOfFreight]
	TransMode VARCHAR(1) NOT NULL, -- Drop Down Proc [mastcode].[uspGetTransportMode]
	TransId	VARCHAR(15) NULL CONSTRAINT ck_sales_salegoodsdispatch_transid CHECK (TransId IS NULL OR [mastcode].[IsValidGSTIN](TransId) > 0),
	TransName VARCHAR(100) NULL,	
	Distance INT NOT NULL DEFAULT 0,
	TransDocNo VARCHAR(15) NULL,
	TransDocDt	DATE NULL,
	VehNo VARCHAR(20) NOT NULL,
	VehType	VARCHAR(1) NOT NULL -- Drop Down PROC [mastcode].[uspGetVehicleType]
) ON [PRIMARY];
GO


-- Export Sale
IF OBJECT_ID(N'sales.SaleExport',N'U') IS NOT NULL
	DROP TABLE [sales].[SaleExport];
GO

CREATE TABLE [sales].[SaleExport]
(
	docId BIGINT NOT NULL CONSTRAINT pk_sales_saleexport_docid PRIMARY KEY CONSTRAINT fk_sales_saleexport_docid REFERENCES [sales].[Sale](docId),
	goodsDescription VARCHAR(100) NULL,
	termOfDelivery VARCHAR(200) NULL,
	lutno VARCHAR(30) NULL,
	portLoading	VARCHAR(10) NULL,
	placeOfReceipt VARCHAR(100),  -- Port of Loading and Place of receipt is same but some is written in text
	portDischarge VARCHAR(100) NULL,
	CntCode	VARCHAR(2) NOT NULL CONSTRAINT ck_sales_saleexport_cntcode CHECK ([mastcode].[IsValidCountries](CntCode) > 0),
	finalDestination VARCHAR(100),
	RefClm	VARCHAR(1) CHECK (RefClm IN ('Y','N')),
	ForCur	VARCHAR(16) NOT NULL, -- Reference Currency Code
	cost DECIMAL(12,2) NOT NULL  DEFAULT 0,	
	insurance DECIMAL(12,2) NOT NULL  DEFAULT 0,
	freight DECIMAL(12,2) NOT NULL DEFAULT 0,
	pkt INT NOT NULL DEFAULT 0,
	gwt DECIMAL(12,3) NOT NULL DEFAULT 0,
	nwt DECIMAL(12,3) NOT NULL DEFAULT 0,
	ExpDuty	DECIMAL(12,2) NULL,
	ShipBNo VARCHAR(20),
	ShipBDt	DATE
) ON [PRIMARY];
GO

IF OBJECT_ID(N'sales.SaleItemDetails', N'U') IS NOT NULL
	DROP TABLE [sales].[SaleItemDetails];
GO

CREATE TABLE [sales].[SaleItemDetails]
(
	sdId BIGINT NOT NULL CONSTRAINT pk_sales_saleitemdetails_sidid PRIMARY KEY IDENTITY(1,1),
	docId BIGINT NOT NULL CONSTRAINT fk_sales_saleitemdetails_docId REFERENCES [sales].[Sale](docId) ON DELETE CASCADE,
	Barcde VARCHAR(30) NULL,
	matno VARCHAR(15) NULL CONSTRAINT fk_sales_saleitemdetails_matno REFERENCES [purchase].[Material](matno),	
	PrdDesc VARCHAR(300) NOT NULL, -- Product Description
	HsnCd VARCHAR(8) NOT NULL,
	Qty	DECIMAL (15,3) NOT NULL,
	Mrp DECIMAL(15,3) NULL,
	UnitPrice DECIMAL (15,3) NOT NULL,
	Unit VARCHAR(8) NOT NULL CHECK ([mastcode].[IsValidUnit](Unit) > 0),
	TotAmt DECIMAL (15,3) NOT NULL, --	Gross Amount (Unit Price * Quantity)
	Discount DECIMAL (15,3) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,3) NOT NULL,	-- Taxable Value (Total Amount -Discount)
	GstRt DECIMAL(6,2) NOT NULL,
	GstAmt DECIMAL (15,3) NOT NULL,
	-- These are customisable field 
	CesRt   DECIMAL (6,3) NULL,
	CesAmt	DECIMAL (15,3) NULL,
	CesNonAdvlAmt DECIMAL (15,3) NULL,
	StateCesRt	DECIMAL (6,3) NULL,
	StateCesAmt	DECIMAL (15,3) NULL,
	StateCesNonAdvlAmt DECIMAL (15,3) NULL,
	
	TotItemVal	AS CAST((TotAmt + GstAmt - Discount) AS DECIMAL(12,2)), -- CesAmt + CesNonAdvlAmt + StateCesAmt + StateCesNonAdvlAmt
	-- Free Qty Bundle
	FreeQty	DECIMAL (15,3) NOT NULL DEFAULT 0, -- Free Quantity
	FreeUnitPrice DECIMAL (15,3) NOT NULL DEFAULT 0,
	CONSTRAINT uk_sales_saleitemdetails_no_matno UNIQUE ([docId],matno),
	CONStraint ck_fiac_saleitemdetails_qty_unitprice CHECK (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_saleitemdetails_totamt CHECK(CEILING((TotAmt - Discount)) - AssAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_saleitemdetails_assamt CHECK(CEILING((TotAmt - Discount)) - CEILING(AssAmt) BETWEEN 0 AND 1),
	CONStraint ck_fiac_saleitemdetails_gstamt CHECK(CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
) ON [PRIMARY];
GO

CREATE TRIGGER [sales].[Tr_SaleItemDetails]
ON [sales].[SaleItemDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- All docIds affected by the INSERT, UPDATE, DELETE
    ;WITH ChangedDocs AS (
        SELECT docId FROM inserted
        UNION
        SELECT docId FROM deleted
    ),
    -- Aggregate current child totals
    Agg AS (
        SELECT 
            d.docId,
            SUM(d.Qty)                                   AS TotalQty,
            SUM(d.TotAmt)                                AS TotalTotAmt,
            SUM(ISNULL(d.Discount,0))                    AS TotalDiscount,
            SUM(ISNULL(d.AssAmt,0))                      AS TotalAssAmt,
            SUM(ISNULL(d.GstAmt,0))                      AS TotalGstAmt,
            SUM(ISNULL(d.TotAmt,0) + ISNULL(d.GstAmt,0) - ISNULL(d.Discount,0)) AS TotalTotVal
        FROM [sales].[SaleItemDetails] d
        WHERE EXISTS (SELECT 1 FROM ChangedDocs cd WHERE cd.docId = d.docId)
        GROUP BY d.docId
    )
    -- Update parent rows
    UPDATE s
    SET
        Qty      = ISNULL(a.TotalQty, 0),
        TotAmt   = ISNULL(a.TotalTotAmt, 0),
        Discount = ISNULL(a.TotalDiscount, 0),
        AssAmt   = ISNULL(a.TotalAssAmt, 0),
        GstAmt   = ISNULL(a.TotalGstAmt, 0),
        TotVal   = ISNULL(a.TotalTotVal, 0)
    FROM [sales].[Sale] s
    INNER JOIN ChangedDocs cd ON s.docId = cd.docId
    LEFT JOIN Agg a ON s.docId = a.docId;

    -- Auto-delete parent Sale if no child rows remain
	-- Uncomment if require
    --DELETE s
    --FROM [sales].[Sale] s
    --INNER JOIN ChangedDocs cd ON s.docId = cd.docId
    --WHERE NOT EXISTS (
    --    SELECT 1 FROM [sales].[SaleItemDetails] d WHERE d.docId = s.docId
    --);
END
GO

CREATE TRIGGER [sales].[Tr_Sale]
ON [sales].[Sale]
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- DELETE ALL ROW IF EXISTS 
	DELETE d FROM [sales].[SaleShipping] d INNER JOIN inserted i ON d.docId = i.docId 
	-- INSERT NEW RECORD
	INSERT INTO [sales].[SaleShipping] (docId,LglNm,Addr1,Addr2,Loc,Pin,Stcd,Gstin)
	SELECT i.docId,cs.LglNm, cs.Addr1, cs.Addr2, cs.Loc, cs.Pin, cs.Stcd, cs.Gstin FROM inserted i 
	INNER JOIN [mastcode].[CustomerShipping] cs ON i.shipId = cs.shipCode WHERE i.shipId IS NOT NULL
END
GO

IF OBJECT_ID(N'sales.EInvoice', N'U') IS NOT NULL
	DROP TABLE [sales].[EInvoice];
GO

CREATE TABLE [sales].[EInvoice]
(
	docno BIGINT NOT NULL CONSTRAINT pk_sales_einvoice_docno PRIMARY KEY (docno),
	doctype	VARCHAR(3),
	docdate	DATETIME,
	billValue DECIMAL(15,2),
	irn	VARCHAR(64),
	ackno VARCHAR(20),	
	ackdate	DATETIME,
	rgstin VARCHAR(16),
	status VARCHAR(10),
	sqrcode	VARCHAR(max),
	ewbno VARCHAR(15),
) ON [PRIMARY];
GO

IF OBJECT_ID(N'sales.uspAddSale',N'P') IS NOT NULL
	DROP PROCEDURE [sales].[uspAddSale];
GO

CREATE PROCEDURE [sales].[uspAddSale]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;
			
        DECLARE @Header TABLE (
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			crCode VARCHAR(10),
			poNo VARCHAR(30) NULL,
			poDate DATETIME NULL,
			privateMark VARCHAR(20) NULL,
			shipId BIGINT NULL,
			SaleItemDetails NVARCHAR(MAX)
        );
		DECLARE @HeaderItem TABLE
		(
			[No] VARCHAR(16),
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)	
		)

		;WITH input AS (
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,[No],Dt,lcode,crCode,poNo,poDate,privateMark,shipId,SaleItemDetails FROM OPENJSON(@json)
			WITH (	
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			crCode VARCHAR(10),
			poNo VARCHAR(30),
			poDate DATETIME,
			privateMark VARCHAR(20),
			shipId BIGINT,
			SaleItemDetails NVARCHAR(MAX) AS JSON)
			),
			NewDocNo AS (
				SELECT 
					ISNULL(DIN.docName+'/'+TRY_CAST(DIN.fiYear AS varchar)+'/' + HMax.maxDocno, DIN.docno) AS baseDocno
				FROM (
					SELECT 		 
					TRY_CAST(
					MAX(
					TRY_CAST(
					RIGHT(h.[No], 
					  NULLIF(CHARINDEX('/', REVERSE(h.[No])) - 1, -1))
					AS bigint)
					) AS varchar)
					 AS maxDocno FROM [sales].[Sale] h
				) AS HMax
				CROSS APPLY (
					SELECT docName,initialNo,fiYear,docno FROM [mastcode].[DocInitialNo] WHERE docName = 'INV'
				) AS DIN
			)

        INSERT INTO @Header (rn,[No],Dt,lcode,crCode,poNo,poDate,privateMark,shipId,SaleItemDetails)
		SELECT rn,ISNULL(Input.[No], [mastcode].[NewDocNo](NewDocNo.baseDocno, Input.rn)) [No],Dt,lcode,crCode,poNo,poDate,privateMark,shipId,SaleItemDetails FROM input
		CROSS JOIN NewDocNo

		INSERT INTO @HeaderItem ([No], matno, PrdDesc, HsnCd, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT h.[No],
			d.matno,
			COALESCE(d.PrdDesc,mt.matDescription) AS PrdDesc,
			d.HsnCd,
			TRY_CAST(d.Qty AS DECIMAL(15,2)) AS Qty,
			TRY_CAST(d.UnitPrice AS DECIMAL(15,2)) AS UnitPrice,
			d.Unit,
			TRY_CAST(d.TotAmt AS DECIMAL(15,2)) AS TotAmt,
			TRY_CAST(d.Discount AS DECIMAL(15,2)) AS Discount,
			TRY_CAST(d.AssAmt AS DECIMAL(15,2)) AS AssAmt,			
			TRY_CAST(d.GstRt AS DECIMAL(6,2)) AS GstRt,
			TRY_CAST(d.GstAmt AS DECIMAL(15,2)) AS GstAmt
		FROM @Header h
		CROSS APPLY OPENJSON(h.SaleItemDetails,'$')
		WITH (
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			Qty	DECIMAL (15,2),
			UnitPrice DECIMAL (15,2),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,2),
			Discount DECIMAL (15,2),
			AssAmt  DECIMAL (15,2),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,2)
		) AS d		
		LEFT OUTER JOIN [purchase].[Material] mt ON d.matno = mt.matno;

        DECLARE @ValidationError NVARCHAR(MAX)

		-- DocNo Check Either Manual Or Auto
		IF (SELECT CASE WHEN COUNT([No]) = 0 THEN 1
				WHEN COUNT(*) = COUNT([No]) THEN 1
				ELSE 0
				END AS Result
				FROM @Header) <= 0		
			THROW 61002, 'Either All DocNo should be Null OR Not Null', 1;

		-- Validate foreign keys        
		SELECT @ValidationError = STRING_AGG(lcode,',')
		FROM (SELECT h.lcode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(crCode,',')
		FROM (SELECT h.crCode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.crCode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Item Details Validation Start
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
				LEFT JOIN purchase.Material m ON hi.matno = m.matno AND m.mst = 'A'
                WHERE hi.matno IS NOT NULL AND m.matno IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Material No(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE PrdDesc IS NULL 
				OR HsnCd IS NULL 
				OR Qty IS NULL
				OR UnitPrice IS NULL
				OR Unit IS NULL 
				OR TotAmt IS NULL
				OR AssAmt IS NULL 
				OR GstRt IS NULL
				OR GstAmt IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Line item Of Material No(s) have some null values '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Calculation Check
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE NOT (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1) 
				OR NOT ((CEILING(TotAmt) - Discount) - CEILING(AssAmt) BETWEEN 0 AND 1)
				OR NOT (CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
				)mic;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Calculation Error in Matno : '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

        BEGIN TRANSACTION;
        
		INSERT INTO [sales].[Sale] (No, Dt, lcode, crCode, poNo, poDate, privateMark, shipId, IgstOnIntra, SupTyp, EcmGstin, Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em)
		SELECT ha.[No],	ha.Dt, ha.lcode, ha.crCode,	ha.poNo, ha.poDate, ha.privateMark,ha.shipId, lc.igstOnIntra,   
		lc.SupTyp, IIF(lc.isEcom ='Y',lc.Gstin,NULL) EcmGstin, lc.Gstin, lc.lname, lc.Stcd, lc.[add], lc.add1, lc.city Loc, lc.Stcd, lc.stateName, lc.zipCode, lc.phone, lc.email 
		FROM @Header ha INNER JOIN [mastcode].[ViLedgerCodes] lc ON ha.lcode = lc.lcode

		INSERT INTO [sales].[SaleItemDetails] (docId, matno, PrdDesc, HsnCd,  Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT docId, matno, PrdDesc, HsnCd, hi.Qty, UnitPrice, Unit, hi.TotAmt, hi.Discount, hi.AssAmt, GstRt, hi.GstAmt FROM @HeaderItem hi
		INNER JOIN [sales].[Sale] sdb ON hi.[No] = sdb.[No]

		-- Ledger Posting
		;WITH Inw AS
		(    
			SELECT s.docId, s.[No] BILLNO, s.Dt, s.igstOnIntra, s.lcode, s.crCode, s.AssAmt, s.GstAmt,s.TotVal FROM @Header i
			INNER JOIN [sales].[Sale] s ON i.[No] = s.[No]
			
		)
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, drAmount, crAmount, narration,isBill,adjusted)
		SELECT Inw.docId AS docId,
			'INV' AS docType,
			Inw.Dt AS tranDate,
			X.lcode,
			X.drAmount,
			X.crAmount,
			X.narration,
			X.isBill,
			X.adjusted
		FROM Inw
		CROSS APPLY
		(
			SELECT Inw.lcode, Inw.TotVal AS drAmount, 0 AS crAmount, CONCAT('BY BILL NO. ', Inw.BILLNO) AS narration,1 AS isBill,0 AS adjusted
			UNION ALL SELECT Inw.crCode, 0 AS drAmount, Inw.AssAmt AS crAmount, CONCAT('TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.AssAmt > 0
			UNION ALL SELECT 'IGST', 0 AS drAmount, Inw.GstAmt AS crAmount, CONCAT('TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'Y' AND Inw.GstAmt > 0
			UNION ALL SELECT 'CGST', 0 AS drAmount, Inw.GstAmt / 2.0 AS crAmount, CONCAT('TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmt > 0
			UNION ALL SELECT 'SGST', 0 AS drAmount, Inw.GstAmt / 2.0 AS crAmount, CONCAT('TO BILL NO. ', Inw.BILLNO),0 AS isBill,0 AS adjusted WHERE Inw.igstOnIntra = 'N' AND Inw.GstAmt > 0
		) X;

        IF @@ROWCOUNT = 0
            THROW 61006, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

CREATE VIEW [sales].[ViSale]
AS
SELECT sl.docId,[No], Dt, [mastcode].[ufGetIDate](Dt) dDt,sl.lcode, sl.LglNm AS lname,sl.Loc AS city,sl.StName AS stateName, sl.crCode, lc.lname crlname, sl.igstOnIntra, sl.Qty qty, sl.TotAmt AS Amount, sl.discount AS discountAmount, sl.AssAmt, sl.GstAmt AS GstAmount, 
CASE WHEN sl.igstOnIntra = 'Y' THEN sl.GstAmt ELSE 0 END igstAmount,
CASE WHEN sl.igstOnIntra = 'N' THEN sl.GstAmt / 2.0 ELSE 0 END cgstAmount, 
CASE WHEN sl.igstOnIntra = 'N' THEN sl.GstAmt / 2.0 ELSE 0 END sgstAmount,
sl.TotVal AS tamount, sl.adjAmount payAmount, sl.unadjusted bamount FROM [sales].[Sale] sl 
INNER JOIN [mastcode].[ViLedgerCodes] vlc ON sl.lcode = vlc.lcode
INNER JOIN [mastcode].[LedgerCodes] lc ON sl.lcode = lc.lcode
GO

CREATE PROCEDURE [sales].[uspGetSale]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @igstOnIntra VARCHAR(1) = JSON_VALUE(@json,'$.igstOnIntra'),		
		@lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode'),
		@fdate DATETIME = JSON_VALUE(@json,'$.fdate'),
		@tdate DATETIME = JSON_VALUE(@json,'$.tdate')

	SELECT docId, lcode, lname, city, stateName, [No], Dt,dDt,crCode, crlname, igstOnIntra, qty, amount, discountAmount, AssAmt, GstAmount, igstAmount, cgstAmount, sgstAmount, tamount, payAmount, bamount FROM [sales].[ViSale] 
	WHERE Dt >= @fdate AND Dt <= @tdate
	AND (@igstOnIntra IS NULL OR igstOnIntra = @igstOnIntra)
	AND (@lcode IS NULL OR lcode = @lcode)
	ORDER BY Dt;	
END;
GO

IF OBJECT_ID(N'fiac.SaleDbnote', N'U') IS NOT NULL
	DROP TABLE [fiac].[SaleDbnote];
GO

CREATE TABLE [fiac].[SaleDbnote]
(
	docId BIGINT IDENTITY(1,1) PRIMARY KEY,
	[No] VARCHAR(16) NOT NULL CONSTRAINT ck_fiac_saledbnote_no CHECK ([mastcode].[IsValidDocno](No) > 0),
	Dt DATE NOT NULL,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_saledbnote_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode), -- DROP DOWN PROC EXEC [mastcode].[uspGetLedgerCodesDropDown]
	
	drId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_saledbnote_drid CHECK ([mastcode].[IsValidDocReason](drId) > 0),
	daId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_saledbnote_daid CHECK ([mastcode].[IsValidDocAgainst](daId) > 0),
	crCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_saledbnote_crcode FOREIGN KEY (crCode) REFERENCES [mastcode].[LedgerCodes](lcode),

	
	-- Below is Auto Populated from lcode [NO INPUT REQUIRED]
	TaxSch VARCHAR(10) DEFAULT 'GST', -- Tax Scheme [NOT FOR INPUT]
	-- IF SupTyp is not B2B Then Export Details Required
	SupTyp VARCHAR(10) NOT NULL DEFAULT 'B2B' CHECK ([mastcode].[IsValidGstSupplyType](SupTyp)>0), -- DROP DOWN PROC [mastcode].[uspGetGstSupplyType] [NOT FOR INPUT]
	RegRev VARCHAR(1) NOT NULL DEFAULT 'N' CHECK (RegRev IN ('Y','N')), -- Reverse Charges	[NOT FOR INPUT]
	Typ VARCHAR(3) NOT NULL DEFAULT 'DBN', -- DROP DOWN PROC [mastcode].[uspGetDocType] [NOT FOR INPUT]

	-- Buyer Details 
	Gstin VARCHAR(15) NOT NULL CHECK ([mastcode].[IsValidGSTIN](Gstin)>0),
	LglNm VARCHAR(100) NOT NULL,
	Pos VARCHAR(2) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(100) NOT NULL,
	Stcd VARCHAR(2) NOT NULL,
	StName VARCHAR(50) NOT NULL,
	Pin BIGINT NOT NULL CHECK (Pin >= 100000 AND Pin <= 999999),
	Ph VARCHAR(12) NULL CHECK (Ph IS NULL OR [mastcode].[IsValidPhone](Ph) > 0),
	Em VARCHAR(100) NULL, -- Email
	-- Item Summary 
	Qty	DECIMAL (15,2) NOT NULL DEFAULT 0,
	TotAmt DECIMAL (15,2) NOT NULL  DEFAULT 0,
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,	-- Taxable Value (Total Amount -Discount)
	GstAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,
	TotVal	DECIMAL (15,2) NOT NULL DEFAULT 0,
	adjAmount DECIMAL (15,2) NOT NULL DEFAULT 0,
	unadjusted AS TotVal - adjAmount PERSISTED,
	CONSTRAINT uk_fiac_saledbnote_no UNIQUE ([No])
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.SaleDbnoteItemDetails', N'U') IS NOT NULL
	DROP TABLE [fiac].[SaleDbnoteItemDetails];
GO
					 
CREATE TABLE [fiac].[SaleDbnoteItemDetails]
(
	sidId BIGINT NOT NULL CONSTRAINT pk_fiac_saledbnoteitemdetails_sidid PRIMARY KEY IDENTITY(1,1),
	docId BIGINT NOT NULL CONSTRAINT fk_fiac_saledbnoteitemdetails_docid REFERENCES [fiac].[SaleDbnote](docId) ON DELETE CASCADE,

	--Type of Voucher Against Debit not Get prepared
	vtype VARCHAR(1) NULL,
	wdocno BIGINT NULL,
	
	-- Original Bill No and Date
	OrgInvNo VARCHAR(16) NULL,
	OrgInvDate DATE NULL,

	-- We can make of any reason so matno is null
	matno VARCHAR(15) NULL,	
	PrdDesc VARCHAR(300) NOT NULL, -- Product Description

	HsnCd VARCHAR(8) NOT NULL,
	IgstOnIntra VARCHAR(1) NOT NULL CHECK (IgstOnIntra IN ('Y','N')), -- IGST Yes or No Auto Populated [NOT FOR INPUT]
	Qty	DECIMAL (15,2) NOT NULL,
	UnitPrice DECIMAL (15,2) NOT NULL,
	Unit VARCHAR(8) NOT NULL CHECK ([mastcode].[IsValidUnit](Unit) > 0),
	TotAmt DECIMAL (15,2) NOT NULL, --	Gross Amount (Unit Price * Quantity)
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL,	-- Taxable Value (Total Amount -Discount)
	GstRt DECIMAL(6,2) NOT NULL,
	GstAmt  DECIMAL (15,2) NOT NULL,

	-- These are customisable field 
	CesRt   DECIMAL (6,2) NULL,
	CesAmt	DECIMAL (15,2) NULL,
	CesNonAdvlAmt DECIMAL (15,2) NULL,
	StateCesRt	DECIMAL (6,2) NULL,
	StateCesAmt	DECIMAL (15,2) NULL,
	StateCesNonAdvlAmt DECIMAL (15,2) NULL,
	
	TotItemVal	AS CAST(((TotAmt + GstAmt) - Discount)  AS DECIMAL(12,2)), -- CesAmt + CesNonAdvlAmt + StateCesAmt + StateCesNonAdvlAmt
	-- Free Qty Bundle
	FreeQty	DECIMAL (15,3) NOT NULL DEFAULT 0, -- Free Quantity
	FreeUnitPrice DECIMAL (15,3) NOT NULL DEFAULT 0,
	CONSTRAINT uk_fiac_saledbnoteitemdetails_no_matno UNIQUE (docId,matno),
	CONStraint ck_fiac_saledbnoteitemdetails_qty_unitprice CHECK (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_saledbnoteitemdetails_totamt CHECK(CEILING((TotAmt - Discount)) - AssAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_saledbnoteitemdetails_assamt CHECK(CEILING((TotAmt - Discount)) - CEILING(AssAmt) BETWEEN 0 AND 1),
	CONStraint ck_fiac_saledbnoteitemdetails_gstamt CHECK(CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
) ON [PRIMARY];
GO

IF OBJECT_ID('[fiac].[TrSaleDbnoteItemDetails]', 'TR') IS NOT NULL
    DROP TRIGGER [fiac].[TrSaleDbnoteItemDetails];
GO

CREATE TRIGGER [fiac].[TrSaleDbnoteItemDetails]
ON [fiac].[SaleDbnoteItemDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedDocs AS (
        SELECT docId FROM inserted
        UNION
        SELECT docId FROM deleted
    ),
    Agg AS (
        SELECT 
            d.docId,
            SUM(d.Qty)                                   AS TotalQty,
            SUM(d.TotAmt)                                AS TotalTotAmt,
            SUM(ISNULL(d.Discount,0))                    AS TotalDiscount,
            SUM(ISNULL(d.AssAmt,0))                      AS TotalAssAmt,
            SUM(ISNULL(d.GstAmt,0))                      AS TotalGstAmt,
            SUM(ISNULL(d.TotAmt,0) + ISNULL(d.GstAmt,0) - ISNULL(d.Discount,0)) AS TotalTotVal
        FROM [fiac].[SaleDbnoteItemDetails] d
        INNER JOIN ChangedDocs cd ON cd.docId = d.docId
        GROUP BY d.docId
    )
    UPDATE s
    SET
        Qty      = ISNULL(a.TotalQty, 0),
        TotAmt   = ISNULL(a.TotalTotAmt, 0),
        Discount = ISNULL(a.TotalDiscount, 0),
        AssAmt   = ISNULL(a.TotalAssAmt, 0),
        GstAmt   = ISNULL(a.TotalGstAmt, 0),
        TotVal   = ISNULL(a.TotalTotVal, 0)
    FROM [fiac].[SaleDbnote] s
    INNER JOIN ChangedDocs cd ON s.docId = cd.docId
    LEFT JOIN Agg a ON s.docId = a.docId;
END
GO

IF OBJECT_ID('fiac.uspGetSaleDbnotePostPending', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetSaleDbnotePostPending];
GO

CREATE PROCEDURE [fiac].[uspGetSaleDbnotePostPending]
AS
BEGIN
	SET NOCOUNT ON; 
	SELECT docId,[No],Dt,lcode,LglNm,Loc,StName,TotVal,adjAmount,unadjusted FROM [fiac].[SaleDbnote] WHERE unadjusted > 0
END
GO

IF OBJECT_ID('fiac.ViSaleDbnoteItemDetails', 'V') IS NOT NULL
    DROP VIEW [fiac].[ViSaleDbnoteItemDetails];
GO

CREATE VIEW [fiac].[ViSaleDbnoteItemDetails]
AS
SELECT docId,
	SUM(Qty) AS SumQty,
	SUM(TotAmt) AS SumTotAmt,
	SUM(Discount) AS SumDiscount,
	SUM(AssAmt) AS SumAssAmt,	
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'Y' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS IgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS CgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS SgstAmt,
	SUM(GstAmt) AS SumGstAmt,
	SUM((TotAmt + GstAmt) - Discount) AS SumTotVal
FROM [fiac].[SaleDbnoteItemDetails] GROUP BY docId
GO

IF OBJECT_ID(N'fiac.uspAddSaleDbnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspAddSaleDbnote];
GO

CREATE OR ALTER  PROCEDURE [fiac].[uspAddSaleDbnote]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;

        DECLARE @Header TABLE (
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			crCode VARCHAR(10),
			SaleDbnoteItemDetails NVARCHAR(MAX)
        );
		DECLARE @HeaderItem TABLE
		(
			[No] VARCHAR(16),
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			IgstOnIntra VARCHAR(1),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)	
		)

		;WITH input AS (
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,[No],Dt,lcode,drId,daId,crCode,SaleDbnoteItemDetails FROM OPENJSON(@json)
			WITH (	
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			crCode VARCHAR(10),
			SaleDbnoteItemDetails NVARCHAR(MAX) AS JSON)
			),
			NewDocNo AS (
				SELECT 
					ISNULL(DIN.docName+'/'+TRY_CAST(DIN.fiYear AS varchar)+'/' + HMax.maxDocno, DIN.docno) AS baseDocno
				FROM (
					SELECT 		 
					TRY_CAST(
					MAX(
					TRY_CAST(
					RIGHT(h.[No], 
					  CHARINDEX('/',REVERSE(h.[No])) - 1 )
					AS bigint)
					) AS varchar)
					 AS maxDocno FROM [fiac].[SaleDbnote] h
				) AS HMax
				CROSS APPLY (
					SELECT docName,initialNo,fiYear,docno FROM [mastcode].[DocInitialNo] WHERE docName = 'SDB'
				) AS DIN
			)

        INSERT INTO @Header (rn,[No], Dt, lcode, drId,daId,crCode,SaleDbnoteItemDetails)
		SELECT rn,ISNULL(Input.[No], [mastcode].[NewDocNo](NewDocNo.baseDocno, Input.rn)) [No], Dt, lcode, drId,daId,crCode,SaleDbnoteItemDetails FROM input
		CROSS JOIN NewDocNo

		INSERT INTO @HeaderItem ([No],vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT h.[No],
			d.vtype,
			d.wdocno,
			d.OrgInvNo,
			CONVERT(DATE, d.OrgInvDate, 105) AS OrgInvDate,
			d.matno,
			COALESCE(d.PrdDesc,mt.matDescription) AS PrdDesc,
			d.HsnCd,
			lc.igstOnIntra, 
			TRY_CAST(d.Qty AS DECIMAL(15,2)) AS Qty,
			TRY_CAST(d.UnitPrice AS DECIMAL(15,2)) AS UnitPrice,
			d.Unit,
			TRY_CAST(d.TotAmt AS DECIMAL(15,2)) AS TotAmt,
			TRY_CAST(d.Discount AS DECIMAL(15,2)) AS Discount,
			TRY_CAST(d.AssAmt AS DECIMAL(15,2)) AS AssAmt,			
			TRY_CAST(d.GstRt AS DECIMAL(6,2)) AS GstRt,
			TRY_CAST(d.GstAmt AS DECIMAL(15,2)) AS GstAmt
		FROM @Header h
		INNER JOIN [mastcode].[LedgerCodes] lc On h.lcode = lc.lcode
		CROSS APPLY OPENJSON(h.SaleDbnoteItemDetails,'$')
		WITH (
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			Qty	DECIMAL (15,2),
			UnitPrice DECIMAL (15,2),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,2),
			Discount DECIMAL (15,2),
			AssAmt  DECIMAL (15,2),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,2)
		) AS d		
		LEFT OUTER JOIN [purchase].[Material] mt ON d.matno = mt.matno;

        DECLARE @ValidationError NVARCHAR(MAX)

		-- DocNo Check Either Manual Or Auto
		IF (SELECT CASE WHEN COUNT([No]) = 0 THEN 1
				WHEN COUNT(*) = COUNT([No]) THEN 1
				ELSE 0
				END AS Result
				FROM @Header) <= 0		
			THROW 61002, 'Either All DocNo should be Null OR Not Null', 1;

		-- Validate foreign keys        
		SELECT @ValidationError = STRING_AGG(lcode,',')
		FROM (SELECT h.lcode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(crCode,',')
		FROM (SELECT h.crCode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.crCode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(drId,',')
		FROM (SELECT h.drId FROM @Header h
                WHERE [mastcode].[IsValidDocReason](drId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid drId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(daId,',')
		FROM (SELECT h.daId FROM @Header h
                WHERE [mastcode].[IsValidDocAgainst](daId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid daId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Item Details Validation Start
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
				LEFT JOIN purchase.Material m ON hi.matno = m.matno
                WHERE hi.matno IS NOT NULL AND m.matno IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Material No(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE PrdDesc IS NULL 
				OR HsnCd IS NULL 
				OR IgstOnIntra IS NULL
				OR Qty IS NULL
				OR UnitPrice IS NULL
				OR Unit IS NULL 
				OR TotAmt IS NULL
				OR AssAmt IS NULL 
				OR GstRt IS NULL
				OR GstAmt IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Line item Of Material No(s) have some null values '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Calculation Check
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE NOT (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1) 
				OR NOT ((CEILING(TotAmt) - Discount) - CEILING(AssAmt) BETWEEN 0 AND 1)
				OR NOT (CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
				)mic;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Calculation Error in Matno : '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

        BEGIN TRANSACTION;
        
		INSERT INTO [fiac].[SaleDbnote] ([No], Dt, lcode, drId, daId, crCode, SupTyp,Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em)  
		SELECT ha.[No],	ha.Dt, ha.lcode, ha.drId, ha.daId, ha.crCode, lc.SupTyp, lc.Gstin, lc.lname, lc.Stcd, lc.[add],lc.add1, lc.city Loc, lc.Stcd, lc.stateName, lc.zipCode, lc.phone,lc.email FROM @Header ha
		INNER JOIN [mastcode].[ViLedgerCodes] lc ON ha.lcode = lc.lcode

		INSERT INTO [fiac].[SaleDbnoteItemDetails] (docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, hi.IgstOnIntra, hi.Qty, UnitPrice, Unit, hi.TotAmt, hi.Discount, hi.AssAmt, GstRt, hi.GstAmt FROM @HeaderItem hi
		INNER JOIN [fiac].[SaleDbnote] sdb ON hi.[No] = sdb.[No]

        IF @@ROWCOUNT = 0
            THROW 61006, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspDeleteSaleDbnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspDeleteSaleDbnote];
GO

CREATE PROCEDURE [fiac].[uspDeleteSaleDbnote]  
(  
	@docno BIGINT,
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowAffected int = 0
		
		DELETE [fiac].[SaleDbnote] WHERE [No] = @docno;

		SET @rowaffected = @@ROWCOUNT;

		IF @rowAffected > 0
		BEGIN			
			COMMIT TRANSACTION;
			SET @STATUS = @rowAffected;
		END
		ELSE
		BEGIN
            ROLLBACK TRANSACTION;
			RAISERROR ('Check No. of parameters and data type', 16, 1);
        END
	END TRY  
    BEGIN CATCH  
		-- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
		BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
    END CATCH;  
END;
GO

IF OBJECT_ID('fiac.uspGetSaleDbnote', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetSaleDbnote];
GO

CREATE PROCEDURE [fiac].[uspGetSaleDbnote]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF ISJSON(TRIM(@json)) <> 1
		THROW 50000, 'Invalid JSON input.', 1;

	DECLARE @docId BIGINT = JSON_VALUE(@json,'$.docId'),
	@No VARCHAR(16) = JSON_VALUE(@json,'$.No'),
	@lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode'),
	@RegRev VARCHAR(1) = JSON_VALUE(@json,'$.RegRev'),
	@FDt DATE = JSON_VALUE(@json,'$.FDt'),
	@TDt DATE = JSON_VALUE(@json,'$.TDt');

	IF @docId IS NULL AND
	   @No IS NULL AND 
	   @lcode IS NULL AND 
	   @RegRev IS NULL AND 
	   @FDt IS NULL AND 
	   @TDt IS NULL
		THROW 50001, 'At least One Parameter Should be Available', 1;

	SELECT sdb.docId, sdb.No, sdb.Dt, [mastcode].[ufGetIDate](Dt) DDt, lcode, drId, daId, crCode, TaxSch, SupTyp, RegRev, Typ, 
		Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em, 
		sdbns.SumQty, sdbns.SumTotAmt, sdbns.SumDiscount, sdbns.SumAssAmt, sdbns.IgstAmt, sdbns.CgstAmt, sdbns.SgstAmt, sdbns.SumGstAmt, sdbns.SumTotVal, 
		adjAmount, unadjusted FROM [fiac].[SaleDbnote] sdb
	INNER JOIN [fiac].[ViSaleDbnoteItemDetails] sdbns ON sdb.docId = sdbns.docId
	WHERE ((@FDt IS NULL OR sdb.Dt >= @FDt) 
	AND (@TDt IS NULL OR sdb.Dt <= @TDt))
	AND (@docId IS NULL OR sdb.docId = @docId)
	AND (@No IS NULL OR sdb.[No] = @No)
	AND (@lcode IS NULL OR sdb.lcode = @lcode)
	AND (@RegRev IS NULL OR sdb.RegRev = @RegRev);
END;
GO

IF OBJECT_ID(N'fiac.SaleCrnote', N'U') IS NOT NULL
	DROP TABLE [fiac].[SaleCrnote];
GO

CREATE TABLE [fiac].[SaleCrnote]
(
	docId BIGINT IDENTITY(1,1) PRIMARY KEY,
	[No] VARCHAR(16) NOT NULL CONSTRAINT ck_fiac_salecrnote_no CHECK ([mastcode].[IsValidDocno](No) > 0),
	Dt DATE NOT NULL,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_salecrnote_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode), -- DROP DOWN PROC EXEC [mastcode].[uspGetLedgerCodesDropDown]
	
	drId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_salecrnote_drid CHECK ([mastcode].[IsValidDocReason](drId) > 0),
	daId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_salecrnote_daid CHECK ([mastcode].[IsValidDocAgainst](daId) > 0),
	dbCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_salecrnote_dbcode FOREIGN KEY (dbCode) REFERENCES [mastcode].[LedgerCodes](lcode),

	
	-- Below is Auto Populated from lcode [NO INPUT REQUIRED]
	TaxSch VARCHAR(10) DEFAULT 'GST', -- Tax Scheme [NOT FOR INPUT]
	-- IF SupTyp is not B2B Then Export Details Required
	SupTyp VARCHAR(10) NOT NULL DEFAULT 'B2B' CHECK ([mastcode].[IsValidGstSupplyType](SupTyp)>0), -- DROP DOWN PROC [mastcode].[uspGetGstSupplyType] [NOT FOR INPUT]
	RegRev VARCHAR(1) NOT NULL DEFAULT 'N' CHECK (RegRev IN ('Y','N')), -- Reverse Charges	[NOT FOR INPUT]
	Typ VARCHAR(3) NOT NULL DEFAULT 'CRN', -- DROP DOWN PROC [mastcode].[uspGetDocType] [NOT FOR INPUT]

	-- Buyer Details 
	Gstin VARCHAR(15) NOT NULL CHECK ([mastcode].[IsValidGSTIN](Gstin)>0),
	LglNm VARCHAR(100) NOT NULL,
	Pos VARCHAR(2) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(100) NOT NULL,
	Stcd VARCHAR(2) NOT NULL,
	StName VARCHAR(50) NOT NULL,
	Pin BIGINT NOT NULL CHECK (Pin >= 100000 AND Pin <= 999999),
	Ph VARCHAR(12) NULL CHECK (Ph IS NULL OR [mastcode].[IsValidPhone](Ph) > 0),
	Em VARCHAR(100) NULL, -- Email

	-- Item Summary 
	Qty	DECIMAL (15,2) NOT NULL DEFAULT 0,
	TotAmt DECIMAL (15,2) NOT NULL  DEFAULT 0,
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,	-- Taxable Value (Total Amount -Discount)
	GstAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,
	TotVal	DECIMAL (15,2) NOT NULL DEFAULT 0,
	adjAmount DECIMAL (15,2) NOT NULL DEFAULT 0,
	unadjusted AS TotVal - adjAmount PERSISTED,
	CONSTRAINT uk_fiac_salecrnote_no UNIQUE ([No])
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.SaleCrnoteItemDetails', N'U') IS NOT NULL
	DROP TABLE [fiac].[SaleCrnoteItemDetails];
GO

CREATE TABLE [fiac].[SaleCrnoteItemDetails]
(
	sidId BIGINT NOT NULL CONSTRAINT pk_fiac_salecrnoteitemdetails_sidid PRIMARY KEY IDENTITY(1,1),
	docId BIGINT NOT NULL CONSTRAINT fk_fiac_salecrnoteitemdetails_docid REFERENCES [fiac].[SaleCrnote](docId) ON DELETE CASCADE,

	--Type of Voucher Against Debit not Get prepared
	vtype VARCHAR(1) NULL,
	wdocno BIGINT NULL,
	
	-- Original Bill No and Date
	OrgInvNo VARCHAR(16) NULL,
	OrgInvDate DATE NULL,

	-- We can make of any reason so matno is null
	matno VARCHAR(15) NULL,	
	PrdDesc VARCHAR(300) NOT NULL, -- Product Description

	HsnCd VARCHAR(8) NOT NULL,
	IgstOnIntra VARCHAR(1) NOT NULL CHECK (IgstOnIntra IN ('Y','N')), -- IGST Yes or No Auto Populated [NOT FOR INPUT]
	Qty	DECIMAL (15,2) NOT NULL,	
	UnitPrice DECIMAL (15,2) NOT NULL,
	Unit VARCHAR(8) NOT NULL CHECK ([mastcode].[IsValidUnit](Unit) > 0),
	TotAmt DECIMAL (15,2) NOT NULL, --	Gross Amount (Unit Price * Quantity)
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL,	-- Taxable Value (Total Amount -Discount)
	GstRt DECIMAL(6,2) NOT NULL,
	GstAmt DECIMAL (15,2) NOT NULL,
	-- These are customisable field 
	CesRt   DECIMAL (6,2) NULL,	
	CesAmt	DECIMAL (15,2) NULL,
	CesNonAdvlAmt DECIMAL (15,2) NULL,
	StateCesRt	DECIMAL (6,2) NULL,
	StateCesAmt	DECIMAL (15,2) NULL,
	StateCesNonAdvlAmt DECIMAL (15,2) NULL,
	
	TotItemVal	AS CAST(((TotAmt + GstAmt) - Discount)  AS DECIMAL(12,2)), -- CesAmt + CesNonAdvlAmt + StateCesAmt + StateCesNonAdvlAmt
	-- Free Qty Bundle
	FreeQty	DECIMAL (15,2) NOT NULL DEFAULT 0, -- Free Quantity
	FreeUnitPrice DECIMAL (15,2) NOT NULL DEFAULT 0,
	CONSTRAINT uk_fiac_salecrnoteitemdetails_no_matno UNIQUE ([docId],matno),
	CONStraint ck_fiac_salecrnoteitemdetails_qty_unitprice CHECK (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_salecrnoteitemdetails_totamt CHECK(CEILING((TotAmt - Discount)) - AssAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_salecrnoteitemdetails_assamt CHECK(CEILING((TotAmt - Discount)) - CEILING(AssAmt) BETWEEN 0 AND 1),
	CONStraint ck_fiac_salecrnoteitemdetails_gstamt CHECK(CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.SaleCrnoteAdjustment', N'U') IS NOT NULL
	DROP TABLE [fiac].[SaleCrnoteAdjustment];
GO

CREATE TABLE [fiac].[SaleCrnoteAdjustment] 
(
    adjId BIGINT IDENTITY(1,1) PRIMARY KEY,
    docId BIGINT NOT NULL,
    transId BIGINT,
	vtype VARCHAR(1),
    adjAmount DECIMAL(18,2) NOT NULL,
    CONSTRAINT fk_fiac_salecrnoteadjustment_docId FOREIGN KEY (docId) REFERENCES [fiac].[SaleCrnote](docId) ON DELETE CASCADE
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.hisSaleDetails', N'U') IS NOT NULL
	DROP TABLE [fiac].[hisSaleDetails];
GO

CREATE TABLE [fiac].[hisSaleDetails]
(
	hsid BIGINT NOT NULL IDENTITY (1,1) CONSTRAINT pk_fiac_hissaledetails_hsid PRIMARY KEY (hsid),
	invNo BIGINT NOT NULL,
	docDate DATETIME NOT NULL,
	bpCode VARCHAR(10) NOT NULL,	
	matno VARCHAR(15) NOT NULL,
	qty DECIMAL(12,3) NOT NULL CHECK (QTY > 0),
	rate DECIMAL(12,2) NOT NULL,
	crnQty DECIMAL(12,3) NOT NULL DEFAULT 0,
	bqty AS qty - crnQty,
	CONSTRAINT pk_fiac_hissaledetails_invno_matno UNIQUE (invNo,matno),
	CONSTRAINT ck_fiac_hissaledetails_crnqty CHECK (qty >= crnQty)
) ON [PRIMARY];
GO

IF OBJECT_ID('[fiac].[TrSaleCrnoteItemDetails]', 'TR') IS NOT NULL
    DROP TRIGGER [fiac].[TrSaleCrnoteItemDetails];
GO

CREATE TRIGGER [fiac].[TrSaleCrnoteItemDetails]
ON [fiac].[SaleCrnoteItemDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedDocs AS (
        SELECT docId FROM inserted
        UNION
        SELECT docId FROM deleted
    ),
    Agg AS (
        SELECT 
            d.docId,
            SUM(d.Qty)                                   AS TotalQty,
            SUM(d.TotAmt)                                AS TotalTotAmt,
            SUM(ISNULL(d.Discount,0))                    AS TotalDiscount,
            SUM(ISNULL(d.AssAmt,0))                      AS TotalAssAmt,
            SUM(ISNULL(d.GstAmt,0))                      AS TotalGstAmt,
            SUM(ISNULL(d.TotAmt,0) + ISNULL(d.GstAmt,0) - ISNULL(d.Discount,0)) AS TotalTotVal
        FROM [fiac].[SaleCrnoteItemDetails] d
        INNER JOIN ChangedDocs cd ON cd.docId = d.docId
        GROUP BY d.docId
    )
    UPDATE s
    SET
        Qty      = ISNULL(a.TotalQty, 0),
        TotAmt   = ISNULL(a.TotalTotAmt, 0),
        Discount = ISNULL(a.TotalDiscount, 0),
        AssAmt   = ISNULL(a.TotalAssAmt, 0),
        GstAmt   = ISNULL(a.TotalGstAmt, 0),
        TotVal   = ISNULL(a.TotalTotVal, 0)
    FROM [fiac].[SaleCrnote] s
    INNER JOIN ChangedDocs cd ON s.docId = cd.docId
    LEFT JOIN Agg a ON s.docId = a.docId;
END
GO

IF OBJECT_ID(N'fiac.uspAddSaleCrnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspAddSaleCrnote];
GO

CREATE OR ALTER  PROCEDURE [fiac].[uspAddSaleCrnote]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;

        DECLARE @Header TABLE (
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			dbCode VARCHAR(10),
			SaleCrnoteItemDetails NVARCHAR(MAX)
        );
		DECLARE @HeaderItem TABLE
		(
			[No] VARCHAR(16),
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			IgstOnIntra VARCHAR(1),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)	
		)

		;WITH input AS (
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,[No],Dt,lcode,drId,daId,dbCode,SaleCrnoteItemDetails FROM OPENJSON(@json)
			WITH (	
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			dbCode VARCHAR(10),
			SaleCrnoteItemDetails NVARCHAR(MAX) AS JSON)
			),
			NewDocNo AS (
				SELECT 
					ISNULL(DIN.docName+'/'+TRY_CAST(DIN.fiYear AS varchar)+'/' + HMax.maxDocno, DIN.docno) AS baseDocno
				FROM (
					SELECT 		 
					TRY_CAST(
					MAX(
					TRY_CAST(
					RIGHT(h.[No], 
					  CHARINDEX('/',REVERSE(h.[No])) - 1 )
					AS bigint)
					) AS varchar)
					 AS maxDocno FROM [fiac].[SaleCrnote] h
				) AS HMax
				CROSS APPLY (
					SELECT docName,initialNo,fiYear,docno FROM [mastcode].[DocInitialNo] WHERE docName = 'CRN'
				) AS DIN
			)

        INSERT INTO @Header (rn,[No], Dt, lcode, drId,daId,dbCode,SaleCrnoteItemDetails)
		SELECT rn,ISNULL(Input.[No], [mastcode].[NewDocNo](NewDocNo.baseDocno, Input.rn)) [No], Dt, lcode, drId,daId,dbCode,SaleCrnoteItemDetails FROM input
		CROSS JOIN NewDocNo

		INSERT INTO @HeaderItem ([No],vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT h.[No],
			d.vtype,
			d.wdocno,
			d.OrgInvNo,
			CONVERT(DATE, d.OrgInvDate, 105) AS OrgInvDate,
			d.matno,
			COALESCE(d.PrdDesc,mt.matDescription) AS PrdDesc,
			d.HsnCd,
			lc.igstOnIntra, 
			TRY_CAST(d.Qty AS DECIMAL(15,2)) AS Qty,
			TRY_CAST(d.UnitPrice AS DECIMAL(15,2)) AS UnitPrice,
			d.Unit,
			TRY_CAST(d.TotAmt AS DECIMAL(15,2)) AS TotAmt,
			TRY_CAST(d.Discount AS DECIMAL(15,2)) AS Discount,
			TRY_CAST(d.AssAmt AS DECIMAL(15,2)) AS AssAmt,			
			TRY_CAST(d.GstRt AS DECIMAL(6,2)) AS GstRt,
			TRY_CAST(d.GstAmt AS DECIMAL(15,2)) AS GstAmt
		FROM @Header h
		INNER JOIN [mastcode].[LedgerCodes] lc On h.lcode = lc.lcode
		CROSS APPLY OPENJSON(h.SaleCrnoteItemDetails,'$')
		WITH (
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)
		) AS d		
		LEFT OUTER JOIN [purchase].[Material] mt ON d.matno = mt.matno;

        DECLARE @ValidationError NVARCHAR(MAX)

		-- DocNo Check Either Manual Or Auto
		IF (SELECT CASE WHEN COUNT([No]) = 0 THEN 1
				WHEN COUNT(*) = COUNT([No]) THEN 1
				ELSE 0
				END AS Result
				FROM @Header) <= 0		
			THROW 61002, 'Either All DocNo should be Null OR Not Null', 1;

		-- Validate foreign keys        
		SELECT @ValidationError = STRING_AGG(lcode,',')
		FROM (SELECT h.lcode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(dbCode,',')
		FROM (SELECT h.dbCode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.dbCode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(drId,',')
		FROM (SELECT h.drId FROM @Header h
                WHERE [mastcode].[IsValidDocReason](drId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid drId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(daId,',')
		FROM (SELECT h.daId FROM @Header h
                WHERE [mastcode].[IsValidDocAgainst](daId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid daId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Item Details Validation Start
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
				LEFT JOIN purchase.Material m ON hi.matno = m.matno
                WHERE hi.matno IS NOT NULL AND m.matno IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Material No(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE PrdDesc IS NULL 
				OR HsnCd IS NULL 
				OR IgstOnIntra IS NULL
				OR Qty IS NULL
				OR UnitPrice IS NULL
				OR Unit IS NULL 
				OR TotAmt IS NULL
				OR AssAmt IS NULL 
				OR GstRt IS NULL
				OR GstAmt IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Line item Of Material No(s) have some null values '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Calculation Check
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE NOT (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1) 
				OR NOT ((CEILING(TotAmt) - CEILING(Discount)) - CEILING(AssAmt) BETWEEN 0 AND 1)
				OR NOT (CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
				)mic;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Calculation Error in Matno : '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

        BEGIN TRANSACTION;
        
		INSERT INTO [fiac].[SaleCrnote] ([No], Dt, lcode, drId, daId, dbCode, SupTyp,Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em)  
		SELECT ha.[No],	ha.Dt, ha.lcode, ha.drId, ha.daId, ha.dbCode, lc.SupTyp, lc.Gstin, lc.lname, lc.Stcd, lc.[add],lc.add1, lc.city Loc, lc.Stcd, lc.stateName, lc.zipCode, lc.phone,lc.email FROM @Header ha
		INNER JOIN [mastcode].[ViLedgerCodes] lc ON ha.lcode = lc.lcode

		INSERT INTO [fiac].[SaleCrnoteItemDetails] (docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, hi.IgstOnIntra, hi.Qty, UnitPrice, Unit, hi.TotAmt, hi.Discount, hi.AssAmt, GstRt, hi.GstAmt FROM @HeaderItem hi
		INNER JOIN [fiac].[SaleCrnote] sdb ON hi.[No] = sdb.[No]

        IF @@ROWCOUNT = 0
            THROW 61006, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspDeleteSaleCrnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspDeleteSaleCrnote];
GO

CREATE PROCEDURE [fiac].[uspDeleteSaleCrnote]  
(  
	@docno BIGINT,
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowAffected int = 0
		
		DELETE [fiac].[SaleCrnote] WHERE [No] = @docno;

		SET @rowaffected = @@ROWCOUNT;

		IF @rowAffected > 0
		BEGIN			
			COMMIT TRANSACTION;
			SET @STATUS = @rowAffected;
		END
		ELSE
		BEGIN
            ROLLBACK TRANSACTION;
			RAISERROR ('Check No. of parameters and data type', 16, 1);
        END
	END TRY  
    BEGIN CATCH  
		-- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
		BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
    END CATCH;  
END;
GO

IF OBJECT_ID('fiac.uspGetSaleCrnotePostPending', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetSaleCrnotePostPending];
GO

CREATE PROCEDURE [fiac].[uspGetSaleCrnotePostPending]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT docId,[No],Dt,lcode,LglNm,Loc,StName,TotVal,adjAmount,unadjusted FROM [fiac].[SaleCrnote] WHERE unadjusted > 0
END
GO

IF OBJECT_ID('fiac.ViSaleCrnoteItemDetails', 'V') IS NOT NULL
    DROP VIEW [fiac].[ViSaleCrnoteItemDetails];
GO

CREATE VIEW [fiac].[ViSaleCrnoteItemDetails]
AS
SELECT docId,
	SUM(Qty) AS SumQty,
	SUM(TotAmt) AS SumTotAmt,
	SUM(Discount) AS SumDiscount,
	SUM(AssAmt) AS SumAssAmt,	
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'Y' THEN GstAmt ELSE 0 END) AS DECIMAL(15,2)) AS IgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS CgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS SgstAmt,
	SUM(GstAmt) AS SumGstAmt,
	SUM((TotAmt + GstAmt) - Discount) AS SumTotVal
FROM [fiac].[SaleCrnoteItemDetails] GROUP BY docId
GO

IF OBJECT_ID('fiac.uspGetSaleCrnote', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetSaleCrnote];
GO

CREATE PROCEDURE [fiac].[uspGetSaleCrnote]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF ISJSON(TRIM(@json)) <> 1
		THROW 50000, 'Invalid JSON input.', 1;

	DECLARE @docId BIGINT = JSON_VALUE(@json,'$.docId'),
	@No VARCHAR(16) = JSON_VALUE(@json,'$.No'),
	@lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode'),
	@RegRev VARCHAR(1) = JSON_VALUE(@json,'$.RegRev'),
	@FDt DATE = JSON_VALUE(@json,'$.FDt'),
	@TDt DATE = JSON_VALUE(@json,'$.TDt');

	IF @docId IS NULL AND
	   @No IS NULL AND 
	   @lcode IS NULL AND 
	   @RegRev IS NULL AND 
	   @FDt IS NULL AND 
	   @TDt IS NULL
		THROW 50001, 'At least One Parameter Should be Available', 1;

	SELECT sdb.docId, sdb.No, sdb.Dt, [mastcode].[ufGetIDate](Dt) dDt, lcode, drId, daId, dbCode, TaxSch, SupTyp, RegRev, Typ, 
		Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em, 
		sdbns.SumQty, sdbns.SumTotAmt,sdbns.SumDiscount,sdbns.SumAssAmt,sdbns.IgstAmt,sdbns.CgstAmt,sdbns.SgstAmt,sdbns.SumGstAmt,sdbns.SumTotVal, 
		adjAmount, unadjusted FROM [fiac].[SaleCrnote] sdb
	INNER JOIN [fiac].[ViSaleCrnoteItemDetails] sdbns ON sdb.docId = sdbns.docId
	WHERE ((@FDt IS NULL OR sdb.Dt >= @FDt) 
	AND (@TDt IS NULL OR sdb.Dt <= @TDt))
	AND (@docId IS NULL OR sdb.docId = @docId)
	AND (@No IS NULL OR sdb.[No] = @No)
	AND (@lcode IS NULL OR sdb.lcode = @lcode)
	AND (@RegRev IS NULL OR sdb.RegRev = @RegRev);
END;
GO

IF OBJECT_ID(N'fiac.SaleCrnotePost', N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[SaleCrnotePost];
GO

CREATE PROCEDURE [fiac].[SaleCrnotePost]
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PendingBills AS
    (
        SELECT 
            b.docId,
            b.vtype,
            b.lcode,
            b.Dt AS billDt,
            b.unadjusted AS billRemain,
            i.payId,
            i.unadjusted AS payAmount,
            i.Dt AS payDt,
            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId) AS rn,
            SUM(b.unadjusted) OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal
        FROM (SELECT docId payId, Dt, lcode, unadjusted FROM [fiac].[SaleCrnotePostPending]) i
        JOIN [fiac].[PaymentPending] b 
            ON b.lcode = i.lcode
        WHERE b.unadjusted > 0
    ),
    Allocation AS
    (
        SELECT 
            pb.payId,
            pb.docId,
            pb.vtype,
            CASE 
                WHEN pb.payAmount >= pb.RunningBillTotal 
                     THEN pb.billRemain                            -- full bill gets cleared
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.billRemain 
                     THEN 0                                        -- nothing allocated
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.billRemain) -- partial allocation
            END AS AllocatedAmount
        FROM PendingBills pb
    )
    INSERT INTO [fiac].[SaleCrnoteAdjustment] (docId, transId, vtype, adjAmount)
    SELECT payId, docId, vtype, AllocatedAmount
    FROM Allocation
    WHERE AllocatedAmount > 0;
END;
GO

IF OBJECT_ID(N'fiac.TrSaleCrnoteAdjustment', N'TR') IS NOT NULL
	DROP TRIGGER [fiac].[TrSaleCrnoteAdjustment];
GO

CREATE OR ALTER TRIGGER [fiac].[TrSaleCrnoteAdjustment]
ON [fiac].[SaleCrnoteAdjustment]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Sale
        UPDATE s
        SET s.adjAmount = s.adjAmount - d.totalAdj
        FROM [sales].[Sale] s
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            WHERE vtype = 'I'
            GROUP BY transId
        ) d ON s.docId = d.transId;

        UPDATE dnote
        SET dnote.adjAmount = dnote.adjAmount - d.totalAdj
        FROM [fiac].[SaleDbnote] dnote
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            WHERE vtype = 'D'
            GROUP BY transId
        ) d ON dnote.docId = d.transId;

        UPDATE pi
        SET pi.adjAmount = pi.adjAmount - d.totalAdj
        FROM [fiac].[SaleCrnote] pi
        INNER JOIN (
            SELECT docId, SUM(adjAmount) AS totalAdj
            FROM deleted
            GROUP BY docId
        ) d ON pi.docId = d.docId;
    END;

    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- Sale
        UPDATE s
        SET s.adjAmount = s.adjAmount + i.totalAdj
        FROM [sales].[Sale] s
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            WHERE vtype = 'I'
            GROUP BY transId
        ) i ON s.docId = i.transId;

        UPDATE dnote
        SET dnote.adjAmount = dnote.adjAmount + i.totalAdj
        FROM [fiac].[SaleDbnote] dnote
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            WHERE vtype = 'D'
            GROUP BY transId
        ) i ON dnote.docId = i.transId;

        UPDATE pi
        SET pi.adjAmount = pi.adjAmount + i.totalAdj
        FROM [fiac].[SaleCrnote] pi
        INNER JOIN (
            SELECT docId, SUM(adjAmount) AS totalAdj
            FROM inserted
            GROUP BY docId
        ) i ON pi.docId = i.docId;
    END;
END;
GO

IF OBJECT_ID(N'fiac.Dbnote', N'U') IS NOT NULL
	DROP TABLE [fiac].[Dbnote];
GO

CREATE TABLE [fiac].[Dbnote]
(
	docId BIGINT IDENTITY(1,1) PRIMARY KEY,
	[No] VARCHAR(16) NOT NULL CHECK ([No] IS NULL OR [mastcode].[IsValidDocno](No) > 0),
	Dt DATE NOT NULL,
	lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_dbnote_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode), -- DROP DOWN PROC EXEC [mastcode].[uspGetLedgerCodesDropDown]
	
	drId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_dbnote_drid CHECK ([mastcode].[IsValidDocReason](drId) > 0),
	daId VARCHAR(2) NOT NULL CONSTRAINT ck_fiac_dbnote_daid CHECK ([mastcode].[IsValidDocAgainst](daId) > 0),
	crCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_dbnote_crcode FOREIGN KEY (crCode) REFERENCES [mastcode].[LedgerCodes](lcode),

	
	-- Below is Auto Populated from lcode [NO INPUT REQUIRED]
	TaxSch VARCHAR(10) DEFAULT 'GST', -- Tax Scheme [NOT FOR INPUT]
	-- IF SupTyp is not B2B Then Export Details Required
	SupTyp VARCHAR(10) NOT NULL DEFAULT 'B2B' CHECK ([mastcode].[IsValidGstSupplyType](SupTyp)>0), -- DROP DOWN PROC [mastcode].[uspGetGstSupplyType] [NOT FOR INPUT]
	RegRev VARCHAR(1) NOT NULL DEFAULT 'N' CHECK (RegRev IN ('Y','N')), -- Reverse Charges	[NOT FOR INPUT]
	Typ VARCHAR(3) NOT NULL DEFAULT 'DBN', -- DROP DOWN PROC [mastcode].[uspGetDocType] [NOT FOR INPUT]

	-- Buyer Details 
	Gstin VARCHAR(15) NOT NULL CHECK ([mastcode].[IsValidGSTIN](Gstin)>0),
	LglNm VARCHAR(100) NOT NULL,
	Pos VARCHAR(2) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(100) NOT NULL,
	Stcd VARCHAR(2) NOT NULL,
	StName VARCHAR(50) NOT NULL,
	Pin BIGINT NOT NULL CHECK (Pin >= 100000 AND Pin <= 999999),
	Ph VARCHAR(12) NULL CHECK (Ph IS NULL OR [mastcode].[IsValidPhone](Ph) > 0),
	Em VARCHAR(10) NULL, -- Email

	-- Item Summary 
	Qty	DECIMAL (15,2) NOT NULL DEFAULT 0,
	TotAmt DECIMAL (15,2) NOT NULL  DEFAULT 0,
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,	-- Taxable Value (Total Amount -Discount)
	GstAmt  DECIMAL (15,2) NOT NULL  DEFAULT 0,
	TotVal	DECIMAL (15,2) NOT NULL DEFAULT 0,
	adjAmount DECIMAL (15,2) NOT NULL DEFAULT 0,
	unadjusted AS TotVal - adjAmount PERSISTED,
	CONSTRAINT uk_fiac_dbnote_no UNIQUE ([No])
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.DbnoteItemDetails', N'U') IS NOT NULL
	DROP TABLE [fiac].[DbnoteItemDetails];
GO

CREATE TABLE [fiac].[DbnoteItemDetails]
(
	sidId BIGINT NOT NULL CONSTRAINT pk_fiac_dbnoteitemdetails_sidid PRIMARY KEY IDENTITY(1,1),
	docId BIGINT NOT NULL CONSTRAINT fk_fiac_dbnoteitemdetails_docid REFERENCES [fiac].[Dbnote](docId) ON DELETE CASCADE,

	--Type of Voucher Against Debit not Get prepared
	vtype VARCHAR(1) NULL,
	wdocno BIGINT NULL,
	
	-- Original Bill No and Date
	OrgInvNo VARCHAR(16) NULL,
	OrgInvDate DATE NULL,

	-- We can make of any reason so matno is null
	matno VARCHAR(15) NULL,	
	PrdDesc VARCHAR(300) NOT NULL, -- Product Description

	HsnCd VARCHAR(8) NOT NULL,
	IgstOnIntra VARCHAR(1) NOT NULL CHECK (IgstOnIntra IN ('Y','N')), -- IGST Yes or No Auto Populated [NOT FOR INPUT]
	Qty	DECIMAL (15,2) NOT NULL,
	UnitPrice DECIMAL (15,2) NOT NULL,
	Unit VARCHAR(8) NOT NULL CHECK ([mastcode].[IsValidUnit](Unit) > 0),
	TotAmt DECIMAL (15,2) NOT NULL, --	Gross Amount (Unit Price * Quantity)
	Discount DECIMAL (15,2) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,2) NOT NULL,	-- Taxable Value (Total Amount -Discount)
	GstRt DECIMAL(6,2) NOT NULL,
	GstAmt  DECIMAL (15,2) NOT NULL,
	-- These are customisable field 
	CesRt   DECIMAL (6,2) NULL,
	CesAmt	DECIMAL (15,2) NULL,
	CesNonAdvlAmt DECIMAL (15,2) NULL,
	StateCesRt	DECIMAL (6,2) NULL,
	StateCesAmt	DECIMAL (15,2) NULL,
	StateCesNonAdvlAmt DECIMAL (15,2) NULL,
	
	TotItemVal	AS CAST(((TotAmt + GstAmt) - Discount) AS DECIMAL(12,2)), -- CesAmt + CesNonAdvlAmt + StateCesAmt + StateCesNonAdvlAmt
	-- Free Qty Bundle
	FreeQty	DECIMAL (15,2) NOT NULL DEFAULT 0, -- Free Quantity
	FreeUnitPrice DECIMAL (15,2) NOT NULL DEFAULT 0,
	CONSTRAINT uk_fiac_dbnoteitemdetails_no_matno UNIQUE (docId,matno),	
	CONStraint ck_fiac_dbnoteitemdetails_qty_unitprice CHECK (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_dbnoteitemdetails_totamt CHECK(CEILING((TotAmt - Discount)) - AssAmt BETWEEN 0 AND 1),
	CONStraint ck_fiac_dbnoteitemdetails_assamt CHECK(CEILING((TotAmt - Discount)) - CEILING(AssAmt) BETWEEN 0 AND 1),
	CONStraint ck_fiac_dbnoteitemdetails_gstamt CHECK(CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.DbnoteAdjustment', N'U') IS NOT NULL
	DROP TABLE [fiac].[DbnoteAdjustment];
GO

CREATE TABLE [fiac].[DbnoteAdjustment] 
(
    adjId BIGINT IDENTITY(1,1) PRIMARY KEY,
    docId BIGINT NOT NULL,
    transId BIGINT,
	vtype VARCHAR(1),
    adjAmount DECIMAL(18,2) NOT NULL,
    CONSTRAINT fk_fiac_DbnoteAdjustment_docId FOREIGN KEY (docId) REFERENCES [fiac].[Dbnote](docId) ON DELETE CASCADE
) ON [PRIMARY];
GO

IF OBJECT_ID('[fiac].[TrDbnoteItemDetails]', 'TR') IS NOT NULL
    DROP TRIGGER [fiac].[TrDbnoteItemDetails];
GO

CREATE TRIGGER [fiac].[TrDbnoteItemDetails]
ON [fiac].[DbnoteItemDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH ChangedDocs AS (
        SELECT docId FROM inserted
        UNION
        SELECT docId FROM deleted
    ),
    Agg AS (
        SELECT 
            d.docId,
            SUM(d.Qty)                                   AS TotalQty,
            SUM(d.TotAmt)                                AS TotalTotAmt,
            SUM(ISNULL(d.Discount,0))                    AS TotalDiscount,
            SUM(ISNULL(d.AssAmt,0))                      AS TotalAssAmt,
            SUM(ISNULL(d.GstAmt,0))                      AS TotalGstAmt,
            SUM(ISNULL(d.TotAmt,0) + ISNULL(d.GstAmt,0) - ISNULL(d.Discount,0)) AS TotalTotVal
        FROM [fiac].[DbnoteItemDetails] d
        INNER JOIN ChangedDocs cd ON cd.docId = d.docId
        GROUP BY d.docId
    )
    UPDATE s
    SET
        Qty      = ISNULL(a.TotalQty, 0),
        TotAmt   = ISNULL(a.TotalTotAmt, 0),
        Discount = ISNULL(a.TotalDiscount, 0),
        AssAmt   = ISNULL(a.TotalAssAmt, 0),
        GstAmt   = ISNULL(a.TotalGstAmt, 0),
        TotVal   = ISNULL(a.TotalTotVal, 0)
    FROM [fiac].[Dbnote] s
    INNER JOIN ChangedDocs cd ON s.docId = cd.docId
    LEFT JOIN Agg a ON s.docId = a.docId;
END
GO

IF OBJECT_ID(N'fiac.uspAddDbnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspAddDbnote];
GO

CREATE PROCEDURE [fiac].[uspAddDbnote]
    @json NVARCHAR(MAX),
    @STATUS smallint = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF ISJSON(@json) <> 1
            THROW 61001, 'Invalid JSON input.', 1;

        DECLARE @Header TABLE (
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			crCode VARCHAR(10),
			DbnoteItemDetails NVARCHAR(MAX)
        );
		DECLARE @HeaderItem TABLE
		(
			[No] VARCHAR(16),
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			IgstOnIntra VARCHAR(1),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)	
		)

		;WITH input AS (
			SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn,[No],Dt,lcode,drId,daId,crCode,DbnoteItemDetails FROM OPENJSON(@json)
			WITH (	
			rn BIGINT,
			[No] VARCHAR(16),
			Dt DATE,
			lcode VARCHAR(10),
			drId VARCHAR(2),
			daId VARCHAR(2),
			crCode VARCHAR(10),
			DbnoteItemDetails NVARCHAR(MAX) AS JSON)
			),
			NewDocNo AS (
				SELECT 
					ISNULL(DIN.docName+'/'+TRY_CAST(DIN.fiYear AS varchar)+'/' + HMax.maxDocno, DIN.docno) AS baseDocno
				FROM (
					SELECT 		 
					TRY_CAST(
					MAX(
					TRY_CAST(
					RIGHT(h.[No], 
					  CHARINDEX('/',REVERSE(h.[No])) - 1 )
					AS bigint)
					) AS varchar)
					 AS maxDocno FROM [fiac].[Dbnote] h
				) AS HMax
				CROSS APPLY (
					SELECT docName,initialNo,fiYear,docno FROM [mastcode].[DocInitialNo] WHERE docName = 'DBN'
				) AS DIN
			)

        INSERT INTO @Header (rn,[No], Dt, lcode, drId,daId,crCode,DbnoteItemDetails)
		SELECT rn,ISNULL(Input.[No], [mastcode].[NewDocNo](NewDocNo.baseDocno, Input.rn)) [No], Dt, lcode, drId,daId,crCode,DbnoteItemDetails FROM input
		CROSS JOIN NewDocNo

		INSERT INTO @HeaderItem ([No],vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT h.[No],
			d.vtype,
			d.wdocno,
			d.OrgInvNo,
			CONVERT(DATE, d.OrgInvDate, 105) AS OrgInvDate,
			d.matno,
			COALESCE(d.PrdDesc,mt.matDescription) AS PrdDesc,
			d.HsnCd,
			lc.igstOnIntra, 
			TRY_CAST(d.Qty AS DECIMAL(15,2)) AS Qty,
			TRY_CAST(d.UnitPrice AS DECIMAL(15,2)) AS UnitPrice,
			d.Unit,
			TRY_CAST(d.TotAmt AS DECIMAL(15,2)) AS TotAmt,
			TRY_CAST(d.Discount AS DECIMAL(15,2)) AS Discount,
			TRY_CAST(d.AssAmt AS DECIMAL(15,2)) AS AssAmt,			
			TRY_CAST(d.GstRt AS DECIMAL(6,2)) AS GstRt,
			TRY_CAST(d.GstAmt AS DECIMAL(15,2)) AS GstAmt
		FROM @Header h
		INNER JOIN [mastcode].[LedgerCodes] lc On h.lcode = lc.lcode
		CROSS APPLY OPENJSON(h.DbnoteItemDetails,'$')
		WITH (
			vtype VARCHAR(1),
			wdocno BIGINT,	
			OrgInvNo VARCHAR(16),
			OrgInvDate DATE,
			matno VARCHAR(15),	
			PrdDesc VARCHAR(300),
			HsnCd VARCHAR(8),
			Qty	DECIMAL (15,3),
			UnitPrice DECIMAL (15,3),
			Unit VARCHAR(8),
			TotAmt DECIMAL (15,3),
			Discount DECIMAL (15,3),
			AssAmt  DECIMAL (15,3),
			GstRt DECIMAL(6,2),
			GstAmt  DECIMAL (15,3)
		) AS d		
		LEFT OUTER JOIN [purchase].[Material] mt ON d.matno = mt.matno;

        DECLARE @ValidationError NVARCHAR(MAX)

		-- DocNo Check Either Manual Or Auto
		IF (SELECT CASE WHEN COUNT([No]) = 0 THEN 1
				WHEN COUNT(*) = COUNT([No]) THEN 1
				ELSE 0
				END AS Result
				FROM @Header) <= 0		
			THROW 61002, 'Either All DocNo should be Null OR Not Null', 1;

		-- Validate foreign keys        
		SELECT @ValidationError = STRING_AGG(lcode,',')
		FROM (SELECT h.lcode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.lcode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(crCode,',')
		FROM (SELECT h.crCode FROM @Header h
				LEFT JOIN mastcode.LedgerCodes l ON h.crCode = l.lcode
                WHERE l.lcode IS NULL)fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Ledger Code(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(drId,',')
		FROM (SELECT h.drId FROM @Header h
                WHERE [mastcode].[IsValidDocReason](drId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid drId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(daId,',')
		FROM (SELECT h.daId FROM @Header h
                WHERE [mastcode].[IsValidDocAgainst](daId) <= 0 )fk;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid daId '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Item Details Validation Start
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
				LEFT JOIN purchase.Material m ON hi.matno = m.matno
                WHERE hi.matno IS NOT NULL AND m.matno IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Invalid Material No(s) '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE PrdDesc IS NULL 
				OR HsnCd IS NULL 
				OR IgstOnIntra IS NULL
				OR Qty IS NULL
				OR UnitPrice IS NULL
				OR Unit IS NULL 
				OR TotAmt IS NULL
				OR AssAmt IS NULL 
				OR GstRt IS NULL
				OR GstAmt IS NULL)mi;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Line item Of Material No(s) have some null values '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END
		
		-- Calculation Check
		SET @ValidationError = NULL;
        SELECT @ValidationError = STRING_AGG(matno,',')
		FROM (SELECT hi.matno FROM @HeaderItem hi
                WHERE NOT (CEILING((Qty * UnitPrice)) - TotAmt BETWEEN 0 AND 1) 
				OR NOT ((CEILING(TotAmt) - Discount) - CEILING(AssAmt) BETWEEN 0 AND 1)
				OR NOT (CEILING((((Qty * UnitPrice) - Discount) * GstRt * .01)) - GstAmt BETWEEN 0 AND 1)
				)mic;
        IF @ValidationError IS NOT NULL
		BEGIN
			SET @ValidationError = 'Calculation Error in Matno : '+ @ValidationError;
			THROW 61002, @ValidationError, 1;
		END

        BEGIN TRANSACTION;
        
		INSERT INTO [fiac].[Dbnote] ([No], Dt, lcode, drId, daId, crCode, SupTyp,Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em)  
		SELECT ha.[No],	ha.Dt, ha.lcode, ha.drId, ha.daId, ha.crCode, lc.SupTyp, lc.Gstin, lc.lname, lc.Stcd, lc.[add],lc.add1, lc.city Loc, lc.Stcd, lc.stateName, lc.zipCode, lc.phone,lc.email FROM @Header ha
		INNER JOIN [mastcode].[ViLedgerCodes] lc ON ha.lcode = lc.lcode

		INSERT INTO [fiac].[DbnoteItemDetails] (docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, IgstOnIntra, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)
		SELECT docId, vtype, wdocno, OrgInvNo, OrgInvDate, matno, PrdDesc, HsnCd, hi.IgstOnIntra, hi.Qty, UnitPrice, Unit, hi.TotAmt, hi.Discount, hi.AssAmt, GstRt, hi.GstAmt FROM @HeaderItem hi
		INNER JOIN [fiac].[Dbnote] sdb ON hi.[No] = sdb.[No]

        IF @@ROWCOUNT = 0
            THROW 61006, 'Insert failed: no rows affected.', 1;

        COMMIT TRANSACTION;
        SET @STATUS = 1;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRAN;
        EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;
        THROW;
    END CATCH
END;
GO

IF OBJECT_ID(N'fiac.uspDeleteDbnote',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspDeleteDbnote];
GO

CREATE PROCEDURE [fiac].[uspDeleteDbnote]  
(  
	@docno BIGINT,
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowAffected int = 0
		
		DELETE [fiac].[Dbnote] WHERE [No] = @docno;

		SET @rowaffected = @@ROWCOUNT;

		IF @rowAffected > 0
		BEGIN			
			COMMIT TRANSACTION;
			SET @STATUS = @rowAffected;
		END
		ELSE
		BEGIN
            ROLLBACK TRANSACTION;
			RAISERROR ('Check No. of parameters and data type', 16, 1);
        END
	END TRY  
    BEGIN CATCH  
		-- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
		BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
    END CATCH;  
END;
GO

IF OBJECT_ID('fiac.uspGetDbnotePostPending', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetDbnotePostPending];
GO

CREATE PROCEDURE [fiac].[uspGetDbnotePostPending]
AS
BEGIN
	SET NOCOUNT ON;
	SELECT docId,[No],Dt,lcode,LglNm,Loc,StName,TotVal,adjAmount,unadjusted FROM [fiac].[Dbnote] WHERE unadjusted > 0;
END

GO

IF OBJECT_ID('fiac.ViDbnoteItemDetails', 'V') IS NOT NULL
    DROP VIEW [fiac].[ViDbnoteItemDetails];
GO

CREATE VIEW [fiac].[ViDbnoteItemDetails]
AS
SELECT docId,
	SUM(Qty) AS SumQty,
	SUM(TotAmt) AS SumTotAmt,
	SUM(Discount) AS SumDiscount,
	SUM(AssAmt) AS SumAssAmt,	
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'Y' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS IgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS CgstAmt,
	TRY_CAST(SUM(CASE WHEN IgstOnIntra = 'N' THEN GstAmt / 2.0 ELSE 0 END) AS DECIMAL(15,2)) AS SgstAmt,
	SUM(GstAmt) AS SumGstAmt,
	SUM((TotAmt + GstAmt) - Discount) AS SumTotVal
FROM [fiac].[DbnoteItemDetails] GROUP BY docId
GO

IF OBJECT_ID('fiac.uspGetDbnote', 'P') IS NOT NULL
    DROP PROCEDURE [fiac].[uspGetDbnote];
GO

CREATE PROCEDURE [fiac].[uspGetDbnote]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF ISJSON(TRIM(@json)) <> 1
		THROW 50000, 'Invalid JSON input.', 1;

	DECLARE @docId BIGINT = JSON_VALUE(@json,'$.docId'),
	@No VARCHAR(16) = JSON_VALUE(@json,'$.No'),
	@lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode'),
	@RegRev VARCHAR(1) = JSON_VALUE(@json,'$.RegRev'),
	@FDt DATE = JSON_VALUE(@json,'$.FDt'),
	@TDt DATE = JSON_VALUE(@json,'$.TDt');

	IF @docId IS NULL AND
	   @No IS NULL AND 
	   @lcode IS NULL AND 
	   @RegRev IS NULL AND 
	   @FDt IS NULL AND 
	   @TDt IS NULL
		THROW 50001, 'At least One Parameter Should be Available', 1;

	SELECT sdb.docId, sdb.No, sdb.Dt, [mastcode].[ufGetIDate](Dt) DDt, lcode, drId, daId, crCode, TaxSch, SupTyp, RegRev, Typ, 
		Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, StName, Pin, Ph, Em, 
		sdbns.SumQty, sdbns.SumTotAmt, sdbns.SumDiscount, sdbns.SumAssAmt, sdbns.IgstAmt, sdbns.CgstAmt, sdbns.SgstAmt, sdbns.SumGstAmt, sdbns.SumTotVal, 
		adjAmount, unadjusted FROM [fiac].[Dbnote] sdb
	INNER JOIN [fiac].[ViDbnoteItemDetails] sdbns ON sdb.docId = sdbns.docId
	WHERE ((@FDt IS NULL OR sdb.Dt >= @FDt) 
	AND (@TDt IS NULL OR sdb.Dt <= @TDt))
	AND (@docId IS NULL OR sdb.docId = @docId)
	AND (@No IS NULL OR sdb.[No] = @No)
	AND (@lcode IS NULL OR sdb.lcode = @lcode)
	AND (@RegRev IS NULL OR sdb.RegRev = @RegRev);
END;
GO

IF OBJECT_ID(N'fiac.DbnotePost', N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[DbnotePost];
GO

CREATE PROCEDURE [fiac].[DbnotePost]
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH PendingBills AS
    (
        SELECT 
            b.docId,
            b.vtype,
            b.lcode,
            b.Dt AS billDt,
            b.unadjusted AS billRemain,
            i.payId,
            i.unadjusted AS payAmount,
            i.Dt AS payDt,
            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId) AS rn,
            SUM(b.unadjusted) OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal
        FROM (SELECT docId payId, Dt, lcode, unadjusted FROM [fiac].[DbnotePostPending]) i
        JOIN [fiac].[PaymentPending] b 
            ON b.lcode = i.lcode
        WHERE b.unadjusted > 0
    ),
    Allocation AS
    (
        SELECT 
            pb.payId,
            pb.docId,
            pb.vtype,
            CASE 
                WHEN pb.payAmount >= pb.RunningBillTotal 
                     THEN pb.billRemain                            -- full bill gets cleared
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.billRemain 
                     THEN 0                                        -- nothing allocated
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.billRemain) -- partial allocation
            END AS AllocatedAmount
        FROM PendingBills pb
    )
    INSERT INTO [fiac].[DbnoteAdjustment] (docId, transId, vtype, adjAmount)
    SELECT payId, docId, vtype, AllocatedAmount
    FROM Allocation
    WHERE AllocatedAmount > 0;
END;
GO

IF OBJECT_ID(N'fiac.TrDbnoteAdjustment', N'TR') IS NOT NULL
	DROP TRIGGER [fiac].[TrDbnoteAdjustment];
GO

CREATE OR ALTER TRIGGER [fiac].[TrDbnoteAdjustment]
ON [fiac].[DbnoteAdjustment]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        UPDATE inw
        SET inw.payAmount = inw.payAmount - d.totalAdj
        FROM [fiac].[Inward] inw
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            WHERE vtype = 'I'
            GROUP BY transId
        ) d ON inw.transId = d.transId;

        UPDATE inv
        SET inv.payAmount = inv.payAmount - d.totalAdj
        FROM [fiac].[InwardVoucher] inv
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            WHERE vtype = 'V'
            GROUP BY transId
        ) d ON inv.transId = d.transId;

        UPDATE pi
        SET pi.adjAmount = pi.adjAmount - d.totalAdj
        FROM [fiac].[Dbnote] pi
        INNER JOIN (
            SELECT docId, SUM(adjAmount) AS totalAdj
            FROM deleted
            GROUP BY docId
        ) d ON pi.docId = d.docId;
    END;

    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- Sale
        UPDATE inw
        SET inw.payAmount = inw.payAmount + i.totalAdj
        FROM [fiac].[Inward] inw
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            WHERE vtype = 'I'
            GROUP BY transId
        ) i ON inw.transId = i.transId;

        UPDATE inv
        SET inv.payAmount = inv.payAmount + i.totalAdj
        FROM [fiac].[InwardVoucher] inv
        INNER JOIN (
            SELECT transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            WHERE vtype = 'V'
            GROUP BY transId
        ) i ON inv.transId = i.transId;

        UPDATE pi
        SET pi.adjAmount = pi.adjAmount + i.totalAdj
        FROM [fiac].[Dbnote] pi
        INNER JOIN (
            SELECT docId, SUM(adjAmount) AS totalAdj
            FROM inserted
            GROUP BY docId
        ) i ON pi.docId = i.docId;
    END;
END;
GO




-- Below is Sample code Not to execute


IF OBJECT_ID(N'fiac.hisPurchaseDetails', N'U') IS NOT NULL
	DROP TABLE [fiac].[hisPurchaseDetails];
GO

CREATE TABLE [fiac].[hisPurchaseDetails]
(
	id BIGINT NOT NULL CONSTRAINT pk_fiac_hispurchasedetails_id PRIMARY KEY (id) IDENTITY(1,1),
	grno BIGINT NOT NULL,
	bpCode VARCHAR(10) NOT NULL,
	billNo VARCHAR(20) NOT NULL,
	billDate DATETIME NOT NULL,
	matno VARCHAR(15) NOT NULL,
	hsnCode VARCHAR(10) NOT NULL,
	rgst DECIMAL(5,2) NOT NULL,
	qty DECIMAL(12,3) NOT NULL,
	prate DECIMAL(12,3) NOT NULL,
	dbnQty DECIMAL(12,3) NOT NULL,
	bqty AS qty - dbnqty,
	CONSTRAINT ck_fiac_hispurchasedetails_bqty CHECK (qty >= dbnqty)
) ON [PRIMARY];
GO

IF OBJECT_ID(N'fiac.uspGetHisPurchaseDetails', N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspGetHisPurchaseDetails];
GO

CREATE PROCEDURE [fiac].[uspGetHisPurchaseDetails]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;

	IF ISJSON(@json) != 1
		THROW 50001,'Invalid JSON ',1;
		
	DECLARE @bpCode VARCHAR(10) = JSON_VALUE(@json,'$.bpCode'),
		@matno VARCHAR(15) = JSON_VALUE(@json,'$.matno'),
		@repType VARCHAR(1) = JSON_VALUE(@json,'$.repType');

	SELECT id, grno, hpd.bpCode, lc.lname, lc.city, lc.stateName, billNo, billDate, matno, hsnCode, rgst, qty, prate, dbnQty, bqty FROM [fiac].[hisPurchaseDetails] hpd
		INNER JOIN [mastcode].[ViLedgerCodes] lc ON hpd.bpCode = lc.lcode
	WHERE (@bpCode IS NULL OR hpd.bpCode = @bpCode)
	AND (@matno IS NULL OR hpd.matno = @matno)
	AND ((@repType = 'B' AND hpd.bqty > 0)
        OR (@repType IS NULL))  -- optional: no filtering if NULL
END
GO

IF OBJECT_ID(N'fiac.uspGetHisSaleDetails', N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspGetHisSaleDetails];
GO

CREATE PROCEDURE [fiac].[uspGetHisSaleDetails]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;

	IF ISJSON(@json) != 1
		THROW 50001,'Invalid JSON ',1;
		
	DECLARE @bpCode VARCHAR(10) = JSON_VALUE(@json,'$.bpCode'),
		@matno VARCHAR(15) = JSON_VALUE(@json,'$.matno'),
		@repType VARCHAR(1) = JSON_VALUE(@json,'$.repType');

	SELECT hsid, invNo, docDate, bpCode, matno, qty, rate, crnQty, bqty FROM [fiac].[hisSaleDetails] hsd
		INNER JOIN [mastcode].[ViLedgerCodes] lc ON hsd.bpCode = lc.lcode
	WHERE (@bpCode IS NULL OR hsd.bpCode = @bpCode)
	AND (@matno IS NULL OR hsd.matno = @matno)
	AND ((@repType = 'B' AND hsd.bqty > 0)
        OR (@repType IS NULL))  -- optional: no filtering if NULL
END
GO

-- Movement reasons as per Rule 55 illustrations
IF OBJECT_ID(N'mastcode.MovementReason',N'U') IS NOT NULL
	DROP TABLE [mastcode].[MovementReason];
GO

CREATE TABLE [mastcode].[MovementReason] 
(
    reaCode VARCHAR(2) NOT NULL PRIMARY KEY,
    reaDescription VARCHAR(30) NOT NULL
) ON [PRIMARY];
GO

INSERT INTO [mastcode].[MovementReason] (reaCode,reaDescription)
	VALUES ('JB','JOBWORK'),
	('AP','APPROVAL'),
	('TR','TRANSFER'),
	('RE','REPAIR'),
	('EX','EXHIBIT'),
	('RT','RETURNABLE');
GO

IF OBJECT_ID(N'mastcode.uspGetMovementReasons',N'P') IS NOT NULL
	DROP PROCEDURE [mastcode].[uspGetMovementReasons]
GO

CREATE PROCEDURE [mastcode].[uspGetMovementReasons]
(
    @json NVARCHAR(MAX) = NULL
)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @reaCode VARCHAR(2);

    -- Extract filter from JSON if provided
    IF @json IS NOT NULL
    BEGIN
        SELECT @reaCode = reaCode FROM OPENJSON(@json, '$')
        WITH (
			reaCode VARCHAR(2) '$.reaCode');
    END

    -- Return data
    SELECT MR.reaCode, MR.reaDescription FROM [mastcode].[MovementReason] MR
    WHERE (@reaCode IS NULL OR MR.reaCode = @reaCode);
END
GO

IF OBJECT_ID(N'inven.DeliveryChallan',N'U') IS NOT NULL
	DROP TABLE [inven].[DeliveryChallan];
GO

CREATE TABLE [inven].[DeliveryChallan] 
(
    dcId BIGINT IDENTITY(1,1) PRIMARY KEY,
    [No] VARCHAR(16) NOT NULL UNIQUE,
    Dt DATE NOT NULL,
	dDt AS [mastcode].[ufGetIDate](Dt),
	lcode VARCHAR(10) FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode),
	taxApplies BIT NOT NULL DEFAULT(1), -- Drop down proc [mastcode].[uspGetBitYesNo]
    movementReason VARCHAR(30)  NOT NULL, -- Drop dowm Proc [mastcode].[uspGetMovementReasons]
    Remarks VARCHAR(250) NULL,
	prodNo VARCHAR(15) NULL,
	qty DECIMAL(12,3) NULL,

	-- Transport
	transMode VARCHAR(1) NOT NULL, -- Drop Down Proc [mastcode].[uspGetTransportMode]
	transId	VARCHAR(15) NULL CONSTRAINT ck_sales_salegoodsdispatch_transid CHECK (TransId IS NULL OR [mastcode].[IsValidGSTIN](TransId) > 0),
    vehicleNo VARCHAR(15)  NULL,
    transDocNo VARCHAR(16)  NULL,       -- LR/RR/AWB/BL
    transDocDate DATE         NULL,
    ewayBillNo VARCHAR(20)  NULL CHECK (ewayBillNo NOT LIKE '%[^0-9]%'),
    ewayBillDate DATETIME NULL,

	-- Consignee Details 
	Gstin VARCHAR(15) NOT NULL CHECK ([mastcode].[IsValidGSTIN](Gstin)>0),
	LglNm VARCHAR(100) NOT NULL,
	Pos VARCHAR(2) NOT NULL,
	Addr1 VARCHAR(100) NOT NULL,
	Addr2 VARCHAR(100) NULL,
	Loc VARCHAR(10) NOT NULL,
	Stcd VARCHAR(2) NOT NULL,
	Pin BIGINT NOT NULL CHECK (Pin >= 100000 AND Pin <= 999999),
	Ph VARCHAR(12) NULL CHECK (Ph IS NULL OR [mastcode].[IsValidPhone](Ph) > 0),
	Em VARCHAR(10) NULL -- Email
);
GO

IF OBJECT_ID(N'inven.DeliveryChallanItemDetails',N'U') IS NOT NULL
	DROP TABLE [inven].[DeliveryChallanItemDetails];
GO

CREATE TABLE [inven].[DeliveryChallanItemDetails]  
(
    dcdId BIGINT IDENTITY(1,1) PRIMARY KEY,
    dcId BIGINT NOT NULL REFERENCES [inven].[DeliveryChallan](dcId) ON DELETE CASCADE,
	matno VARCHAR(15) NOT NULL,	
	PrdDesc VARCHAR(300) NOT NULL, -- Product Description
	HsnCd VARCHAR(8) NOT NULL,
	Qty	DECIMAL (15,3) NOT NULL,
	UnitPrice DECIMAL (15,3) NOT NULL,
	Unit VARCHAR(8) NOT NULL CHECK ([mastcode].[IsValidUnit](Unit) > 0),
	TotAmt DECIMAL (15,3) NOT NULL, --	Gross Amount (Unit Price * Quantity)
	Discount DECIMAL (15,3) NULL DEFAULT 0,
	AssAmt  DECIMAL (15,3) NOT NULL,	-- Taxable Value (Total Amount -Discount)
	GstRt DECIMAL(6,2) NOT NULL,
	GstAmt DECIMAL(15,3) NOT NULL,
	TotItemVal	AS CAST(AssAmt + GstAmt AS DECIMAL(12,2))
) ON [PRIMARY];
GO

IF OBJECT_ID(N'inven.ViDeliveryChallan',N'V') IS NOT NULL
	DROP VIEW [inven].[ViDeliveryChallan];
GO

CREATE VIEW [inven].[ViDeliveryChallan]
AS
WITH v AS (SELECT dcId,
	SUM(Qty) sumQty,
	SUM(TotAmt) sumTotAmt,
	SUM(Discount) sumDiscount,
	SUM(AssAmt) sumAssAmt,
	SUM(GstAmt) sumGstAmt,
	SUM(TotItemVal) sumTotItemVal
FROM [inven].[DeliveryChallanItemDetails] dci GROUP BY dci.[dcId])
SELECT dc.*, v.sumQty,v.sumTotAmt,v.sumDiscount,v.sumAssAmt,v.sumGstAmt,
CASE WHEN dc.Stcd = [mastcode].[ufGetCompanyState]() THEN 'N' ELSE 'Y' END IgstOnIntra,
CASE WHEN dc.Stcd != [mastcode].[ufGetCompanyState]() THEN ROUND(v.sumGstAmt / 2.0, 2) ELSE 0 END sumIgstAmt,
CASE WHEN dc.Stcd = [mastcode].[ufGetCompanyState]() THEN ROUND(v.sumGstAmt / 2.0, 2) ELSE 0 END sumCgstAmt,
CASE WHEN dc.Stcd = [mastcode].[ufGetCompanyState]() THEN ROUND(v.sumGstAmt / 2.0, 2) ELSE 0 END sumSgstAmt,
v.sumTotItemVal FROM v INNER JOIN [inven].[DeliveryChallan] dc ON v.dcId = dc.dcId ;
GO

IF OBJECT_ID(N'inven.uspAddDeliveryChallan',N'P') IS NOT NULL
	DROP PROCEDURE [inven].[uspAddDeliveryChallan];
GO

CREATE PROCEDURE [inven].[uspAddDeliveryChallan]  
(  
	@json NVARCHAR(max),
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @dcId BIGINT, 
			@docno BIGINT,
			@rowAffected int = 0,
			@message NVARCHAR(4000) = NULL
		
		-- Material Does Not Exists check
		SELECT @message = STUFF((SELECT ', '+matno FROM OPENJSON(@json,'$.DeliveryChallanItemDetails')
		WITH (
			matno VARCHAR(15) '$.matno',
			Qty DECIMAL(12,2) '$.Qty'	
			)i WHERE matno NOT IN (SELECT matno FROM [purchase].[Material] WHERE mst = 'A') FOR XML PATH('')),1,1,'') 

		IF @message IS NOT NULL
		BEGIN
			SET @message = 'Material ' + @message + ' Does Not Exists'
			RAISERROR(@message,16,1)
			RETURN
		END 

		-- Auto No
		SELECT @docno = MAX([No]) + 1 FROM [inven].[DeliveryChallan]
		IF @docno IS NULL OR @docno <= 0
		BEGIN
			SELECT @docno = docNo FROM [mastcode].[DocInitialNo] WHERE docName='DLC'
			SET @docno = @docno + 1
		END

		INSERT INTO [inven].[DeliveryChallan] (No, Dt, lcode, taxApplies, movementReason, Remarks, prodNo, qty, transMode, transId, vehicleNo, transDocNo, transDocDate, ewayBillNo, ewayBillDate, Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, Pin, Ph, Em)  
		SELECT ISNULL([No],@docno) docno, Dt, i.lcode, taxApplies, movementReason, Remarks, prodNo, qty, transMode, transId, vehicleNo, transDocNo, transDocDate, ewayBillNo, ewayBillDate, lc.Gstin, lc.lname, lc.Stcd, lc.[add], lc.[add1], lc.city, lc.Stcd, lc.zipCode, lc.phone, lc.email FROM OPENJSON(@json,'$')
			WITH (
				[No] BIGINT '$.No',
				Dt DATE '$.Dt',
				lcode VARCHAR(10) '$.lcode',
				taxApplies BIT '$.taxApplies',
				movementReason VARCHAR(30) '$.movementReason',
				Remarks VARCHAR(250) '$.Remarks',
				prodNo VARCHAR(15) '$.prodNo',
				qty DECIMAL(12,3) '$.qty',
				transMode VARCHAR(1) '$.transMode',
				transId VARCHAR(15) '$.transId',
				vehicleNo VARCHAR(15) '$.vehicleNo',
				transDocNo VARCHAR(16) '$.transDocNo',
				transDocDate DATE '$.transDocDate',
				ewayBillNo VARCHAR(20) '$.ewayBillNo',
				ewayBillDate DATETIME '$.ewayBillDate'
				) i INNER JOIN [mastcode].[LedgerCodes] lc ON i.lcode = lc.lcode;
		SET @dcId = SCOPE_IDENTITY();

		INSERT INTO [inven].[DeliveryChallanItemDetails] (dcId, matno, PrdDesc, HsnCd, Qty, UnitPrice, Unit, TotAmt, Discount, AssAmt, GstRt, GstAmt)    
		SELECT @dcId, dcd.matno, m.matDescription PrdDesc, m.hsnCode HsnCd, dcd.Qty, m.prate UnitPrice, m.unit Unit, ROUND(dcd.Qty * m.prate,2) TotAmt, 0 Discount, ROUND(dcd.Qty * m.prate,2) AssAmt, m.gstTaxRate GstRt,ROUND(ROUND(dcd.Qty * m.prate,2) * m.gstTaxRate * .01,1) GstAmt FROM OPENJSON(@json,'$.DeliveryChallanItemDetails')
		WITH (	
			matno VARCHAR(15) '$.matno',
			Qty DECIMAL(15,3) '$.Qty'
		)dcd INNER JOIN [purchase].[Material] m ON dcd.matno = m.matno  

		SET @rowaffected = @@ROWCOUNT;

		IF @rowAffected > 0
		BEGIN			
			COMMIT TRANSACTION;
			SET @STATUS = @rowAffected;
		END
		ELSE
		BEGIN
            ROLLBACK TRANSACTION;
			RAISERROR ('Check No. of parameters and data type', 16, 1);
        END
	END TRY  
    BEGIN CATCH  
		-- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
		BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
    END CATCH;  
END;
GO
--TEST PROC
--DECLARE @json NVARCHAR(max)='{"No":null,"Dt":"2025-08-25","lcode":"LT0043","taxApplies":true,"movementReason":"Sales Return","Remarks":"Matal returned due to damage","prodNo":"PRD12345","qty":125.75,"transMode":"1","transId":null,"vehicleNo":"BR01AB1234","transDocNo":"DOC20250001","transDocDate":"2025-08-25","ewayBillNo":"32165498765432100001","ewayBillDate":"2025-08-25T14:30:00","DeliveryChallanItemDetails":[{"matno":"MAT002","Qty":10},{"matno":"MAT003","Qty":20}]}'
--EXEC [inven].[uspAddDeliveryChallan] @json

IF OBJECT_ID(N'inven.uspDeleteDeliveryChallan',N'P') IS NOT NULL
	DROP PROCEDURE [inven].[uspDeleteDeliveryChallan];
GO

CREATE PROCEDURE [inven].[uspDeleteDeliveryChallan]  
(  
	@dcId BIGINT,
	@STATUS SMALLINT = 0 OUTPUT  
)  
AS  
BEGIN  
    SET NOCOUNT ON;  
    BEGIN TRY  
		BEGIN TRANSACTION;

		DECLARE @rowAffected int = 0
		
		DELETE [inven].[DeliveryChallan] WHERE [dcId] = @dcId;

		SET @rowaffected = @@ROWCOUNT;

		IF @rowAffected > 0
		BEGIN			
			COMMIT TRANSACTION;
			SET @STATUS = @rowAffected;
		END
		ELSE
		BEGIN
            ROLLBACK TRANSACTION;
			RAISERROR ('Check No. of parameters and data type', 16, 1);
        END
	END TRY  
    BEGIN CATCH  
		-- Rollback any active or uncommittable transactions before  
        -- inserting information in the ErrorLog  
        DECLARE @ErrorMessage NVARCHAR(4000) , @ErrorSeverity INT , @ErrorState INT;  
		SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  
  
		IF @@TRANCOUNT > 0  
		BEGIN  
            ROLLBACK TRANSACTION;  
        END  
  
        EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);  
    END CATCH;  
END;
GO

IF OBJECT_ID(N'inven.uspGetDeliveryChallanRep',N'P') IS NOT NULL
	DROP PROCEDURE [inven].[uspGetDeliveryChallanRep];
GO

CREATE PROCEDURE [inven].[uspGetDeliveryChallanRep]
(
	@json NVARCHAR(max)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @igstOnIntra VARCHAR(1),		
		@lcode VARCHAR(10),
		@fdate DATETIME,
		@tdate DATETIME,
		@searchCondition VARCHAR(500)

	SELECT @igstOnIntra= igstOnIntra,@lcode = lcode,@fdate = fdate,@tdate = tdate FROM OPENJSON (@json,'$')
	WITH 
	(
		igstOnIntra VARCHAR(2) '$.igstOnIntra',		
		lcode VARCHAR(10) '$.lcode',
		fdate DATETIME '$.fdate',
		tdate DATETIME '$.tdate'
	)q;

	SET @searchCondition = 'WHERE Dt >= '''+[mastcode].[ufGetDate](@fdate)+''' AND Dt <= '''+ [mastcode].[ufGetDate](@tdate)+'''';        
	 
	IF @igstOnIntra IS NOT NULL
		SET @searchCondition = @searchCondition + ' AND igstOnIntra = '''+@igstOnIntra+'''';
	IF @lcode IS NOT NULL
		SET @searchCondition = @searchCondition + ' AND lcode = '''+@lcode+'''';

	SET @searchCondition = 'SELECT dcId, [No], Dt, dDt, lcode, taxApplies, movementReason, Remarks, prodNo, qty, transMode, transId, vehicleNo, transDocNo, transDocDate, ewayBillNo, ewayBillDate, Gstin, LglNm, Pos, Addr1, Addr2, Loc, Stcd, Pin, Ph, Em, sumQty, sumTotAmt, sumDiscount, sumAssAmt, sumGstAmt, IgstOnIntra, sumIgstAmt, sumCgstAmt, sumSgstAmt, sumTotItemVal FROM [inven].[ViDeliveryChallan] ' + @searchCondition + ' ORDER BY Dt, [No];'
	
	execute (@searchCondition);
END;
GO

-- Bank Import
CREATE TABLE [fiac].[BankStatement] 
(
	transId BIGINT NOT NULL CONSTRAINT pk_fiac_bankstatement_transid PRIMARY KEY (transId) DEFAULT LEFT(ABS(CAST(CAST(NEWID() AS VARBINARY) AS BIGINT)),10),
	transDate DATETIME NOT NULL,
	transDescription VARCHAR(250) NOT NULL,	
	refNumber VARCHAR(50) NULL,	
	valueDate DATETIME NOT NULL,	
	withdrawal DECIMAL(12,2) NULL,	
	deposit DECIMAL(12,2) NULL,	
	bankCode VARCHAR(10) NOT NULL,	
	lcode VARCHAR(10) NULL,	
	postMethod VARCHAR(1) NOT NULL, -- Drop Down [mastcode].[BankPostMethod](bpmId)	
	naration VARCHAR(255) NULL,
	posted VARCHAR(1) NULL CONSTRAINT ck_fiac_bankstatement_posted CHECK (posted = 'Y')
) ON [PRIMARY];
GO

CREATE TABLE [fiac].[PaymentIn]
(
    payId BIGINT IDENTITY(1,1) PRIMARY KEY,
    Dt DATE NOT NULL CONSTRAINT df_fiac_paymentin_dt DEFAULT (GETDATE()),
    lcode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_paymentin_lcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode), -- Customer Ledger
	dbCode VARCHAR(10) NOT NULL CONSTRAINT fk_fiac_paymentin_dbcode FOREIGN KEY REFERENCES [mastcode].[LedgerCodes](lcode),
    amount DECIMAL(12,2) NOT NULL CHECK (amount > 0),
    mop VARCHAR(20) NOT NULL, -- Drop down [mastcode].[uspGetModeOfPayment]
    refNo VARCHAR(50) NULL,       -- Cheque / Transaction ID
    refDate DATE NULL,
    narration VARCHAR(100) NULL,
    adjAmount DECIMAL(12,2) NOT NULL CONSTRAINT df_fiac_paymentin_adjAmount DEFAULT (0),
    unadjusted  AS (amount - adjAmount) PERSISTED,
	bankTransId BIGINT NULL CONSTRAINT fk_fiac_paymentin_banktransid FOREIGN KEY REFERENCES [fiac].[BankStatement](transId),
	CONSTRAINT ck_fiac_paymentin_unadjusted CHECK (unadjusted >= 0)
);
GO


CREATE OR ALTER PROCEDURE [fiac].[uspAddBankStatement]
    @json   NVARCHAR(MAX),
    @STATUS NVARCHAR(4000) = N'' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
	CREATE TABLE #Map (transId BIGINT);

    BEGIN TRY
        -- Basic JSON validation
        IF @json IS NULL OR ISJSON(@json) <> 1
            THROW 61101, 'Invalid or NULL JSON input.', 1;

        BEGIN TRANSACTION;

        ;WITH Parsed AS (
            SELECT *
            FROM OPENJSON(@json)
            WITH (
                transDateStr NVARCHAR(30)   '$.transDate',
                transDescription VARCHAR(250)   '$.transDescription',
                refNumber VARCHAR(50)    '$.refNumber',
                valueDateStr NVARCHAR(30)   '$.valueDate',
                withdrawal DECIMAL(12,2)  '$.withdrawal',
                deposit DECIMAL(12,2)  '$.deposit',
                bankCode VARCHAR(10)    '$.bankCode',
                lcode VARCHAR(10)    '$.lcode',
                postMethod VARCHAR(1)     '$.postMethod',
                naration VARCHAR(255)   '$.naration'
            )
        ),
        Validated AS (
            SELECT
				COALESCE(TRY_CONVERT(date, transDatestr, 103), TRY_CONVERT(date, transDatestr, 3), TRY_CONVERT(date, transDatestr, 101), TRY_CONVERT(date, transDatestr, 1)) AS transDate,
                transDescription,
                refNumber,
				COALESCE(TRY_CONVERT(date, valueDatestr, 103), TRY_CONVERT(date, valueDatestr, 3), TRY_CONVERT(date, valueDatestr, 101), TRY_CONVERT(date, valueDatestr, 1)) AS valueDate,
                withdrawal,
                deposit,
                bankCode,
                lcode,
                postMethod,
                naration
            FROM Parsed
			WHERE transDateStr IS NOT NULL
			AND transDescription IS NOT NULL
			AND valueDateStr IS NOT NULL
			AND bankCode IS NOT NULL
			AND postMethod IS NOT NULL
        )
        INSERT INTO [fiac].[BankStatement] (transDate, transDescription, refNumber, valueDate, withdrawal, deposit, bankCode, lcode, postMethod, naration)
        OUTPUT inserted.transId INTO #Map (transId)
		SELECT transDate, transDescription, refNumber, valueDate, withdrawal, deposit, bankCode, lcode, postMethod, naration FROM Validated
	   
	   	-- Ledger Posting
		;WITH Inw AS
		(    
			SELECT i.transId, i.transDate,withdrawal,deposit,lcode,bankCode,CONCAT(i.transDescription,' ',i.refNumber,' ',ISNULL(i.naration,'')) AS naration FROM [fiac].[BankStatement] i
			INNER JOIN #Map m ON m.transId = i.transId
		)
		INSERT INTO [gl].[GeneralLedger] (docId, docType, tranDate, lcode, drAmount, crAmount, narration,isBill,adjusted)
		SELECT Inw.transId AS docId,
			'BNK' AS docType,
			Inw.transDate AS tranDate,
			X.lcode,
			X.drAmount,
			X.crAmount,
			X.naration,
			X.isBill,
			X.adjusted
		FROM Inw
		CROSS APPLY
		(
			SELECT Inw.lcode, Inw.withdrawal AS drAmount, 0  AS crAmount, LEFT(naration,100) AS naration,1 AS isBill,0 AS adjusted WHERE Inw.withdrawal IS NOT NULL
			UNION ALL SELECT Inw.bankCode, 0 AS drAmount, Inw.withdrawal  AS crAmount, LEFT(naration,100) AS naration,0 AS isBill,0 AS adjusted WHERE Inw.withdrawal IS NOT NULL
			UNION ALL SELECT Inw.lcode, 0 AS drAmount, Inw.deposit  AS crAmount, LEFT(naration,100) AS naration,1 AS isBill,0 AS adjusted WHERE Inw.deposit IS NOT NULL
			UNION ALL SELECT Inw.bankCode, Inw.deposit AS drAmount, 0  AS crAmount, LEFT(naration,100) AS naration,0 AS isBill,0 AS adjusted WHERE Inw.deposit IS NOT NULL
		) X;

        DECLARE @InsertedRows INT = @@ROWCOUNT;
        COMMIT TRANSACTION;

        SET @STATUS = CONCAT('SUCCESS: ', @InsertedRows, ' row(s) inserted.');
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        SET @STATUS = ERROR_MESSAGE();
        RAISERROR(@STATUS, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE [fiac].[UnclaimedBankStatement]
AS
SELECT transId,[mastcode].[ufGetIDate](transDate) dtransDate,transDescription,refNumber,deposit FROM [fiac].[BankStatement] WHERE ISNULL(deposit,0) > 0 AND lcode IS NULL FOR JSON PATH
GO

CREATE PROCEDURE [fiac].[ClaimBankStatement]
(
    @json NVARCHAR(MAX),
    @status INT = 0 OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @msg NVARCHAR(MAX);

    -- Validate JSON
    IF ISJSON(@json) <> 1
    BEGIN
        THROW 64000, 'Invalid JSON payload.', 1;
    END;

    -- Validate ledger codes
    SELECT @msg = STRING_AGG(j.lcode, ', ')
    FROM OPENJSON(@json,'$')
    WITH (
		lcode VARCHAR(10) '$.lcode'
		) j LEFT JOIN [mastcode].[LedgerCodes] lc ON j.lcode = lc.lcode
    WHERE lc.lcode IS NULL OR j.lcode IS NULL;
	
	IF ISNULL(LTRIM(RTRIM(@msg)), '') <> ''
	BEGIN
		SET @msg = 'Invalid Ledger Code : ' + @msg;
		THROW 64001, @msg, 1;
	END

    -- Duplicate transId
    SET @msg = NULL;
	SELECT @msg = STRING_AGG(CONVERT(varchar(20), d.transId), ', ')
    FROM (
        SELECT transId
        FROM OPENJSON(@json,'$')
        WITH (
			transId BIGINT '$.transId'
			) GROUP BY transId HAVING COUNT(*) > 1
		) d;

    IF ISNULL(LTRIM(RTRIM(@msg)), '') <> ''
    BEGIN
        SET @msg = 'Duplicate Trans Id : ' + @msg;
        THROW 64002, @msg, 1;
    END;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE bs
        SET bs.lcode = i.lcode
        FROM [fiac].[BankStatement] bs
        INNER JOIN (
            SELECT transId, lcode
            FROM OPENJSON(@json,'$')
            WITH (
                transId BIGINT '$.transId',
                lcode   VARCHAR(10) '$.lcode'
            )) i ON i.transId = bs.transId;

        DECLARE @rc INT = @@ROWCOUNT;

        IF @rc = 0
        BEGIN
            -- No rows Updated, treat as error
            SET @msg = 0;
            THROW 64003, @msg, 1;
        END

        SET @status = 1;
        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        EXECUTE [dbo].[uspLogError];
        SET @status = 0;
        THROW;
    END CATCH;
END;
GO

CREATE PROCEDURE [fiac].[BankStatementPendingPost]
AS
SELECT transId,transDate,[mastcode].[ufGetIDate](transDate) dtransDate,lname,city,stateName,transDescription,refNumber,valueDate,deposit FROM [fiac].[BankStatementPending] bsp 
FOR JSON PATH
GO

CREATE PROCEDURE [fiac].[BankStatementPost]
(  
	@STATUS SMALLINT = 0 output  
)  
AS  
BEGIN  
	SET NOCOUNT ON;  
	SET XACT_ABORT ON;
	BEGIN TRY  
		BEGIN TRANSACTION;  
		DECLARE @rowaffected INT  
		INSERT INTO [fiac].[PaymentIn] (Dt,  
			lcode,  
			dbCode,  
			amount,  
			mop,  
			refNo,  
			refDate,
			narration,
			bankTransId)  
		SELECT transDate,lcode,bankCode,deposit,'NEFT/RTGS' mop,refNumber,valueDate,naration,transId FROM [fiac].[BankStatementPending];  

		SET @rowaffected = @@ROWCOUNT;  
		IF @rowaffected > 0  
		BEGIN  
			COMMIT TRANSACTION;  
			SET @STATUS = @rowaffected;  
		END  
		ELSE  
		BEGIN  
			SET @STATUS = 0;  
			ROLLBACK TRANSACTION;  
		END  
	END TRY  
    BEGIN CATCH  
        -- Rollback any active or uncommittable transactions before    
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        
		-- inserting information in the ErrorLog
		EXECUTE [dbo].[uspLogError];  
    
		SET @STATUS = 0;  
		THROW        
	END catch;  
END
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetBankStatement]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @type VARCHAR(1), 
		@fromDate DATE,
		@toDate DATE,
		@lcode NVARCHAR(20);

    -- Parse JSON input
    SELECT @fromDate = JSON_VALUE(@json, '$.fromDate'),
        @toDate = JSON_VALUE(@json, '$.toDate'),
        @lcode = JSON_VALUE(@json, '$.lcode'),
		@type = JSON_VALUE(@json, '$.type')

    SELECT transId, transDate, [mastcode].[ufGetIDate](transDate) AS dtransDate,
        bs.lcode, lc.lname, lc.city, lc.stateName,
        bs.bankCode, transDescription, refNumber, [mastcode].[ufGetIDate](valueDate) dvalueDate, withdrawal, deposit
    FROM [fiac].[BankStatement] bs 
	LEFT OUTER JOIN [mastcode].[ViLedgerCodes] lc ON bs.lcode = lc.lcode
	WHERE (bs.transDate >= @fromDate AND bs.transDate <= @toDate)
		AND (@lcode IS NULL OR bs.lcode = @lcode)
		AND ((@type = 'W' AND ISNULL(bs.withdrawal,0) > 0)
            OR (@type = 'D' AND ISNULL(bs.deposit,0) > 0)
            OR (@type IS NULL))      
END
GO

-- Payment Out
CREATE TABLE [fiac].[PaymentOut] 
(
    payId BIGINT IDENTITY(1,1) PRIMARY KEY,
    Dt DATE NOT NULL,
    lcode VARCHAR(10) NOT NULL,
	crCode VARCHAR(10) NOT NULL,
    amount   DECIMAL(18,2) NOT NULL,
    mop VARCHAR(20) NOT NULL, -- Drop Down [mastcode].[uspGetModeOfPayment]
    refNo        VARCHAR(30) NULL,
    refDate      DATE NULL,
    narration    VARCHAR(200) NULL,
	adjAmount  DECIMAL(12,2) NOT NULL DEFAULT 0,
	unadjusted AS amount - adjAmount PERSISTED,
	payStatus VARCHAR(1) CHECK (payStatus IN ('U','E')),
 	utrno BIGINT NULL,
	CONSTRAINT ck_fiac_paymentout_amount_adjusted CHECK (amount >= adjAmount),
) ON [Primary];
GO

CREATE TABLE [fiac].[PaymentOutAdjustment] 
(
    adjId BIGINT IDENTITY(1,1) PRIMARY KEY,
    payId BIGINT NOT NULL,
    transId BIGINT,
	vtype VARCHAR(1),
    adjAmount DECIMAL(18,2) NOT NULL,
    CONSTRAINT fk_fiac_PaymentOutAdjustment_payId FOREIGN KEY (PayId) REFERENCES [fiac].[PaymentOut](PayId) ON DELETE CASCADE
) ON [PRIMARY];
GO

CREATE OR ALTER VIEW [fiac].[BillPending]
AS
SELECT transId,billNo, billDate,DATEDIFF(d,billDate,GETDATE()) tdays, lcode,'I' vtype,tdsAmount, tamount,ISNULL(payAmount,0) + ISNULL(tdsAmount,0) AS paid, bamount FROM [fiac].[Inward] WHERE bamount > 0
UNION ALL SELECT transId,billNo, billDate,DATEDIFF(d,billDate,GETDATE()) tdays, lcode,'V' vtype,tdsAmount, tamount,ISNULL(payAmount,0)  + ISNULL(tdsAmount,0), bamount FROM [fiac].[InwardVoucher] WHERE bamount > 0
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetBillPending]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 64001, 'Input JSON is required.', 1;

        IF LEFT(LTRIM(@json),1) = '['
            THROW 64002, 'Array JSON not allowed. Pass single object.', 1;

        IF ISJSON(@json) <> 1
            THROW 64003, 'Invalid JSON format.', 1;

        DECLARE @lcode VARCHAR(10),@iday INT;

        SELECT @lcode = j.lcode,@iday = ISNULL(j.iday,0)
        FROM OPENJSON(@json)
        WITH (
            lcode VARCHAR(10) '$.lcode',
            iday INT '$.iday'
        ) j;

		WITH BillData AS (
		SELECT	bp.lcode, lc.lname,	lc.city, lc.stateName,
			bp.vtype, bp.transId, bp.billNo, bp.billDate,bp.tdays, bp.tdsAmount,	bp.tamount,	bp.paid, bp.bamount,
			SUM(bp.bamount) OVER (
				PARTITION BY bp.lcode 
				ORDER BY bp.billDate, bp.billNo, bp.transId
				ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
				) AS rowBamount
			FROM [fiac].[BillPending] bp
			INNER JOIN [mastcode].[ViLedgerCodes] lc 
			ON bp.lcode = lc.lcode
			WHERE (@iday IS NULL OR bp.tdays >= @iday)
				AND (@lcode IS NULL OR bp.lcode = @lcode)
			)
		SELECT
		-- Detailed + per-lcode summary
		(
			SELECT lcode, lname, city, stateName,
            -- detailed rows
            (SELECT transId, billNo, billDate, tdays, [mastcode].[ufGetIDate](billDate) dbillDate, vtype, tdsAmount, tamount, paid, bamount, rowBamount
             FROM BillData bd2 WHERE bd2.lcode = bd1.lcode ORDER BY bd2.billDate, bd2.billNo FOR JSON PATH ) AS details,
            -- summary per ledger
            (SELECT SUM(bamount) AS totalBamount,
                 SUM(paid) AS totalPaid,
                 SUM(bamount) AS totalPending
             FROM BillData bd3
             WHERE bd3.lcode = bd1.lcode FOR JSON PATH, WITHOUT_ARRAY_WRAPPER ) AS summary
			FROM BillData bd1
			GROUP BY lcode, lname, city, stateName
			ORDER BY lname
			FOR JSON PATH
		) AS LcodeData,
		-- grand summary
		(
		 SELECT SUM(bamount) AS grandTotalBamount,
         SUM(paid) AS grandTotalPaid,
         SUM(bamount) AS grandTotalPending
		FROM BillData
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		) AS GrandSummary
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER TRIGGER [fiac].[tr_PaymentOut_Insert]
ON [fiac].[PaymentOut]
AFTER INSERT
AS
BEGIN
	/*
        Trigger Purpose:
        ----------------
        Automatically allocate newly inserted payments against pending bills
        (from [fiac].[Purchase] view, which unions Inward + InwardVoucher).

        Allocation is FIFO (oldest bills first, by billdate then transId).
        Supports multiple rows inserted into PaymentOut in one batch.
    */
	SET NOCOUNT ON;

    ;WITH PendingBills AS
    (
        SELECT 
            p.transId,
            p.vtype,
            p.lcode,
            p.billdate,
            p.bamount,  -- already net = BillAmount - ISNULL(payAmount,0)
            i.payId,
            i.amount AS payAmount,
            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY p.billdate, p.transId) AS rn,
            SUM(p.bamount) OVER (PARTITION BY i.payId ORDER BY p.billdate, p.transId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal
        FROM inserted i
        JOIN [fiac].[BillPending] p 
            ON p.lcode = i.lcode
        WHERE p.bamount > 0
    ),
    Allocation AS
    (
        SELECT 
            pb.payId,
            pb.transId,
            pb.vtype,
            CASE 
                WHEN pb.payAmount >= pb.RunningBillTotal 
                     THEN pb.bamount                             -- full bill gets cleared
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.bamount 
                     THEN 0                                     -- nothing allocated
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.bamount) -- partial allocation
            END AS AllocatedAmount
        FROM PendingBills pb
    )
    INSERT INTO fiac.PaymentOutAdjustment (payId, transId, vtype, adjAmount)
    SELECT payId, transId, vtype, AllocatedAmount
    FROM Allocation
    WHERE AllocatedAmount > 0;
END;
GO

CREATE OR ALTER TRIGGER [fiac].[tr_PaymentOutAdjustment_Audit]
ON [fiac].[PaymentOutAdjustment]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------------------------------
    -- DELETE: Roll back adjustments that are being removed
    -----------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- InwardVoucher
        UPDATE iv
        SET iv.payAmount = ISNULL(iv.payAmount,0) - d.totalAdj
        FROM [fiac].[InwardVoucher] iv
        INNER JOIN (
            SELECT vtype, transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            GROUP BY vtype, transId
        ) d ON d.vtype = 'V' AND iv.transId = d.transId;

        -- Inward
        UPDATE iw
        SET iw.payAmount = ISNULL(iw.payAmount,0) - d.totalAdj
        FROM [fiac].[Inward] iw
        INNER JOIN (
            SELECT vtype, transId, SUM(adjAmount) AS totalAdj
            FROM deleted
            GROUP BY vtype, transId
        ) d ON d.vtype = 'I' AND iw.transId = d.transId;

        -- PaymentOut
        UPDATE po
        SET po.adjAmount = ISNULL(po.adjAmount,0) - d.totalAdj
        FROM [fiac].[PaymentOut] po
        INNER JOIN (
            SELECT payId, SUM(adjAmount) AS totalAdj
            FROM deleted
            GROUP BY payId
        ) d ON po.payId = d.payId;
    END;

    -----------------------------------------------------------------
    -- INSERT: Apply new adjustments
    -----------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- InwardVoucher
        UPDATE iv
        SET iv.payAmount = ISNULL(iv.payAmount,0) + i.totalAdj
        FROM [fiac].[InwardVoucher] iv
        INNER JOIN (
            SELECT vtype, transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            GROUP BY vtype, transId
        ) i ON i.vtype = 'V' AND iv.transId = i.transId;

        -- Inward
        UPDATE iw
        SET iw.payAmount = ISNULL(iw.payAmount,0) + i.totalAdj
        FROM [fiac].[Inward] iw
        INNER JOIN (
            SELECT vtype, transId, SUM(adjAmount) AS totalAdj
            FROM inserted
            GROUP BY vtype, transId
        ) i ON i.vtype = 'I' AND iw.transId = i.transId;

        -- PaymentOut
        UPDATE po
        SET po.adjAmount = ISNULL(po.adjAmount,0) + i.totalAdj
        FROM [fiac].[PaymentOut] po
        INNER JOIN (
            SELECT payId, SUM(adjAmount) AS totalAdj
            FROM inserted
            GROUP BY payId
        ) i ON po.payId = i.payId;
    END;
END;
GO

CREATE PROCEDURE [fiac].[PurchaseLedger]
	@json NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	IF ISJSON(@json) <> 1
    THROW 64001, 'Invalid JSON input.', 1;

	DECLARE @lcode VARCHAR(10) = JSON_VALUE(@json,'$.lcode');
	SELECT
		CASE WHEN X.rnBill = 1 THEN X.transId   END AS transId,
		CASE WHEN X.rnBill = 1 THEN X.vtype     END AS vtype,
		CASE WHEN X.rnBill = 1 THEN X.lcode     END AS lcode,
		CASE WHEN X.rnBill = 1 THEN X.lname     END AS lname,
		CASE WHEN X.rnBill = 1 THEN X.city      END AS city,
		CASE WHEN X.rnBill = 1 THEN X.stateName END AS stateName,
		CASE WHEN X.rnBill = 1 THEN X.billNo    END AS billNo,
		CASE WHEN X.rnBill = 1 THEN X.billDate  END AS billDate,
		CASE WHEN X.rnBill = 1 THEN X.tamount   END AS tamount,
		CASE WHEN X.rnBill = 1 THEN X.tdsAmount END AS tdsAmount,
		CASE WHEN X.rnBill = 1 THEN X.paid      END AS paid,
		CASE WHEN X.rnBill = 1 THEN X.bamount   END AS bamount,

		CASE WHEN X.rnPay = 1 THEN X.payId END   AS payId,
		CASE WHEN X.rnPay = 1 THEN X.amount END  AS amount,

		ISNULL(X.adjAmount,0) AS adjAmount
		FROM (
			SELECT 
			p.transId,
			p.vtype,
			p.lcode,
			lc.lname,
			lc.city,
			lc.stateName,
			p.billNo,
			p.billDate,
			p.tamount,
			p.tdsAmount,
			p.paid,
			p.bamount,
			padj.payId,
			padj.adjAmount,
			po.amount,
			ROW_NUMBER() OVER (
				PARTITION BY p.transId, p.vtype 
				ORDER BY po.payId
			) AS rnBill,
			ROW_NUMBER() OVER (
				PARTITION BY padj.payId 
				ORDER BY p.transId, p.vtype
			) AS rnPay
		FROM fiac.Purchase p
		INNER JOIN mastcode.ViLedgerCodes lc ON p.lcode = lc.lcode
		LEFT JOIN fiac.PaymentOutAdjustment padj 
			ON p.transId = padj.transId AND p.vtype = padj.vtype
		LEFT JOIN fiac.PaymentOut po 
			ON padj.payId = po.payId
		WHERE (@lcode IS NULL OR p.lcode = @lcode)
		) X
		ORDER BY X.lcode, X.transId, X.payId;
END
GO

CREATE OR ALTER PROCEDURE [fiac].[uspAddPaymentOut]
(
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
)
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET XACT_ABORT ON;  
  
    BEGIN TRY  
        -- Input,Normalize AND Valid JSON check respectively  
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''  
            THROW 51001, 'Input JSON is required.', 1;  
  
        IF ISJSON(@json) <> 1  
            THROW 51002, 'Invalid JSON.', 1;  
  
        -- Parsing JSON As table variable  
        DECLARE @Input TABLE  
        (  
            RowNo     INT IDENTITY(1,1) PRIMARY KEY,  
            Dt        DATE,  
            lcode     VARCHAR(10),  
            crCode    VARCHAR(10),  
            amount    DECIMAL(18,2),
            mop       VARCHAR(20),  
            refNo     VARCHAR(30),  
            refDate   DATE,
            narration VARCHAR(200)  
        );  
  
        INSERT INTO @Input (Dt, lcode, crCode, amount, mop, refNo, refDate, narration)  
        SELECT j.Dt, j.lcode, j.crCode, j.amount, j.mop, j.refNo, j.refDate, j.narration  
        FROM OPENJSON(@json,'$')  
        WITH (  
            Dt        DATE         '$.Dt',  
            lcode     VARCHAR(10)  '$.lcode',  
            crCode    VARCHAR(10)  '$.crCode',  
            amount    DECIMAL(18,2) '$.amount',  
            mop       VARCHAR(1)   '$.mop',  
            refNo     VARCHAR(30)  '$.refNo',  
            refDate   DATE         '$.refDate',  
            narration VARCHAR(200) '$.narration'  
        ) AS j;  
  
        DECLARE @msg NVARCHAR(MAX);  
  
        -- Required field validation  
        IF EXISTS (SELECT 1 FROM @Input WHERE Dt IS NULL OR lcode IS NULL OR crCode IS NULL OR amount IS NULL OR mop IS NULL)  
        BEGIN  
            SET @msg = 'Dt, lcode, crCode, amount, and mop are required fields.';  
            THROW 51003, @msg, 1;  
        END  
  
        -- Payload duplicate validation (within JSON input)  
        IF EXISTS (  
            SELECT Dt, lcode, crCode, amount, mop, refNo, refDate, COUNT(*) AS Cnt  
            FROM @Input  
            GROUP BY Dt, lcode, crCode, amount, mop, refNo, refDate  
            HAVING COUNT(*) > 1  
        )  
        BEGIN  
            DECLARE @dup NVARCHAR(MAX);  
            SELECT @dup = STRING_AGG(  
                CONCAT('(', Dt, ', ', lcode, ', ', crCode, ', ', amount, ', ', mop, ', ', ISNULL(refNo,'NULL'), ', ', ISNULL(CONVERT(VARCHAR(10),refDate,120),'NULL'), ')'), '; '  
            )  
            FROM (  
                SELECT Dt, lcode, crCode, amount, mop, refNo, refDate  
                FROM @Input  
                GROUP BY Dt, lcode, crCode, amount, mop, refNo, refDate  
                HAVING COUNT(*) > 1  
            ) d;  
  
            SET @msg = 'Duplicate rows found in JSON input: ' + ISNULL(@dup,'');  
            THROW 51004, @msg, 1;  
        END  
  
        -- Foreign key validation: lcode must exist  
        IF EXISTS (  
            SELECT 1 FROM @Input i  
            LEFT JOIN [mastcode].[LedgerCodes] l ON i.lcode = l.lcode  
            WHERE l.lcode IS NULL  
        )  
        BEGIN  
            DECLARE @badLcode NVARCHAR(MAX);  
            SELECT @badLcode = STRING_AGG(t.lcode, ', ')  
            FROM (  
                SELECT DISTINCT i.lcode  
                FROM @Input i  
                LEFT JOIN [mastcode].[LedgerCodes] l ON i.lcode = l.lcode  
                WHERE l.lcode IS NULL  
            ) t(lcode);  
            SET @msg = 'Invalid lcode (not found in LedgerCodes): ' + ISNULL(@badLcode,'');  
            THROW 51005, @msg, 1;  
        END  
  
        -- Foreign key validation: crCode must exist  
        IF EXISTS (  
            SELECT 1 FROM @Input i  
            LEFT JOIN [mastcode].[LedgerCodes] c ON i.crCode = c.lcode  
            WHERE c.lcode IS NULL  
        )  
        BEGIN  
            DECLARE @badCr NVARCHAR(MAX);  
            SELECT @badCr = STRING_AGG(t.crCode, ', ')  
            FROM (  
                SELECT DISTINCT i.crCode  
                FROM @Input i  
                LEFT JOIN [mastcode].[LedgerCodes] c ON i.crCode = c.lcode  
                WHERE c.lcode IS NULL  
            ) t(crCode);  
            SET @msg = 'Invalid crCode (not found in LedgerCodes): ' + ISNULL(@badCr,'');  
            THROW 51006, @msg, 1;  
        END  
  
        BEGIN TRAN;  
  
            INSERT INTO [fiac].[PaymentOut] (Dt, lcode, crCode, amount, mop, refNo, refDate, narration)  
            SELECT Dt, lcode, crCode, amount, mop, refNo, refDate, narration  
            FROM @Input;  
  
            SET @STATUS = @@ROWCOUNT;  
  
        COMMIT TRAN;  
    END TRY  
    BEGIN CATCH  
        IF XACT_STATE() <> 0 ROLLBACK TRAN;  
		EXECUTE [dbo].[uspLogError];
        SET @STATUS = 0;  
        THROW;  
    END CATCH  
END  
GO

CREATE OR ALTER PROCEDURE [fiac].[uspUpdatePaymentOut]  
    @json NVARCHAR(MAX),  
    @STATUS INT = 0 OUTPUT  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET XACT_ABORT ON;  

    BEGIN TRY  
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''  
            THROW 60001, 'Input JSON is required.', 1;

        IF ISJSON(@json) <> 1  
            THROW 60002, 'Invalid JSON.', 1;  

        DECLARE @Input TABLE  
        (  
            RowNo   INT IDENTITY(1,1) PRIMARY KEY,  
            payId   BIGINT,  
            Dt      DATE,  
            lcode   VARCHAR(10),  
            crCode  VARCHAR(10),  
            amount  DECIMAL(18,2),  
            mop     VARCHAR(20),  
            refNo   VARCHAR(30),  
            refDate DATE,  
            narration VARCHAR(200)  
        );  

        INSERT INTO @Input (payId, Dt, lcode, crCode, amount, mop, refNo, refDate, narration)  
        SELECT j.payId, j.Dt, j.lcode, j.crCode, j.amount, j.mop, j.refNo, j.refDate, j.narration  
        FROM OPENJSON(@json)  
        WITH (  
            payId BIGINT '$.payId',  
            Dt DATE '$.Dt',  
            lcode VARCHAR(10) '$.lcode',  
            crCode VARCHAR(10) '$.crCode',  
            amount DECIMAL(18,2) '$.amount',  
            mop VARCHAR(1) '$.mop',  
            refNo VARCHAR(30) '$.refNo',  
            refDate DATE '$.refDate',  
            narration VARCHAR(200) '$.narration'  
        ) AS j;  

        DECLARE @msg NVARCHAR(MAX);  

        -- Required fields  
        IF EXISTS (SELECT 1 FROM @Input WHERE payId IS NULL OR Dt IS NULL OR lcode IS NULL OR crCode IS NULL OR mop IS NULL)  
        BEGIN  
            THROW 60003, 'payId, Dt, lcode, crCode, mop are required.', 1;  
        END  

        -- Duplicate payId in payload
        IF EXISTS (
            SELECT 1
            FROM @Input
            GROUP BY payId
            HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(CAST(payId AS VARCHAR(20)), ', ')
            FROM (
                SELECT payId FROM @Input GROUP BY payId HAVING COUNT(*) > 1
            ) d;
            SET @STATUS = 'Duplicate payId in input: ' + ISNULL(@dup,'');
            THROW 62006, @STATUS, 1;
        END; 
  
        -- Validate existing records  
        IF EXISTS (SELECT 1 FROM @Input i LEFT JOIN fiac.PaymentOut p ON i.payId = p.payId WHERE p.payId IS NULL)  
        BEGIN  
            DECLARE @bad NVARCHAR(MAX);  
            SELECT @bad = STRING_AGG(CAST(i.payId AS VARCHAR(20)), ', ')  
            FROM @Input i  
            LEFT JOIN fiac.PaymentOut p ON i.payId = p.payId  
            WHERE p.payId IS NULL;  

            SET @msg = 'Invalid payId (not found): ' + @bad;  
            THROW 60004, @msg, 1;  
        END

        -- Foreign key validation: lcode must exist  
        IF EXISTS (  
            SELECT 1 FROM @Input i  
            LEFT JOIN [mastcode].[LedgerCodes] l ON i.lcode = l.lcode  
            WHERE l.lcode IS NULL  
        )  
        BEGIN  
            DECLARE @badLcode NVARCHAR(MAX);  
            SELECT @badLcode = STRING_AGG(t.lcode, ', ')  
            FROM (  
                SELECT DISTINCT i.lcode  
                FROM @Input i  
                LEFT JOIN [mastcode].[LedgerCodes] l ON i.lcode = l.lcode  
                WHERE l.lcode IS NULL  
            ) t(lcode);  
            SET @msg = 'Invalid lcode (not found in LedgerCodes): ' + ISNULL(@badLcode,'');  
            THROW 51005, @msg, 1;  
        END  
  
        -- Foreign key validation: crCode must exist  
        IF EXISTS (  
            SELECT 1 FROM @Input i  
            LEFT JOIN [mastcode].[LedgerCodes] c ON i.crCode = c.lcode  
            WHERE c.lcode IS NULL  
        )  
        BEGIN  
            DECLARE @badCr NVARCHAR(MAX);  
            SELECT @badCr = STRING_AGG(t.crCode, ', ')  
            FROM (  
                SELECT DISTINCT i.crCode  
                FROM @Input i  
                LEFT JOIN [mastcode].[LedgerCodes] c ON i.crCode = c.lcode  
                WHERE c.lcode IS NULL  
            ) t(crCode);  
            SET @msg = 'Invalid crCode (not found in LedgerCodes): ' + ISNULL(@badCr,'');  
            THROW 51006, @msg, 1;  
        END  
		-- Action Begin
        BEGIN TRAN;  

            UPDATE p  
            SET  
                p.Dt = i.Dt,  
                p.lcode = i.lcode,  
                p.crCode = i.crCode,  
                p.amount = i.amount,  
                p.mop = i.mop,  
                p.refNo = i.refNo,  
                p.refDate = i.refDate,  
                p.narration = i.narration  
            FROM fiac.PaymentOut p  
            JOIN @Input i ON p.payId = i.payId;  

            SET @STATUS = @@ROWCOUNT;  

        COMMIT TRAN;  
    END TRY  
    BEGIN CATCH  
        IF XACT_STATE() <> 0 ROLLBACK TRAN;  
        EXEC dbo.uspLogError;  
        SET @STATUS = 0;  
        THROW;  
    END CATCH  
END  
GO  

CREATE OR ALTER PROCEDURE [fiac].[uspDeletePaymentOut]  
    @json NVARCHAR(MAX),  
    @STATUS INT = 0 OUTPUT  
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET XACT_ABORT ON;  

    BEGIN TRY  
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''  
            THROW 61001, 'Input JSON is required.', 1;  
 
        IF ISJSON(@json) <> 1  
            THROW 61002, 'Invalid JSON.', 1;  

        DECLARE @Input TABLE (RowNo INT IDENTITY(1,1) PRIMARY KEY, payId BIGINT);  

        INSERT INTO @Input (payId)  
        SELECT j.payId  
        FROM OPENJSON(@json)  
        WITH (payId BIGINT '$.payId') j;  

        -- Required field check  
        IF EXISTS (SELECT 1 FROM @Input WHERE payId IS NULL)  
            THROW 61003, 'payId is required.', 1;  

        -- Validate payId exists  
        IF EXISTS (SELECT 1 FROM @Input i LEFT JOIN fiac.PaymentOut p ON i.payId = p.payId WHERE p.payId IS NULL)  
        BEGIN  
            DECLARE @bad NVARCHAR(MAX);  
            SELECT @bad = STRING_AGG(CAST(i.payId AS VARCHAR(20)), ', ')  
            FROM @Input i  
            LEFT JOIN fiac.PaymentOut p ON i.payId = p.payId  
            WHERE p.payId IS NULL;  

            DECLARE @msg NVARCHAR(MAX) = 'Invalid payId (not found): ' + @bad;  
            THROW 61004, @msg, 1;  
        END  

        BEGIN TRAN;  

            DELETE p  
            FROM fiac.PaymentOut p  
            JOIN @Input i ON p.payId = i.payId;  

            SET @STATUS = @@ROWCOUNT;  

        COMMIT TRAN;  
    END TRY  
    BEGIN CATCH  
        IF XACT_STATE() <> 0 ROLLBACK TRAN;  
        EXEC dbo.uspLogError;  
        SET @STATUS = 0;  
        THROW;  
    END CATCH  
END  
GO  

CREATE OR ALTER PROCEDURE [fiac].[uspGetPaymentOut]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Validate input
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 51001, 'Input JSON is required.', 1;

        -- Reject array JSON
        IF LEFT(LTRIM(@json),1) = '['
            THROW 51002, 'Array JSON is not allowed. Pass a single JSON object.', 1;

        IF ISJSON(@json) <> 1
            THROW 51003, 'Invalid JSON format.', 1;

        -- Declare variables
        DECLARE @payId BIGINT,
                @fromDate DATE,
                @toDate DATE,
                @lcode VARCHAR(10);

        -- Extract values
        SELECT @payId    = j.payId,
               @fromDate = j.fromDate,
               @toDate   = j.toDate,
               @lcode    = j.lcode
        FROM OPENJSON(@json)
        WITH (
            payId    BIGINT      '$.payId',
            fromDate DATE        '$.fromDate',
            toDate   DATE        '$.toDate',
            lcode    VARCHAR(10) '$.lcode'
        ) j;

        -- Mandatory date validation
        IF @payId IS NULL
		BEGIN
			IF @fromDate IS NULL OR @toDate IS NULL
				THROW 51004, 'Both fromDate and toDate are required.', 1;
		END

        -- Return data
        SELECT p.payId, p.Dt, [mastcode].[ufGetIDate](p.Dt) dDt, p.lcode,lc.lname, p.crCode, crlc.lname crName, p.amount, p.mop,
               p.refNo, p.refDate, p.narration, p.adjAmount, p.unadjusted
        FROM fiac.PaymentOut p
		INNER JOIN [mastcode].[LedgerCodes] lc ON p.lcode = lc.lcode
		INNER JOIN [mastcode].[LedgerCodes] crlc ON p.crCode = crlc.lcode
        WHERE
            (@payId IS NULL OR p.payId = @payId)
            AND (@lcode IS NULL OR p.lcode = @lcode)
            AND (@fromDate IS NULL OR p.Dt >= @fromDate)
            AND (@toDate IS NULL OR  p.Dt <= @toDate)
        ORDER BY p.Dt, p.payId;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE VIEW [fiac].[PaymentOutAdvance]  
AS  
SELECT payId,Dt,po.lcode,lc.lname,lc.city,lc.stateName StName,amount,adjAmount, unadjusted, refNo,refDate,narration FROM [fiac].[PaymentOut] po   
INNER JOIN [mastcode].[ViLedgerCodes] lc ON po.lcode = lc.lcode WHERE unadjusted > 0 
GO

CREATE OR ALTER PROCEDURE [fiac].[PaymentOutAdvance_Post]  
AS  
BEGIN  
 /*  
        Procedure Purpose:  
        ----------------  
        Automatically allocate Advance payments against pending bills  
        (from [fiac].[Purchase] view, which unions Inward + InwardVoucher).  
  
        Allocation is FIFO (oldest bills first, by billdate then transId).  
        Supports multiple rows inserted into PaymentOut in one batch.  
    */  
 SET NOCOUNT ON;  
  
    ;WITH PendingBills AS  
    (  
        SELECT   
            p.transId,  
            p.vtype,  
            p.lcode,  
            p.billdate,  
            p.bamount,  -- already net = BillAmount - ISNULL(payAmount,0)  
            i.payId,  
            i.unadjusted AS payAmount,  
            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY p.billdate, p.transId) AS rn,  
            SUM(p.bamount) OVER (PARTITION BY i.payId ORDER BY p.billdate, p.transId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal  
        FROM (SELECT payId,lcode,unadjusted FROM [fiac].[PaymentOutAdvance]) As i  
        JOIN [fiac].[Purchase] p   
            ON p.lcode = i.lcode  
        WHERE p.bamount > 0  
    ),  
    Allocation AS  
    (  
        SELECT   
            pb.payId,  
            pb.transId,  
            pb.vtype,  
            CASE   
                WHEN pb.payAmount >= pb.RunningBillTotal   
                     THEN pb.bamount                             -- full bill gets cleared  
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.bamount   
                     THEN 0                                     -- nothing allocated  
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.bamount) -- partial allocation  
            END AS AllocatedAmount  
        FROM PendingBills pb  
    )  
    INSERT INTO fiac.PaymentOutAdjustment (payId, transId, vtype, adjAmount)  
    SELECT payId, transId, vtype, AllocatedAmount  
    FROM Allocation  
    WHERE AllocatedAmount > 0;  
END;  
GO

CREATE VIEW [fiac].[PaymentPending]  
AS  
SELECT docId,'I' Vtype,[No],Dt,DATEDIFF(dd,Dt,GETDATE()) as tdays, lcode,LglNm,Loc,Stcd, Stname,TotVal,adjAmount,unadjusted FROM [sales].[Sale] WHERE unadjusted > 0  
UNION ALL SELECT docId,'D' Vtype,[No],Dt,DATEDIFF(dd,Dt,GETDATE()) as tdays,lcode,LglNm,Loc,Stcd, Stname,TotVal,adjAmount paid,unadjusted FROM [fiac].[SaleDbnote] WHERE unadjusted > 0  
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetPaymentPending]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Input validation
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 65001, 'Input JSON is required.', 1;

        IF LEFT(LTRIM(@json),1) = '['
            THROW 65002, 'Array JSON not allowed. Pass single object.', 1;

        IF ISJSON(@json) <> 1
            THROW 65003, 'Invalid JSON format.', 1;

        DECLARE @lcode VARCHAR(10),@iday INT,@stcode VARCHAR(2);

        SELECT @lcode = j.lcode,@iday = ISNULL(j.iday,0),@stcode = stcode
        FROM OPENJSON(@json)
        WITH (
            lcode VARCHAR(10) '$.lcode',
            iday INT '$.iday',
			stcode VARCHAR(2) '$.stcode'
        ) j;

        ;WITH PayData AS (
            SELECT
                pp.lcode,
                pp.LglNm   AS lname,
                pp.Loc     AS city,
                pp.Stname  AS stateName,
                'I'       AS vtype,
                pp.docId   AS transId,
                pp.[No]    AS billNo,
                pp.[Dt]    AS billDate,
				pp.tdays,
                pp.[TotVal] AS tamount,
                pp.adjAmount AS paid,
                pp.unadjusted AS bamount,
                SUM(pp.unadjusted) OVER (
                    PARTITION BY pp.lcode
                    ORDER BY pp.[Dt], pp.[No], pp.docId
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                ) AS rowBamount
            FROM [fiac].[PaymentPending] pp
            WHERE pp.unadjusted > 0
              AND (@lcode IS NULL OR pp.lcode = @lcode)
			  AND (@iday IS NULL OR pp.tdays >= @iday)
			  AND (@stcode IS NULL OR pp.Stcd = @stcode)
        )
        SELECT
            (
                SELECT
                    lcode, lname, city, stateName,
                    -- detailed rows
                    (SELECT
                         transId, billNo, billDate, [mastcode].[ufGetIDate](billDate) dbillDate, tdays, vtype, tamount, paid, bamount, rowBamount
                     FROM PayData pd2
                     WHERE pd2.lcode = pd1.lcode
                     ORDER BY pd2.billDate, pd2.billNo, pd2.transId
                     FOR JSON PATH
                    ) AS details,
                    -- summary per ledger
                    (SELECT
                         SUM(bamount)        AS totalBamount,
                         SUM(paid)           AS totalPaid,
                         SUM(bamount) AS totalPending
                     FROM PayData pd3
                     WHERE pd3.lcode = pd1.lcode
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
                    ) AS summary
                FROM PayData pd1
                GROUP BY lcode, lname, city, stateName
                ORDER BY lname
                FOR JSON PATH
            ) AS LcodeData,
            (
                SELECT
                    SUM(bamount)        AS grandTotalBamount,
                    SUM(paid)           AS grandTotalPaid,
                    SUM(bamount) AS grandTotalPending
                FROM PayData
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) AS GrandSummary
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE TABLE [fiac].[PaymentInAdjustment]
(
    payAdjId BIGINT IDENTITY(1,1) PRIMARY KEY,
    payId BIGINT NOT NULL CONSTRAINT fk_fiac_paymentinadjustment_payId FOREIGN KEY (payId) REFERENCES [fiac].[PaymentIn](payId) ON DELETE CASCADE,
    docId BIGINT NOT NULL, -- Sale or Debit Note
    vtype CHAR(1) NOT NULL CHECK (vtype IN ('I','D')), -- 'I' = Sale Invoice, 'D' = Debit Note
    adjustAmt   DECIMAL(18,2) NOT NULL CHECK (adjustAmt > 0)   
);
GO

CREATE VIEW [fiac].[PaymentInAdvance]  
AS  
SELECT payId,Dt,pin.lcode,lc.lname,lc.city,lc.stateName StName,amount,adjAmount, unadjusted, refNo,refDate,narration FROM [fiac].[PaymentIn] pin   
INNER JOIN [mastcode].[ViLedgerCodes] lc ON pin.lcode = lc.lcode WHERE unadjusted > 0 
GO

CREATE OR ALTER PROCEDURE [fiac].[PaymentInAdvance_Post]
AS
BEGIN
    /*
        Procedure Purpose:
        ----------------
        Automatically allocate newly advance payment against pending bills
        (from [fiac].[PaymentPending], which unions Sale + SaleDbnote).

        Allocation is FIFO (oldest bills first, by Dt then docId).
        Supports multiple rows inserted into PaymentIn in one batch.
    */
    SET NOCOUNT ON;

    ;WITH PendingBills AS
    (
        SELECT 
            b.docId,
            b.vtype,
            b.lcode,
            b.Dt AS billDt,
            b.unadjusted AS billRemain,
            i.payId,
            i.unadjusted AS payAmount,
            i.Dt AS payDt,
            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId) AS rn,
            SUM(b.unadjusted) OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal
        FROM (SELECT payId, Dt, lcode, unadjusted FROM [fiac].[PaymentInAdvance]) i
        JOIN [fiac].[PaymentPending] b 
            ON b.lcode = i.lcode
        WHERE b.unadjusted > 0
    ),
    Allocation AS
    (
        SELECT 
            pb.payId,
            pb.docId,
            pb.vtype,
            CASE 
                WHEN pb.payAmount >= pb.RunningBillTotal 
                     THEN pb.billRemain                            -- full bill gets cleared
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.billRemain 
                     THEN 0                                        -- nothing allocated
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.billRemain) -- partial allocation
            END AS AllocatedAmount
        FROM PendingBills pb
    )
    INSERT INTO [fiac].[PaymentInAdjustment] (payId, docId, vtype, adjustAmt)
    SELECT payId, docId, vtype, AllocatedAmount
    FROM Allocation
    WHERE AllocatedAmount > 0;
END;
GO

CREATE OR ALTER TRIGGER [fiac].[tr_PaymentIn_Insert]
ON [fiac].[PaymentIn]
AFTER INSERT,UPDATE
AS
BEGIN
    /*
        Trigger Purpose:
        ----------------
        Automatically allocate newly inserted receipts against pending bills
        (from [fiac].[PaymentPending], which unions Sale + SaleDbnote).

        Allocation is FIFO (oldest bills first, by Dt then docId).
        Supports multiple rows inserted into PaymentIn in one batch.
    */
    SET NOCOUNT ON;

	IF CONTEXT_INFO() = 0x1234
    RETURN;
	SET CONTEXT_INFO 0x1234;

	IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        DELETE pa
        FROM [fiac].[PaymentInAdjustment] pa
        WHERE pa.payId IN (SELECT d.payId FROM deleted d);
    END;

    ;WITH PendingBills AS
    (
        SELECT 
            b.docId,
            b.vtype,
            b.lcode,
            b.Dt      AS billDt,
            b.unadjusted AS billRemain,

            i.payId,
            i.amount AS payAmount,
            i.Dt     AS payDt,

            ROW_NUMBER() OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId) AS rn,
            SUM(b.unadjusted) OVER (PARTITION BY i.payId ORDER BY b.Dt, b.docId ROWS UNBOUNDED PRECEDING) AS RunningBillTotal
        FROM inserted i
        JOIN [fiac].[PaymentPending] b 
            ON b.lcode = i.lcode
        WHERE b.unadjusted > 0
    ),
    Allocation AS
    (
        SELECT 
            pb.payId,
            pb.docId,
            pb.vtype,
            CASE 
                WHEN pb.payAmount >= pb.RunningBillTotal 
                     THEN pb.billRemain                            -- full bill gets cleared
                WHEN pb.payAmount <= pb.RunningBillTotal - pb.billRemain 
                     THEN 0                                        -- nothing allocated
                ELSE pb.payAmount - (pb.RunningBillTotal - pb.billRemain) -- partial allocation
            END AS AllocatedAmount
        FROM PendingBills pb
    )
    INSERT INTO [fiac].[PaymentInAdjustment] (payId, docId, vtype, adjustAmt)
    SELECT payId, docId, vtype, AllocatedAmount
    FROM Allocation
    WHERE AllocatedAmount > 0;

	SET CONTEXT_INFO 0x0;
END;
GO

CREATE OR ALTER TRIGGER [fiac].[tr_PaymentInAdjustment_Audit]
ON [fiac].[PaymentInAdjustment]
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    /*
        Trigger Purpose:
        ----------------
        Keep adjAmount columns in sync whenever adjustments are
        inserted, deleted, or updated in [fiac].[PaymentInAdjustment].

        - On INSERT: increment adjAmount in Sale/SaleDbnote and PaymentIn
        - On DELETE: decrement adjAmount
        - On UPDATE: handle both directions by netting differences
    */
    SET NOCOUNT ON;

    -----------------------------------------------------------------
    -- DELETE: Roll back adjustments that are being removed
    -----------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        -- Sale
        UPDATE s
        SET s.adjAmount = s.adjAmount - d.totalAdj
        FROM [sales].[Sale] s
        INNER JOIN (
            SELECT docId, SUM(adjustAmt) AS totalAdj
            FROM deleted
            WHERE vtype = 'I'
            GROUP BY docId
        ) d ON s.docId = d.docId;

        -- SaleDbnote
        UPDATE dnote
        SET dnote.adjAmount = dnote.adjAmount - d.totalAdj
        FROM [sales].[SaleDbnote] dnote
        INNER JOIN (
            SELECT docId, SUM(adjustAmt) AS totalAdj
            FROM deleted
            WHERE vtype = 'D'
            GROUP BY docId
        ) d ON dnote.docId = d.docId;

        -- PaymentIn
        UPDATE pi
        SET pi.adjAmount = pi.adjAmount - d.totalAdj
        FROM [fiac].[PaymentIn] pi
        INNER JOIN (
            SELECT payId, SUM(adjustAmt) AS totalAdj
            FROM deleted
            GROUP BY payId
        ) d ON pi.payId = d.payId;
    END;

    -----------------------------------------------------------------
    -- INSERT: Apply new adjustments
    -----------------------------------------------------------------
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        -- Sale
        UPDATE s
        SET s.adjAmount = s.adjAmount + i.totalAdj
        FROM [sales].[Sale] s
        INNER JOIN (
            SELECT docId, SUM(adjustAmt) AS totalAdj
            FROM inserted
            WHERE vtype = 'I'
            GROUP BY docId
        ) i ON s.docId = i.docId;

        -- SaleDbnote
        UPDATE dnote
        SET dnote.adjAmount = dnote.adjAmount + i.totalAdj
        FROM [sales].[SaleDbnote] dnote
        INNER JOIN (
            SELECT docId, SUM(adjustAmt) AS totalAdj
            FROM inserted
            WHERE vtype = 'D'
            GROUP BY docId
        ) i ON dnote.docId = i.docId;

        -- PaymentIn
        UPDATE pi
        SET pi.adjAmount = pi.adjAmount + i.totalAdj
        FROM [fiac].[PaymentIn] pi
        INNER JOIN (
            SELECT payId, SUM(adjustAmt) AS totalAdj
            FROM inserted
            GROUP BY payId
        ) i ON pi.payId = i.payId;
    END;
END;
GO

CREATE OR ALTER PROCEDURE [fiac].[uspAddPaymentIn]
    @json NVARCHAR(MAX),
    @STATUS NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 61001, 'Input JSON is required.', 1;
        IF ISJSON(@json) <> 1
            THROW 61002, 'Invalid JSON format.', 1;

        DECLARE @Input TABLE
        (
            RowNo    INT IDENTITY(1,1) PRIMARY KEY,
            Dt       DATE,
            lcode    VARCHAR(10),
			dbCode   VARCHAR(10),
            amount   DECIMAL(18,2),
            mop      VARCHAR(1),
            refNo    VARCHAR(30),
            refDate  DATE,
            narration VARCHAR(200)
        );

        INSERT INTO @Input (Dt, lcode, dbCode, amount, mop, refNo, refDate, narration)
        SELECT j.Dt, j.lcode, j.dbCode, j.amount, j.mop, j.refNo, j.refDate, j.narration
        FROM OPENJSON(@json)
        WITH (
            Dt DATE '$.Dt',
            lcode VARCHAR(10) '$.lcode',
			dbCode VARCHAR(10) '$.dbCode',
            amount DECIMAL(18,2) '$.amount',
            mop VARCHAR(1) '$.mop',
            refNo VARCHAR(30) '$.refNo',
            refDate DATE '$.refDate',
            narration VARCHAR(200) '$.narration'
        ) AS j;

        -- Required fields
        IF EXISTS (SELECT 1 FROM @Input WHERE Dt IS NULL OR lcode IS NULL OR dbCode IS NULL OR amount IS NULL OR mop IS NULL)
            THROW 61003, 'Mandatory fields missing (Dt, lcode, amount, mop).', 1;

        -- Payload duplicate validation (within JSON input)
        IF EXISTS (
            SELECT 1
            FROM @Input
            GROUP BY Dt, lcode, dbCode, amount, mop, refNo, refDate, narration
            HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(
                CONCAT(
                    '(', ISNULL(CONVERT(VARCHAR(10), Dt, 120),'NULL'), ', ',
                          ISNULL(lcode,'NULL'), ', ',
						  ISNULL(dbCode,'NULL'), ', ',
                          ISNULL(CONVERT(VARCHAR(30), amount), 'NULL'), ', ',
                          ISNULL(mop,'NULL'), ', ',
                          ISNULL(refNo,'NULL'), ', ',
                          ISNULL(CONVERT(VARCHAR(10), refDate,120),'NULL'), ', ',
                          ISNULL(narration,'NULL'), ')'
                ), '; '
            )
            FROM (
                SELECT Dt, lcode, dbCode, amount, mop, refNo, refDate, narration
                FROM @Input
                GROUP BY Dt, lcode, dbCode,amount, mop, refNo, refDate, narration
                HAVING COUNT(*) > 1
            ) d;

            SET @STATUS = 'Duplicate rows found in JSON input: ' + ISNULL(@dup,'');
            THROW 61004, @STATUS, 1;
        END;

        -- Foreign key validation: lcode must exist
        IF EXISTS (
            SELECT 1
            FROM @Input i
            LEFT JOIN mastcode.LedgerCodes l ON i.lcode = l.lcode
            WHERE l.lcode IS NULL
        )
        BEGIN
            DECLARE @badLcode NVARCHAR(MAX);
            SELECT @badLcode = STRING_AGG(t.lcode, ', ')
            FROM (
                SELECT DISTINCT i.lcode
                FROM @Input i
                LEFT JOIN mastcode.LedgerCodes l ON i.lcode = l.lcode
                WHERE l.lcode IS NULL
            ) t;

            SET @STATUS = 'Invalid lcode (not found in LedgerCodes): ' + ISNULL(@badLcode,'');
            THROW 61005, @STATUS, 1;
        END;

        -- Foreign key validation: dbCode must exist
        IF EXISTS (
            SELECT 1
            FROM @Input i
            LEFT JOIN mastcode.LedgerCodes l ON i.dbCode = l.lcode
            WHERE l.lcode IS NULL
        )
        BEGIN
            DECLARE @baddbCode NVARCHAR(MAX);
            SELECT @baddbCode = STRING_AGG(t.dbCode, ', ')
            FROM (
                SELECT DISTINCT i.dbCode
                FROM @Input i
                LEFT JOIN mastcode.LedgerCodes l ON i.dbCode = l.lcode
                WHERE l.lcode IS NULL
            ) t;

            SET @STATUS = 'Invalid dbCode (not found in LedgerCodes): ' + ISNULL(@baddbCode,'');
            THROW 61005, @STATUS, 1;
        END;

		-- Action Begin
        BEGIN TRAN;

            INSERT INTO [fiac].[PaymentIn] (Dt, lcode, dbCode, amount, mop, refNo, refDate, narration)
            SELECT Dt, lcode, dbCode, amount, mop, refNo, refDate, narration
            FROM @Input;

            SET @STATUS = CONCAT('SUCCESS: ', @@ROWCOUNT, ' row(s) inserted.');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        SET @STATUS = ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [fiac].[uspUpdatePaymentIn]
    @json NVARCHAR(MAX),
    @STATUS NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 62001, 'Input JSON is required.', 1;

        IF ISJSON(@json) <> 1
            THROW 62002, 'Invalid JSON format.', 1;

        DECLARE @Input TABLE
        (
            RowNo INT IDENTITY(1,1) PRIMARY KEY,
            payId BIGINT,
            Dt DATE,
            lcode VARCHAR(10),
			dbCode VARCHAR(10),
            amount DECIMAL(18,2),
            mop VARCHAR(1),
            refNo VARCHAR(30),
            refDate DATE,
            narration VARCHAR(200)
        );

        INSERT INTO @Input (payId, Dt, lcode, dbCode, amount, mop, refNo, refDate, narration)
        SELECT j.payId, j.Dt, j.lcode, j.dbCode, j.amount, j.mop, j.refNo, j.refDate, j.narration
        FROM OPENJSON(@json)
        WITH (
            payId BIGINT '$.payId',
            Dt DATE '$.Dt',
            lcode VARCHAR(10) '$.lcode',
			dbCode VARCHAR(10) '$.dbCode',
            amount DECIMAL(18,2) '$.amount',
            mop VARCHAR(1) '$.mop',
            refNo VARCHAR(30) '$.refNo',
            refDate DATE '$.refDate',
            narration VARCHAR(200) '$.narration'
        ) AS j;

        -- Ensure payId present
        IF EXISTS (SELECT 1 FROM @Input WHERE payId IS NULL)
            THROW 62003, 'payId is required for update.', 1;

        -- Duplicate payId in payload
        IF EXISTS (
            SELECT 1
            FROM @Input
            GROUP BY payId
            HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(CAST(payId AS VARCHAR(20)), ', ')
            FROM (
                SELECT payId FROM @Input GROUP BY payId HAVING COUNT(*) > 1
            ) d;
            SET @STATUS = 'Duplicate payId in input: ' + ISNULL(@dup,'');
            THROW 62006, @STATUS, 1;
        END;

        -- Check existence of payId
        IF EXISTS (
            SELECT i.payId
            FROM @Input i
            LEFT JOIN [fiac].[PaymentIn] p ON i.payId = p.payId
            WHERE p.payId IS NULL
        )
        BEGIN
            DECLARE @bad NVARCHAR(MAX);
            SELECT @bad = STRING_AGG(CAST(i.payId AS VARCHAR(20)), ', ')
            FROM @Input i
            LEFT JOIN [fiac].[PaymentIn] p ON i.payId = p.payId
            WHERE p.payId IS NULL;

            SET @STATUS = 'Invalid payId (not found): ' + ISNULL(@bad,'');
            THROW 62004, @STATUS, 1;
        END;

        -- Check FK if lcode provided
        IF EXISTS (
            SELECT 1 FROM @Input i
            WHERE i.lcode IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM mastcode.LedgerCodes l WHERE l.lcode = i.lcode)
        )
        BEGIN
			DECLARE @badLcode NVARCHAR(MAX);
			SELECT @badLcode = STRING_AGG(x.lcode, ', ')
			FROM (
			SELECT DISTINCT i.lcode
			FROM @Input i
			WHERE i.lcode IS NOT NULL
			AND NOT EXISTS (SELECT 1 FROM mastcode.LedgerCodes l WHERE l.lcode = i.lcode)
			) x;

            SET @STATUS = 'Invalid lcode in input: ' + ISNULL(@badLcode,'');
            THROW 62005, @STATUS, 1;
        END;

		-- Check FK if dbCode provided
        IF EXISTS (
            SELECT 1 FROM @Input i
            WHERE i.dbCode IS NOT NULL
              AND NOT EXISTS (SELECT 1 FROM mastcode.LedgerCodes l WHERE l.lcode = i.dbCode)
        )
        BEGIN
			DECLARE @baddbCode NVARCHAR(MAX);
			SELECT @baddbCode = STRING_AGG(x.dbCode, ', ')
			FROM (
			SELECT DISTINCT i.dbCode
			FROM @Input i
			WHERE i.dbCode IS NOT NULL
			AND NOT EXISTS (SELECT 1 FROM mastcode.LedgerCodes l WHERE l.lcode = i.dbCode)
			) x;

            SET @STATUS = 'Invalid dbCode in input: ' + ISNULL(@baddbCode,'');
            THROW 62005, @STATUS, 1;
        END;
        BEGIN TRAN;

            UPDATE p
            SET
                p.Dt = ISNULL(i.Dt, p.Dt),
                p.lcode = ISNULL(i.lcode, p.lcode),
				p.dbCode = ISNULL(i.dbCode, p.dbCode),
                p.amount = ISNULL(i.amount, p.amount),
                p.mop = ISNULL(i.mop, p.mop),
                p.refNo = ISNULL(i.refNo, p.refNo),
                p.refDate = ISNULL(i.refDate, p.refDate),
                p.narration = ISNULL(i.narration, p.narration)
            FROM [fiac].[PaymentIn] p
            JOIN @Input i ON p.payId = i.payId;

            SET @STATUS = CONCAT('SUCCESS: ', @@ROWCOUNT, ' row(s) updated.');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
		EXECUTE [dbo].[uspLogError];
        SET @STATUS = ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [fiac].[uspDeletePaymentIn]
    @json NVARCHAR(MAX),
    @STATUS NVARCHAR(200) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 63001, 'Input JSON is required.', 1;

        IF ISJSON(@json) <> 1
            THROW 63002, 'Invalid JSON format.', 1;

        DECLARE @Input TABLE (RowNo INT IDENTITY(1,1) PRIMARY KEY, payId BIGINT NULL);

        INSERT INTO @Input (payId)
        SELECT j.payId
        FROM OPENJSON(@json)
        WITH ( payId BIGINT '$.payId' ) j;

        IF EXISTS (SELECT 1 FROM @Input WHERE payId IS NULL)
            THROW 63003, 'payId is required for delete.', 1;

        -- Duplicate payId in payload
        IF EXISTS (
            SELECT 1 FROM @Input GROUP BY payId HAVING COUNT(*) > 1
        )
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(CAST(payId AS VARCHAR(20)), ', ')
            FROM (SELECT payId FROM @Input GROUP BY payId HAVING COUNT(*) > 1) d;

            SET @STATUS = 'Duplicate payId in input: ' + ISNULL(@dup,'');
            THROW 63005, @STATUS, 1;
        END;

        -- Existence check
        IF EXISTS (
            SELECT i.payId FROM @Input i
            LEFT JOIN [fiac].[PaymentIn] p ON i.payId = p.payId
            WHERE p.payId IS NULL
        )
        BEGIN
            DECLARE @bad NVARCHAR(MAX);
            SELECT @bad = STRING_AGG(CAST(i.payId AS VARCHAR(20)), ', ')
            FROM @Input i
            LEFT JOIN [fiac].[PaymentIn] p ON i.payId = p.payId
            WHERE p.payId IS NULL;

            SET @STATUS = 'Invalid payId (not found): ' + ISNULL(@bad,'');
            THROW 63004, @STATUS, 1;
        END;

        BEGIN TRAN;

            DELETE p
            FROM [fiac].[PaymentIn] p
            JOIN @Input i ON p.payId = i.payId;

            SET @STATUS = CONCAT('SUCCESS: ', @@ROWCOUNT, ' row(s) deleted.');

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        SET @STATUS = ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetPaymentIn]
    @json NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 64001, 'Input JSON is required.', 1;

        IF LEFT(LTRIM(@json),1) = '['
            THROW 64002, 'Array JSON not allowed. Pass single object.', 1;

        IF ISJSON(@json) <> 1
            THROW 64003, 'Invalid JSON format.', 1;

        DECLARE @payId BIGINT, @fromDate DATE, @toDate DATE, @lcode VARCHAR(10);

        SELECT @payId = j.payId, @fromDate = j.fromDate, @toDate = j.toDate, @lcode = j.lcode
        FROM OPENJSON(@json)
        WITH (
            payId BIGINT '$.payId',
            fromDate DATE '$.fromDate',
            toDate DATE '$.toDate',
            lcode VARCHAR(10) '$.lcode'
        ) j;

        IF @payId IS NULL
		BEGIN
			IF @fromDate IS NULL OR @toDate IS NULL
				THROW 64004, 'Both fromDate and toDate are required.', 1;
		END

        SELECT p.payId, p.Dt, [mastcode].[ufGetIDate](p.Dt) dDt, p.lcode,lc.lname, p.dbCode, dblc.lname dbName, p.amount, p.mop,
               p.refNo, p.refDate, p.narration, p.adjAmount, p.unadjusted
        FROM [fiac].[PaymentIn] p
		INNER JOIN [mastcode].[LedgerCodes] lc ON p.lcode = lc.lcode
		INNER JOIN [mastcode].[LedgerCodes] dblc ON p.dbCode = dblc.lcode
        WHERE (@payId IS NULL OR p.payId = @payId)
          AND (@lcode IS NULL OR p.lcode = @lcode)
          AND (@fromDate IS NULL OR p.Dt >= @fromDate)
          AND (@toDate IS NULL OR p.Dt <= @toDate)
        ORDER BY p.Dt, p.payId;
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER VIEW [fiac].[PaymentKotak]
AS
SELECT pot.payId,pot.Dt,co.clientCode,co.productCode,NULL bc1,NULL bc2,CONVERT(VARCHAR(10),Dt,103) AS transDate,NULL bc3,NULL bc4,pot.amount,NULL bc5,NULL bc6,LEFT(lc.lname,40) benName,NULL bc7,lc.ifscCode,lc.bankAcNo,
NULL bc8,NULL bc9,NULL bc10,NULL bc11,NULL bc12,NULL bc13,NULL bc14,lc.email,lc.phone AS benMobile,CAST(payId AS VARCHAR(10)) + ' ' + LEFT(lc.lname,20) AS dbnarration,CAST(payId AS VARCHAR(10)) + ' ' + LEFT(lc.lname,20) AS crnarration,
NULL bc15,NULL bc16,NULL bc17,NULL bc18,NULL bc19,NULL bc20,NULL bc21,NULL bc22,NULL bc23,NULL bc24,NULL bc25,NULL bc26,NULL bc27,NULL bc28,NULL bc29,NULL bc30,NULL bc31,NULL bc32,NULL bc33,NULL bc34,NULL bc35,NULL bc36,NULL bc37,NULL bc38,pot.payStatus FROM [fiac].[PaymentOut] pot 
INNER JOIN [mastcode].[LedgerCodes] lc ON pot.lcode = lc.lcode
CROSS APPLY [mastcode].[Company] co
GO

CREATE OR ALTER VIEW [fiac].[PaymentHdfc]
AS
SELECT pot.payId,pot.Dt,'N' AS transType,NULL bc1,lc.bankAcNo,pot.amount,LEFT(lc.lname,40) benName,
NULL bc2,NULL bc3,NULL bc4,NULL bc5,NULL bc6,NULL bc7,NULL bc8,NULL bc9,CAST(payId AS VARCHAR(10)) + ' ' + LEFT(lc.lname,9) AS crefno,
NULL bc10,NULL bc11,NULL bc12,NULL bc13,NULL bc14,NULL bc15,NULL bc16,NULL bc17,CONVERT(VARCHAR(10),pot.Dt,103) AS transDate,NULL bc18, 
lc.ifscCode,lc.bankName,lc.bankName bankBranch,lc.email,pot.payStatus FROM [fiac].[PaymentOut] pot  
INNER JOIN [mastcode].[LedgerCodes] lc ON pot.lcode = lc.lcode 
GO

CREATE OR ALTER PROCEDURE [fiac].[GetPaymentKotak]
(
	@json NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @transDate DATETIME
	SELECT @transDate = transDate FROM OPENJSON(@json,'$')
	WITH (
		transDate DATETIME '$.transDate'
		)qo
	SELECT clientCode, productCode, bc1, bc2, transDate, bc3, bc4, amount, bc5, bc6, benName, bc7, ifscCode, bankAcNo, bc8, bc9, bc10, bc11, bc12, bc13, bc14, email, benMobile, dbnarration, crnarration, bc15, bc16, bc17, bc18, bc19, bc20, bc21, bc22, bc23, bc24, bc25, bc26, bc27, bc28, bc29, bc30, bc31, bc32, bc33, bc34, bc35, bc36, bc37, bc38 FROM [fiac].[PaymentKotak]
	WHERE Dt = @transDate AND payStatus IS NULL;

	UPDATE [fiac].[PaymentOut] SET payStatus = 'U' WHERE Dt = @transDate AND payStatus IS NULL;
END
GO

CREATE OR ALTER PROCEDURE [fiac].[GetPaymentHdfc]
(
	@json NVARCHAR(MAX)
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @transDate DATETIME
	SELECT @transDate = transDate FROM OPENJSON(@json,'$')
	WITH (
		transDate DATETIME '$.transDate'
		)qo
	SELECT transType, bc1, bankAcNo, amount, benName, bc2, bc3, bc4, bc5, bc6, bc7, bc8, bc9, crefno, bc10, bc11, bc12, bc13, bc14, bc15, bc16, bc17, transDate, bc18, ifscCode, bankName, bankBranch, email FROM [fiac].[PaymentHdfc]
	WHERE Dt = @transDate AND payStatus IS NULL;
	
	UPDATE [fiac].[PaymentOut] SET payStatus = 'U' WHERE Dt = @transDate AND payStatus IS NULL;
END
GO

CREATE VIEW [fiac].[BankStatementPending]
AS
SELECT transId,transDate,[mastcode].[ufGetIDate](transDate) dtransDate,bs.lcode,lc.lname,lc.city,lc.stateName,bs.bankCode,transDescription,refNumber,valueDate,deposit,bs.naration FROM [fiac].[BankStatement] bs 
INNER JOIN [mastcode].[ViLedgerCodes] lc ON bs.lcode = lc.lcode
LEFT OUTER JOIN [fiac].[PaymentIn] pin ON bs.transId = pin.bankTransId
WHERE ISNULL(deposit,0) > 0 
	AND bs.lcode IS NOT NULL 
	AND pin.bankTransId IS NULL 
GO

IF OBJECT_ID(N'fiac.uspAddOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspAddOpening];
GO

CREATE PROCEDURE [fiac].[uspAddOpening]
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 50001, 'Input JSON is required.', 1;

        DECLARE @data NVARCHAR(MAX) =
            CASE WHEN LEFT(LTRIM(@json),1) = '[' THEN @json ELSE CONCAT('[', @json, ']') END;

        IF ISJSON(@data) <> 1
            THROW 50002, 'Invalid JSON.', 1;

        DECLARE @Input TABLE
        (
            RowNo   INT IDENTITY(1,1) PRIMARY KEY,
            lcode   VARCHAR(10) NOT NULL,
            Fy      VARCHAR(9)  NOT NULL,
            DrAmt   DECIMAL(18,2) NULL,
            CrAmt   DECIMAL(18,2) NULL
        );

        INSERT INTO @Input (lcode, Fy, DrAmt, CrAmt)
        SELECT j.lcode, j.Fy, j.DrAmt, j.CrAmt
        FROM OPENJSON(@data,'$')
        WITH (
            lcode VARCHAR(10) '$.lcode',
            Fy    VARCHAR(9)  '$.Fy',
            DrAmt DECIMAL(18,2) '$.DrAmt',
            CrAmt DECIMAL(18,2) '$.CrAmt'
        ) AS j;

        DECLARE @msg NVARCHAR(MAX);

        -- Required fields
        IF EXISTS (SELECT 1 FROM @Input WHERE lcode IS NULL OR Fy IS NULL)
        BEGIN
            SET @msg = 'lcode and Fy are required.';
            THROW 50003, @msg, 1;
        END

        -- Duplicate in payload
        IF EXISTS (SELECT lcode, Fy FROM @Input GROUP BY lcode, Fy HAVING COUNT(*) > 1)
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(CONCAT(lcode,'-',Fy), ', ')
            FROM (
                SELECT lcode,Fy FROM @Input GROUP BY lcode,Fy HAVING COUNT(*) > 1
            ) d;
            SET @msg = 'Duplicate (lcode,Fy) in payload: ' + ISNULL(@dup,'');
            THROW 50004, @msg, 1;
        END

        -- Foreign key check: FY must exist
        IF EXISTS (
            SELECT 1 FROM @Input i
            LEFT JOIN [mastcode].[FinancialYear] f ON i.Fy = f.Fy
            WHERE f.Fy IS NULL
        )
        BEGIN
            DECLARE @badFy NVARCHAR(MAX);
            SELECT @badFy = STRING_AGG(t.Fy, ', ')
            FROM (
                SELECT DISTINCT i.Fy
                FROM @Input i
                LEFT JOIN [mastcode].[FinancialYear] f ON i.Fy = f.Fy
                WHERE f.Fy IS NULL
            ) AS t(Fy);
            SET @msg = 'Invalid Fy (not found in FinancialYear): ' + ISNULL(@badFy,'');
            THROW 50005, @msg, 1;
        END

        -- Already exists in table
        IF EXISTS (
            SELECT 1 FROM @Input i
            JOIN [fiac].[Opening] o ON o.lcode = i.lcode AND o.Fy = i.Fy
        )
        BEGIN
            DECLARE @exists NVARCHAR(MAX);
            SELECT @exists = STRING_AGG(CONCAT(x.lcode,'-',x.Fy), ', ')
            FROM (
                SELECT DISTINCT i.lcode,i.Fy
                FROM @Input i
                JOIN [fiac].[Opening] o ON o.lcode = i.lcode AND o.Fy = i.Fy
            ) x;
            SET @msg = 'Opening already exists for: ' + ISNULL(@exists,'');
            THROW 50006, @msg, 1;
        END

        BEGIN TRAN;

            INSERT INTO [fiac].[Opening] (lcode, Fy, DrAmt, CrAmt)
            SELECT lcode, Fy, DrAmt, CrAmt FROM @Input;

            SET @STATUS = @@ROWCOUNT;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        EXEC dbo.uspLogError;
        SET @STATUS = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'fiac.uspUpdateOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspUpdateOpening];
GO

CREATE PROCEDURE [fiac].[uspUpdateOpening]
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 51011, 'Input JSON is required.', 1;

        DECLARE @data NVARCHAR(MAX) =
            CASE WHEN LEFT(LTRIM(@json),1) = '[' THEN @json ELSE CONCAT('[', @json, ']') END;

        IF ISJSON(@data) <> 1
            THROW 51012, 'Invalid JSON.', 1;

        DECLARE @Input TABLE
        (
            RowNo   INT IDENTITY(1,1) PRIMARY KEY,
            lcode   VARCHAR(10) NOT NULL,
            Fy      VARCHAR(9)  NOT NULL,
            DrAmt   DECIMAL(18,2) NULL,
            CrAmt   DECIMAL(18,2) NULL
        );

        INSERT INTO @Input (lcode, Fy, DrAmt, CrAmt)
        SELECT j.lcode, j.Fy, j.DrAmt, j.CrAmt
        FROM OPENJSON(@data,'$')
        WITH (
            lcode VARCHAR(10) '$.lcode',
            Fy    VARCHAR(9)  '$.Fy',
            DrAmt DECIMAL(18,2) '$.DrAmt',
            CrAmt DECIMAL(18,2) '$.CrAmt'
        ) AS j;

        DECLARE @msg NVARCHAR(MAX);

        -- Required fields
        IF EXISTS (SELECT 1 FROM @Input WHERE lcode IS NULL OR Fy IS NULL)
        BEGIN
            SET @msg = 'lcode and Fy are required for update.';
            THROW 51013, @msg, 1;
        END

        -- Duplicate in payload
        IF EXISTS (SELECT lcode,Fy FROM @Input GROUP BY lcode,Fy HAVING COUNT(*) > 1)
        BEGIN
            DECLARE @dup NVARCHAR(MAX);
            SELECT @dup = STRING_AGG(CONCAT(lcode,'-',Fy), ', ')
            FROM (
                SELECT lcode,Fy FROM @Input GROUP BY lcode,Fy HAVING COUNT(*) > 1
            ) d;
            SET @msg = 'Duplicate (lcode,Fy) in update payload: ' + ISNULL(@dup,'');
            THROW 51014, @msg, 1;
        END

        -- Not exists in table
        IF EXISTS (
            SELECT 1 FROM @Input i
            LEFT JOIN [fiac].[Opening] o ON o.lcode = i.lcode AND o.Fy = i.Fy
            WHERE o.ObId IS NULL
        )
        BEGIN
            DECLARE @notFound NVARCHAR(MAX);
            SELECT @notFound = STRING_AGG(CONCAT(m.lcode,'-',m.Fy), ', ')
            FROM (
                SELECT DISTINCT i.lcode,i.Fy
                FROM @Input i
                LEFT JOIN [fiac].[Opening] o ON o.lcode = i.lcode AND o.Fy = i.Fy
                WHERE o.ObId IS NULL
            ) m;
            SET @msg = 'Opening not found for update: ' + ISNULL(@notFound,'');
            THROW 51015, @msg, 1;
        END

        BEGIN TRAN;

            UPDATE o
            SET o.DrAmt = COALESCE(i.DrAmt, o.DrAmt),
                o.CrAmt = COALESCE(i.CrAmt, o.CrAmt)
            FROM [fiac].[Opening] o
            JOIN @Input i ON o.lcode = i.lcode AND o.Fy = i.Fy;

            SET @STATUS = @@ROWCOUNT;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        EXEC dbo.uspLogError;
        SET @STATUS = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'fiac.uspDeleteOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspDeleteOpening];
GO

CREATE PROCEDURE [fiac].[uspDeleteOpening]
    @json NVARCHAR(MAX),
    @STATUS INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
            THROW 51021, 'Input JSON is required.', 1;

        DECLARE @data NVARCHAR(MAX) =
            CASE WHEN LEFT(LTRIM(@json),1) = '[' THEN @json ELSE CONCAT('[', @json, ']') END;

        IF ISJSON(@data) <> 1
            THROW 51022, 'Invalid JSON.', 1;

        DECLARE @Input TABLE
        (
            lcode   VARCHAR(10) NOT NULL,
            Fy      VARCHAR(9)  NOT NULL
        );

        INSERT INTO @Input (lcode,Fy)
        SELECT j.lcode, j.Fy
        FROM OPENJSON(@data,'$')
        WITH (
            lcode VARCHAR(10) '$.lcode',
            Fy    VARCHAR(9)  '$.Fy'
        ) AS j;

        DECLARE @msg NVARCHAR(MAX);

        IF EXISTS (SELECT 1 FROM @Input WHERE lcode IS NULL OR Fy IS NULL)
        BEGIN
            SET @msg = 'lcode and Fy are required for delete.';
            THROW 51023, @msg, 1;
        END

        BEGIN TRAN;

            DELETE o
            FROM [fiac].[Opening] o
            JOIN @Input i ON i.lcode = o.lcode AND i.Fy = o.Fy;

            SET @STATUS = @@ROWCOUNT;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRAN;
        EXEC dbo.uspLogError;
        SET @STATUS = 0;
        THROW;
    END CATCH
END
GO

IF OBJECT_ID(N'fiac.uspGetOpening',N'P') IS NOT NULL
	DROP PROCEDURE [fiac].[uspGetOpening];
GO

CREATE OR ALTER PROCEDURE [fiac].[uspGetOpening]
    @json NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @data NVARCHAR(MAX);

        IF @json IS NULL OR LTRIM(RTRIM(@json)) = ''
        BEGIN
            SELECT o.*
            FROM [fiac].[Opening] o
            ORDER BY o.ObId;
            RETURN;
        END

        -- Check array or Single
        SET @data = CASE WHEN LEFT(LTRIM(@json),1) = '[' THEN @json ELSE CONCAT('[', @json, ']') END;

        IF ISJSON(@data) <> 1
            THROW 52001, 'Invalid JSON input.', 1;

        DECLARE @Filter TABLE
        (
            ObId    BIGINT NULL,
            lcode   VARCHAR(10) NULL,
            Fy      VARCHAR(9)  NULL
        );

        INSERT INTO @Filter (ObId, lcode, Fy)
        SELECT j.ObId, j.lcode, j.Fy
        FROM OPENJSON(@data,'$')
        WITH (
            ObId  BIGINT      '$.ObId',
            lcode VARCHAR(10) '$.lcode',
            Fy    VARCHAR(9)  '$.Fy'
        ) j;

        -- Return matching rows
        SELECT o.* FROM [fiac].[Opening] o
        INNER JOIN @Filter f ON (f.ObId IS NULL OR o.ObId = f.ObId)
           AND (f.lcode IS NULL OR o.lcode = f.lcode)
           AND (f.Fy IS NULL OR o.Fy = f.Fy)
        ORDER BY o.ObId;
    END TRY
    BEGIN CATCH
        EXEC dbo.uspLogError;
        THROW;
    END CATCH
END
GO
