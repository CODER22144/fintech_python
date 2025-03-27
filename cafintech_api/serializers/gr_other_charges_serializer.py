from rest_framework import serializers

class GrOtherChargesSerializer(serializers.Serializer):
    grno = serializers.IntegerField()
    chargeName = serializers.CharField(max_length=30)
    hsnCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    gstTaxRate = serializers.DecimalField(max_digits=12, decimal_places=3)
    gstAmount = serializers.DecimalField(max_digits=12, decimal_places=3)
    tAmount = serializers.DecimalField(max_digits=12, decimal_places=3)