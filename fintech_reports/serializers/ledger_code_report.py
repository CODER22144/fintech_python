from rest_framework import serializers

class LedgerCodeReportSerializer(serializers.Serializer):
    lStatus = serializers.CharField(max_length=1, allow_null=True, required=False)
    lName = serializers.CharField(max_length=50, allow_null=True, required=False)
    agCode = serializers.CharField(max_length=5, allow_null=True, required=False)
    lType = serializers.CharField(max_length=1, allow_null=True, required=False)
    slId = serializers.CharField(max_length=2, allow_null=True, required=False)
    stId = serializers.CharField(max_length=1, allow_null=True, required=False)
    tcs = serializers.CharField(max_length=1, allow_null=True, required=False)
    tdsCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    rc = serializers.CharField(max_length=1, allow_null=True, required=False)
