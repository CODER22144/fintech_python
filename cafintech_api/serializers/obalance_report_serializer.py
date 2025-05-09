from rest_framework import serializers

class OBalanceReportSerializer(serializers.Serializer):
    obId = serializers.CharField(max_length=1, required=False, allow_null=True)
    lcode = serializers.CharField(max_length=10, required=False, allow_null=True)
