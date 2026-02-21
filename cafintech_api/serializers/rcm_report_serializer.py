from rest_framework import serializers

class RcmReportSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=16, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    IgstOnIntra = serializers.CharField(max_length=1, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
