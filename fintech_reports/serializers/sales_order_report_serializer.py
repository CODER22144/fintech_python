from rest_framework import serializers

class SalesOrderReportSerializer(serializers.Serializer):
    orderId = serializers.IntegerField(allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=20, allow_null=True, required=False)
    stateId = serializers.CharField(max_length=50, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    toDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    userid = serializers.CharField(max_length=30, allow_null=True, required=False)
    roleid = serializers.CharField(max_length=10, allow_null=True, required=False)
