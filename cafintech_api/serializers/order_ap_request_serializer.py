from rest_framework import serializers

class OrderApRequestSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    orderValue = serializers.DecimalField(decimal_places=2, max_digits=12)
    remarks = serializers.CharField(max_length=100, allow_null=True, required=False)