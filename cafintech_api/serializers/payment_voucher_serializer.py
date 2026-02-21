from rest_framework import serializers

class PaymentVoucherSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=16, allow_null=True, required=False)
    Dt = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10)
    naration = serializers.CharField(max_length=100)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    AssAmt = serializers.DecimalField(max_digits=15, decimal_places=3)
    GstRt = serializers.DecimalField(max_digits=5, decimal_places=2)
    gstAmount = serializers.DecimalField(max_digits=15, decimal_places=3)
    mop = serializers.CharField(max_length=20, allow_null=True, required=False)
    payRefno = serializers.CharField(max_length=20, allow_null=True, required=False)
