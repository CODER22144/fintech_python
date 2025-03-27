from rest_framework import serializers

class CheckInSerializer(serializers.Serializer):
    userId = serializers.CharField(max_length = 20, allow_null=True, required=False)
    geoCheckIn = serializers.CharField(max_length = 100)