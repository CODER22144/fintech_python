from rest_framework import serializers

class BusinessPartnerProcessingSerializer(serializers.Serializer):
    bpProId = serializers.IntegerField(allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=10)
    pId = serializers.CharField(max_length=5)
    proDescription = serializers.CharField(max_length=30)
    proRate = serializers.DecimalField(max_digits=12, decimal_places=3)

