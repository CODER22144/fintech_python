from rest_framework import serializers

class OrderPackagingSerializer(serializers.Serializer):
    orderId = serializers.IntegerField()
    icode = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
