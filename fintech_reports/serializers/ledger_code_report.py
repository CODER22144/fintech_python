from rest_framework import serializers

class LedgerCodeReportSerializer(serializers.Serializer):
    lstatus = serializers.CharField(max_length=1, allow_null=True, required=False)
    lname = serializers.CharField(max_length=50, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    stateCode = serializers.IntegerField(allow_null=True, required=False)
    supplyType = serializers.CharField(max_length=1, allow_null=True, required=False)
    
