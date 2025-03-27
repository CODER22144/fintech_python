from rest_framework import serializers

class SaleOrderDetailSerializer(serializers.Serializer):
    icode = serializers.CharField(max_length=50)
    qty = serializers.IntegerField()