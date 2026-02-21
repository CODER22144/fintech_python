from rest_framework import serializers

class OBalanceReportSerializer(serializers.Serializer):
    obId = serializers.IntegerField(required=False, allow_null=True)
    lcode = serializers.CharField(max_length=10, required=False, allow_null=True)
    Fy = serializers.CharField(max_length=9, required=False, allow_null=True)
