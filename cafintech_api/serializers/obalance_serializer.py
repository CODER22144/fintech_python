from rest_framework import serializers

class OBalanceSerializer(serializers.Serializer):
    obId = serializers.CharField(max_length=1)
    lcode = serializers.CharField(max_length=10)
    billNo = serializers.CharField(max_length=30, required = False, allow_null = True)
    billDate = serializers.CharField(max_length=20, required = False, allow_null = True)
    naration = serializers.CharField(max_length=100, required = False, allow_null = True)
    balId = serializers.CharField(max_length = 1)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, default = 0)
