from rest_framework import serializers

class AdditionalOrderSerializer(serializers.Serializer):
    poId = serializers.IntegerField()
    matno = serializers.CharField(max_length = 15)
    hsnCode = serializers.CharField(max_length = 10, allow_null=True, required=False)
    poQty = serializers.DecimalField(max_digits=12, decimal_places=2)
    poRate = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True, required=False)
    remark = serializers.CharField(max_length = 100)