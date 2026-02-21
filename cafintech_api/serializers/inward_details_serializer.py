from rest_framework import serializers

class InwardDetailSerializer(serializers.Serializer):
    transId = serializers.IntegerField(allow_null=True, required=False)
    naration = serializers.CharField(max_length=50)
    matno = serializers.CharField(max_length=15)
    hsnCode = serializers.CharField(max_length=10)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3) 
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    unit = serializers.CharField(max_length=8, allow_null=True, required=False)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    roff = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    GstRt = serializers.DecimalField(max_digits=12, decimal_places=2)
    GstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    CesRt = serializers.DecimalField(max_digits=6, decimal_places=3, allow_null=True, required=False)
    CesAmt = serializers.DecimalField(max_digits=15, decimal_places=3, allow_null=True, required=False)
    Bcd = serializers.DecimalField(max_digits=15, decimal_places=3, allow_null=True, required=False)


class InwardVoucherDetailSerializer(serializers.Serializer):
    transId = serializers.IntegerField(allow_null=True, required=False)
    naration = serializers.CharField(max_length=50)
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3) 
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    unit = serializers.CharField(max_length=8, allow_null=True, required=False)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    roff = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    GstRt = serializers.DecimalField(max_digits=12, decimal_places=2)
    GstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)