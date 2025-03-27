from rest_framework import serializers

class PurchaseOrderDetailsSerializer(serializers.Serializer):
    podId = serializers.IntegerField(allow_null=True, required=False)
    poId = serializers.IntegerField(allow_null=True, required=False)
    potype = serializers.CharField(max_length=1)
    matno = serializers.CharField(max_length=15)
    poQty = serializers.IntegerField()
    deliveryDate = serializers.CharField(max_length=50)
    priority = serializers.CharField(max_length=1)
