from rest_framework import serializers

class JournalVoucherSerializer(serializers.Serializer):
    transId = serializers.IntegerField(required=False, allow_null=True)
    Dt = serializers.CharField(max_length = 20)
    dbCode = serializers.CharField(max_length = 10)
    crCode = serializers.CharField(max_length = 10)
    naration = serializers.CharField(max_length = 100)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3)
    DocProof = serializers.CharField(max_length = 100, required=False, allow_null=True)
