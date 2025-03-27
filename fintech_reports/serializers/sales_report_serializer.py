from rest_framework import serializers

class SalesReportSerializer(serializers.Serializer):
    invNo = serializers.IntegerField(allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=20, allow_null=True, required=False)
    stateId = serializers.CharField(max_length=50, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    userid = serializers.CharField(max_length=30, allow_null=True, required=False)
    roleid = serializers.CharField(max_length=10, allow_null=True, required=False)
    slId = serializers.CharField(max_length=2, allow_null=True, required=False)
    stId = serializers.CharField(max_length=1, allow_null=True, required=False)
