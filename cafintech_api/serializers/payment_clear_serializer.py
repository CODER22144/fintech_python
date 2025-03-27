from rest_framework import serializers

class PaymentClearSerializer(serializers.Serializer):
    payId = serializers.IntegerField()
    payType = serializers.CharField(max_length=1, allow_null=True, required=False)
    transId = serializers.CharField(max_length=50)
    vtype = serializers.CharField(max_length=1)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    clnaration = serializers.CharField(max_length=100, allow_null=True, required=False)
