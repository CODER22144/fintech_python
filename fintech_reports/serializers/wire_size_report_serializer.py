from rest_framework import serializers

class WireSizeReportSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    repId = serializers.CharField(max_length=1)
    soId = serializers.CharField(max_length=10)

