from rest_framework import serializers

from cafintech_api.serializers.inward_details_serializer import InwardVoucherDetailSerializer

class InwardVoucherSerializer(serializers.Serializer):
    transId = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length = 10)
    brId = serializers.IntegerField(allow_null=True, required=False)
    billNo = serializers.CharField(max_length = 30,allow_null=True, required = False)
    billDate = serializers.CharField(max_length = 20,allow_null=True, required = False)
    dbCode = serializers.CharField(max_length = 10)
    rc = serializers.CharField(max_length=1)
    rtds = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    tdsCode = serializers.CharField(max_length=10)
    DocProof = serializers.CharField(allow_null=True, required = False)
    naration = serializers.CharField(max_length=255, allow_null=True, required=False)
    InwardVoucherDetails = InwardVoucherDetailSerializer(many=True)

class InwardVoucherSingleSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length = 10)
    billNo = serializers.CharField(max_length = 30,allow_null=True, required = False)
    billDate = serializers.CharField(max_length = 20,allow_null=True, required = False)
    naration = serializers.CharField(max_length=255, allow_null=True, required=False)
    dbCode = serializers.CharField(max_length = 10)
    rc = serializers.CharField(max_length=1)
    tdsCode = serializers.CharField(max_length=10)
    rtds = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    DocProof = serializers.CharField(allow_null=True, required = False)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=3)
    GstRt = serializers.DecimalField(max_digits=12, decimal_places=2)
    GstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    roff = serializers.DecimalField(max_digits=12, decimal_places=3)
    tamount = serializers.DecimalField(max_digits=12, decimal_places=3)

    # transId = serializers.IntegerField(allow_null=True, required=False)
    # brId = serializers.IntegerField(allow_null=True, required=False)