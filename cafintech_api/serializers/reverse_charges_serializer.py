from rest_framework import serializers

class ReverseChargesSerializer(serializers.Serializer):
    docDate = serializers.CharField(max_length=20)
    transId = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)
    billNo = serializers.CharField(max_length=30)
    billDate = serializers.CharField(max_length=20)
    slId = serializers.CharField(max_length=2)
    stId = serializers.CharField(max_length=1)
    naration = serializers.CharField(max_length=50, allow_null=True, required=False)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    rgst = serializers.DecimalField(max_digits=12, decimal_places=2)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
