from rest_framework import serializers

class PaymentSerializer(serializers.Serializer):
    # tdate = serializers.CharField(max_length=20)
    # payType = serializers.CharField(max_length=1)
    mop = serializers.CharField(max_length=1)
    lcode = serializers.CharField(max_length=10)
    crdrCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3)
    naration = serializers.CharField(max_length=100, allow_null=True, required=False)
    transId = serializers.IntegerField()
    vtype = serializers.CharField(max_length=1)