from rest_framework import serializers

class EditMaterialSourceSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    bpCode = serializers.CharField(max_length=10)
    bpRate = serializers.DecimalField(max_digits=12, decimal_places=3)
    rateEf = serializers.CharField(max_length=20)
