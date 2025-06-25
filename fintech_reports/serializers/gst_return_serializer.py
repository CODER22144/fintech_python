from rest_framework import serializers

class GSTReturnSerializer(serializers.Serializer):
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    repType = serializers.CharField(max_length=1, required=False, allow_null=True)

