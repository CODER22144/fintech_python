from rest_framework import serializers

class TDSReportSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    tdsCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)

