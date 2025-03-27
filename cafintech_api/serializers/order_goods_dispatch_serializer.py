from rest_framework import serializers

class OrderGoodsDispatchSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    pkt = serializers.IntegerField()
    weight = serializers.DecimalField(max_digits=12, decimal_places=3)
    vehicleno = serializers.CharField(max_length=15)
    vehtype = serializers.CharField(max_length=1)
    driverName = serializers.CharField(max_length=50)
    driverPhone = serializers.CharField(max_length=10)
