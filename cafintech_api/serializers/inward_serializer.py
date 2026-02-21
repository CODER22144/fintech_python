from rest_framework import serializers

from cafintech_api.serializers.inward_details_serializer import InwardDetailSerializer

class InwardSerializer(serializers.Serializer):
    transId = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)            #Drop Down [mastcode].[LedgerCodes](lcode),
    billNo = serializers.CharField(max_length=30, allow_null=True, required=False)
    billDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    tdsCode = serializers.CharField(max_length=10, allow_null=True, required=False) # Drop Down [mastcode].[tdsType](tdsCode),
    rtds = serializers.DecimalField(max_digits=5, decimal_places=2, default=0) # Auto Populate from tdsCode Dropdown
    dbCode = serializers.CharField(max_length=10)   #  Drop Down [mastcode].[LedgerCodes](lcode),
    rc = serializers.CharField(max_length=1)        #  [mastcode].[YesNo](yn)  
    brId = serializers.IntegerField(allow_null=True, required=False)
    naration = serializers.CharField(max_length=255, allow_null=True, required=False) 
    InwardDetails = InwardDetailSerializer(many=True)
    
    # naration = serializers.CharField(max_length=255, allow_null=True, required=False)
    # rate = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    # hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    # qty = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # amount = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # discountAmount = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # GstRt = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # GstAmount = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # roff = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # tamount = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
    # igstOnIntra = serializers.CharField(max_length=1, allow_null=True, required=False)
    # transDate = serializers.CharField(max_length=20)
    # grno = serializers.IntegerField(allow_null=True, required=False)
    # tcs = serializers.CharField(max_length=1)       #  Drop Down [mastcode].[YesNo](yn) 
    # slId = serializers.CharField(max_length=2)      #  [mastcode].[SupplyType](slId),
    # stId = serializers.CharField(max_length=1)      # [mastcode].[SupplierType](stId),
    # DocProof = serializers.CharField(max_length=255, allow_null=True, required=False)

