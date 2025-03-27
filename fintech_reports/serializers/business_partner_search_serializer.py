from rest_framework import serializers

class BusinessPartnerSearchSerializer(serializers.Serializer):
    bpName = serializers.CharField(max_length = 100)
    bpCity = serializers.CharField(max_length = 50, allow_null=True, required = False)
    bpPhone = serializers.CharField(max_length = 10, allow_null=True, required = False)
