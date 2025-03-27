from rest_framework import serializers

class ReceiptVoucherSerializer(serializers.Serializer):
    rvno = serializers.IntegerField()
    tDate = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10)
    slId = serializers.CharField(max_length=2)
    naration = serializers.CharField(max_length=100)
    hsnCode = serializers.CharField(max_length=100)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    rgst = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)