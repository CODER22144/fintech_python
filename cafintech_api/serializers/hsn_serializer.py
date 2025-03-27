from rest_framework import serializers

class HsnSerializer(serializers.Serializer):
    hsnCode = serializers.CharField(max_length=10)
    hsnShortDescription = serializers.CharField(max_length=50)
    hsnDescription = serializers.CharField(max_length=500)
    isService = serializers.CharField(max_length=1)
    gstTaxRate = serializers.DecimalField(max_digits=5, decimal_places=2)
