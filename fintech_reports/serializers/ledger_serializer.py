from rest_framework import serializers

class LedgerSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10, required=False, allow_null=True)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    agCode = serializers.CharField(max_length=5, required=False, allow_null=True)

