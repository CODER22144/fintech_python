from rest_framework import serializers

class OrderPackedSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    pkt = serializers.IntegerField()
    weight = serializers.DecimalField(max_digits=12, decimal_places=3)