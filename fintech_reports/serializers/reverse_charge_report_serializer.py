from rest_framework import serializers

class ReverseChargeReportSerializer(serializers.Serializer):
    slId = serializers.CharField(max_length=2, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20, allow_null=True, required=False)
    tdate = serializers.CharField(max_length=20, allow_null=True, required=False)


