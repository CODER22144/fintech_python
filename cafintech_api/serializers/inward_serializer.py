from rest_framework import serializers

class InwardSerializer(serializers.Serializer):
    transDate = serializers.CharField(max_length=20)
    brId = serializers.IntegerField()
    grno = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)            #Drop Down [mastcode].[LedgerCodes](lcode),
    billNo = serializers.CharField(max_length=30, allow_null=True, required=False)
    billDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    tdsCode = serializers.CharField(max_length=10, allow_null=True, required=False) # Drop Down [mastcode].[tdsType](tdsCode),
    rtds = serializers.DecimalField(max_digits=5, decimal_places=2, default=0) # Auto Populate from tdsCode Dropdown
    tcs = serializers.CharField(max_length=1)       #  Drop Down [mastcode].[YesNo](yn) 
    dbCode = serializers.CharField(max_length=10)   #  Drop Down [mastcode].[LedgerCodes](lcode),
    slId = serializers.CharField(max_length=2)      #  [mastcode].[SupplyType](slId),
    stId = serializers.CharField(max_length=1)      # [mastcode].[SupplierType](stId),
    rc = serializers.CharField(max_length=1)        #  [mastcode].[YesNo](yn)  
    DocProof = serializers.CharField(max_length=255, allow_null=True, required=False)
