from rest_framework import serializers

class ReverseChargesSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=20, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)
    billNo = serializers.CharField(max_length=30, allow_null=True, required=False)
    billDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    itcEligible = serializers.CharField(max_length=1)
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    naration = serializers.CharField(max_length=100, allow_null=True, required=False)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)
    unit = serializers.CharField(max_length=8)
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    AssAmt = serializers.DecimalField(max_digits=12, decimal_places=2)
    rgst = serializers.DecimalField(max_digits=12, decimal_places=2)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
