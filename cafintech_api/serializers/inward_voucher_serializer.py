from rest_framework import serializers

class InwardVoucherSerializer(serializers.Serializer):
    # tDate = serializers.CharField(max_length = 20)
    lcode = serializers.CharField(max_length = 10)
    brId = serializers.IntegerField(allow_null=True, required=False)
    billNo = serializers.CharField(max_length = 30,allow_null=True, required = False)
    billDate = serializers.CharField(max_length = 20)
    naration = serializers.CharField(max_length = 100, allow_null=True, required = False)
    dbCode = serializers.CharField(max_length = 10)
    # hsnCode = serializers.CharField(max_length = 10, allow_null=True, required = False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)
    rc = serializers.CharField(max_length=1)
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    GstRt = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    GstAmount = serializers.DecimalField(max_digits=12, decimal_places=2, default = 0)
    tdsAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default = 0)
    roff = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    tamount = serializers.DecimalField(max_digits=12, decimal_places=2)

    DocProof = serializers.CharField(allow_null=True, required = False)


# Total Amount  = qty * rate