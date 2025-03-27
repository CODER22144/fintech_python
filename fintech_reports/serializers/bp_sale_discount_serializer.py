from rest_framework import serializers

class BpSaleDiscountSerializer(serializers.Serializer):
    bpName = serializers.CharField(max_length=100, allow_null=True, required=False)
    bpState = serializers.IntegerField(allow_null=True, required=False)
    discType = serializers.CharField(max_length=1, allow_null=True, required=False)
    brType = serializers.CharField(max_length=1, allow_null=True, required=False)
