from rest_framework import serializers

class InwardDetailSerializer(serializers.Serializer):
    naration = serializers.CharField(max_length=50, allow_null=True, required=False)
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3) 
    rate = serializers.DecimalField(max_digits=12, decimal_places=3)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discType = serializers.CharField(max_length=1, default='N', allow_null=True, required=False, allow_blank=True)          # Drop Down [mastcode].[DiscountPercentType](discType)
    rdisc = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    discountAmount = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    bcd = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    roff = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
    rcess = serializers.DecimalField(max_digits=12, decimal_places=2)
    cessAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    rgst = serializers.DecimalField(max_digits=12, decimal_places=2)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    tcsAmount = serializers.DecimalField(max_digits=12, decimal_places=2)
    tamount = serializers.DecimalField(max_digits=12, decimal_places=2) 


