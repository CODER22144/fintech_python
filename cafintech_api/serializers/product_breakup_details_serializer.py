from rest_framework import serializers

class ProductBreakupDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    partNo = serializers.CharField(max_length=15)
    qty = serializers.DecimalField(decimal_places=5, max_digits=12)
    pLength = serializers.DecimalField(decimal_places=5, max_digits=12, allow_null=True, required = False)
    unit = serializers.CharField(max_length=8, allow_null=True, required = False)
    tno = serializers.IntegerField(allow_null=True, required = False)
    rmType = serializers.CharField(max_length=2)