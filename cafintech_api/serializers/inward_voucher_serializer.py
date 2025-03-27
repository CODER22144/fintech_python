from rest_framework import serializers

class InwardVoucherSerializer(serializers.Serializer):
    tDate = serializers.CharField(max_length = 20)
    lcode = serializers.CharField(max_length = 10)
    billNo = serializers.CharField(max_length = 30,allow_null=True, required = False)
    billDate = serializers.CharField(max_length = 20, allow_null=True, required = False)
    naration = serializers.CharField(max_length = 100, allow_null=True, required = False)
    dbCode = serializers.CharField(max_length = 10)
    # hsnCode = serializers.CharField(max_length = 10, allow_null=True, required = False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    # discType = serializers.CharField(max_length = 1)
    # rdisc = serializers.DecimalField(max_digits=5, decimal_places=2, default =0)
    # discountAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    # rcess = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    # cessamount = serializers.DecimalField(max_digits=12, decimal_places=2, default = 0)
    # rgst = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    # gstAmount = serializers.DecimalField(max_digits=12, decimal_places=2, default = 0)
    # tcsAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default = 0)
    # roff = serializers.DecimalField(max_digits=5, decimal_places=2, default = 0)
    # tAmount = serializers.DecimalField(max_digits=12, decimal_places=2)

    DocProof = serializers.CharField(allow_null=True, required = False)


# Total Amount  = qty * rate