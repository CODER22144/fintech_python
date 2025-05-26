from rest_framework import serializers

class GrItemReportSerializer(serializers.Serializer):
    bpCode = serializers.CharField(allow_null=True, required=False, max_length=10)
    billno = serializers.CharField(allow_null=True, required=False, max_length=16)
    frommatno = serializers.CharField(allow_null=True, required=False, max_length=15)
    tomatno = serializers.CharField(allow_null=True, required=False, max_length=15)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)

