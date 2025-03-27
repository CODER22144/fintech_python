from rest_framework import serializers

class GrDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length = 100)
    poId = serializers.CharField(max_length = 100)
    grQty = serializers.CharField(max_length = 100)
    grRate = serializers.CharField(max_length = 100)
    hsnCode = serializers.CharField(max_length = 100)
