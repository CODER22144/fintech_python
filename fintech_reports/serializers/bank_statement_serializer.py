from rest_framework import serializers

class BankStatementSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    type = serializers.CharField(max_length=1, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)

class BankTestSerializer(serializers.Serializer):
    lcode  = serializers.CharField(max_length=10)
    acType = serializers.CharField(max_length=1)
    nameInBank = serializers.CharField(max_length=100)