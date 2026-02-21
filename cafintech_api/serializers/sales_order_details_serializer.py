from rest_framework import serializers

class SaleOrderDetailSerializer(serializers.Serializer):
    No = serializers.CharField(max_length = 30,allow_null=True, required = False)
    IgstOnIntra = serializers.CharField(max_length=1, allow_null=True, required=False)
    PrdDesc = serializers.CharField(max_length=300, allow_null=True, required=False)
    HsnCd = serializers.CharField(max_length=8, allow_null=True, required=False)
    Qty = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    UnitPrice = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    Unit = serializers.CharField(max_length=8, allow_null=True, required=False)
    TotAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    Discount = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    AssAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    GstRt = serializers.DecimalField(max_digits=6, decimal_places=2, required=False, allow_null=True)
    GstAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
