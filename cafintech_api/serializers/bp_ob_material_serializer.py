from rest_framework import serializers

class BusinessPartnerObMaterialSerializer(serializers.Serializer):
    bpmId = serializers.IntegerField(required=False, allow_null=True)
    bpCode = serializers.CharField(max_length=10)
    matno = serializers.CharField(max_length=15)
    chrDescription = serializers.CharField(max_length=500)
    brate = serializers.DecimalField(decimal_places=3, max_digits=10)
    muUnit = serializers.CharField(max_length=8)
