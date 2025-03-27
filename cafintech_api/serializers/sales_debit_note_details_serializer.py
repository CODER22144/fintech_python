from rest_framework import serializers

class SaleDbNoteDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length = 15, allow_null=True, required=False)
    naration = serializers.CharField(max_length = 50, allow_null=True, required=False)
    hsnCode = serializers.CharField(max_length = 10, allow_null=True, required=False)
    billNo = serializers.CharField(max_length = 20, allow_null=True, required=False)
    billDate = serializers.CharField(max_length = 20, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    rate = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discType = serializers.CharField(max_length=1, default='N', allow_null=True, required=False, allow_blank=True)
    rdisc = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    rcess = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    cessAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    rgst = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    roff = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)