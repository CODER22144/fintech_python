from rest_framework import serializers

class PaymentInwardSerializer(serializers.Serializer):
    mop = serializers.CharField(max_length=1)
    lcode = serializers.CharField(max_length=10)
    crdrCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    naration = serializers.CharField(max_length=100)
