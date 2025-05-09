from rest_framework import serializers

class OrderBalanceSerializer(serializers.Serializer):
    orderId = serializers.IntegerField(allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
