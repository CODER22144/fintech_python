from rest_framework import serializers

class LedgerCodesSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10)
    lTitle = serializers.CharField(max_length=5)
    lName = serializers.CharField(max_length=50)
    agCode = serializers.CharField(max_length=5)
    lType = serializers.CharField(max_length=1)
    slId = serializers.CharField(max_length=2)
    stId = serializers.CharField(max_length=1)
    tdsCode = serializers.CharField(max_length=10)
    lStatus = serializers.CharField(max_length=1)
    lRemark = serializers.CharField(max_length=100, allow_null=True, required=False)
    tcs = serializers.CharField(max_length=1)
    rc = serializers.CharField(max_length=1)
    crdrCode = serializers.CharField(max_length=10,allow_null=True, required=False)