from rest_framework import serializers

class MaterialSourceRepSerializer(serializers.Serializer):
    fmatno = serializers.CharField(max_length=15)
    tmatno = serializers.CharField(max_length=15)
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    rateType = serializers.CharField(max_length=1, allow_null=True, required=False)