from rest_framework import serializers

class UnadjustedPaymentInwardClearSerializer(serializers.Serializer):
    payVtype = serializers.CharField(max_length=1)
    payTransId = serializers.IntegerField()
    transId = serializers.IntegerField()
    vtype = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    clnaration = serializers.CharField(max_length=100, allow_null=True, required=False)

