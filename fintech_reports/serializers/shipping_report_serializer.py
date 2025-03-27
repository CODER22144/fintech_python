from rest_framework import serializers

class ShippingReportSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=20, allow_null=True, required=False)
