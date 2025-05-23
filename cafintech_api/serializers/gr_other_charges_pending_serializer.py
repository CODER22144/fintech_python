from rest_framework import serializers

class GrOtherChargesPendingSerializer(serializers.Serializer):
    repType = serializers.CharField(max_length=1, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)