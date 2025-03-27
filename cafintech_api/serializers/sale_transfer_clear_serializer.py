from rest_framework import serializers

class SaleTransferClearSerializer(serializers.Serializer):
    stId = serializers.IntegerField()
    transId = serializers.CharField(max_length=50)
    vtype = serializers.CharField(max_length=1)
    lcode = serializers.CharField(max_length=10)
    crdrCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    clnaration = serializers.CharField(max_length=100)
