from rest_framework import serializers

class CheckOutSerializer(serializers.Serializer):
    userId = serializers.CharField(max_length = 20, allow_null=True, required=False)
    geoCheckOut = serializers.CharField(max_length = 100)