from rest_framework import serializers

class SaleOrderDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=10, allow_null=True, required=False)
    Qty = serializers.DecimalField(max_digits=15, decimal_places=3)




    # sidId = serializers.IntegerField()
    # No = serializers.CharField(max_length=16)
    # # Barcde = serializers.CharField(max_length=20, allow_null=True, required=False)
    # matno = serializers.CharField(max_length=20)
    # PrdDesc = serializers.CharField(max_length=300)
    # HsnCd = serializers.CharField(max_length=8)
    # Qty = serializers.DecimalField(max_digits=15, decimal_places=3)
    # UnitPrice = serializers.DecimalField(max_digits=15, decimal_places=3)
    # Unit = serializers.CharField(max_length=8)
    # TotAmt = serializers.DecimalField(max_digits=15, decimal_places=3)
    # Discount = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True, default=0)
    # AssAmt = serializers.DecimalField(max_digits=15, decimal_places=3)
    # GstRt = serializers.DecimalField(max_digits=6, decimal_places=2)
    # IgstAmt = serializers.DecimalField(max_digits=15, decimal_places=3)
    # CgstAmt = serializers.DecimalField(max_digits=15, decimal_places=3)
    # SgstAmt = serializers.DecimalField(max_digits=15, decimal_places=3)

    # CesRt = serializers.DecimalField(max_digits=6, decimal_places=3, required=False, allow_null=True, default=0)
    # CesAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True, default=0)
    # CesNonAdvlAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True, default=0)
    # StateCesRt = serializers.DecimalField(max_digits=6, decimal_places=3, required=False, allow_null=True, default=0)
    # StateCesAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True, default=0)
    # StateCesNonAdvlAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True, default=0)
    # FreeQty = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, default=0)
    # FreeUnitPrice = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, default=0)

    # TotItemVal = serializers.SerializerMethodField()

    # def get_TotItemVal(self, obj):
    #     return (
    #         (obj.get('AssAmt', 0) or 0)
    #         + (obj.get('IgstAmt', 0) or 0)
    #         + (obj.get('CgstAmt', 0) or 0)
    #         + (obj.get('SgstAmt', 0) or 0)
    #         + (obj.get('CesAmt', 0) or 0)
    #         + (obj.get('CesNonAdvlAmt', 0) or 0)
    #         + (obj.get('StateCesAmt', 0) or 0)
    #         + (obj.get('StateCesNonAdvlAmt', 0) or 0)
    #     )


