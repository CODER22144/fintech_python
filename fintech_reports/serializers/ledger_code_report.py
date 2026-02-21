from rest_framework import serializers

class LedgerCodeReportSerializer(serializers.Serializer):
    lstatus = serializers.CharField(max_length=1, allow_null=True, required=False)
    lname = serializers.CharField(max_length=50, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    stateCode = serializers.IntegerField(allow_null=True, required=False)
    supplyType = serializers.CharField(max_length=1, allow_null=True, required=False)


class LedgerReportSerializer(serializers.Serializer):
    lname = serializers.CharField(max_length=50, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fy = serializers.CharField(max_length=9, allow_null=True, required=False)
    legalName = serializers.CharField(max_length=100, allow_null=True, required=False)
    compAdd = serializers.CharField(max_length=100, allow_null=True, required=False)
    compAdd1 = serializers.CharField(max_length=100, allow_null=True, required=False)
    compCity = serializers.CharField(max_length=50, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    
