from rest_framework import serializers

class BankStatementSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    type = serializers.CharField(max_length=1, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
