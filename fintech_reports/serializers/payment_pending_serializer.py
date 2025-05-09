from rest_framework import serializers

class PaymentPendingSerializer(serializers.Serializer):
    bpState = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=30, allow_null=True, required=False)
