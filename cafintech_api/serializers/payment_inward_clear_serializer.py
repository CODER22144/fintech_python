from rest_framework import serializers

class PaymentInwardClearSerializer(serializers.Serializer):
    transId = serializers.IntegerField()
    ptype = serializers.CharField(max_length=10)
    lcode = serializers.CharField(max_length=15)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
