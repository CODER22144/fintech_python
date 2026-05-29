from rest_framework import serializers

class TrialBalanceReportSerializer(serializers.Serializer):
    fDate = serializers.CharField(max_length=20, required=True)
    toDate = serializers.CharField(max_length=20, required=True)
    agCode = serializers.CharField(required=False, allow_null=True, max_length=5)