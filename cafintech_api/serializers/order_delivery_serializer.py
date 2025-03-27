from rest_framework import serializers

class OrderDeliverySerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    signedBy = serializers.CharField(max_length=50)
    signedByPhone = serializers.CharField(max_length=10)
    dcopyUrl = serializers.CharField(max_length=255)
