from rest_framework import serializers

class WireSizeSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    matDrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    jointDrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    csId = serializers.CharField(max_length=2)