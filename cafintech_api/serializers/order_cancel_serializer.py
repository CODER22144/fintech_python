from rest_framework import serializers

class OrderCancelSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    cancelledDate = serializers.CharField(max_length=20)
    cancelledReason = serializers.CharField(max_length=100)
