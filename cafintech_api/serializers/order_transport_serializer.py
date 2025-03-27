from rest_framework import serializers

class OrderTransportSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    grno = serializers.CharField(max_length=30)
    grDate = serializers.CharField(max_length=20)
    carrierName = serializers.CharField(max_length=50)
    freight = serializers.DecimalField(max_digits=10, decimal_places=2)
    grUrl = serializers.CharField(max_length=255)
