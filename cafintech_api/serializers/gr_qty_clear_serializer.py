from rest_framework import serializers

class GrQtyClearSerializer(serializers.Serializer):
    grdId = serializers.IntegerField()
    recqty = serializers.DecimalField(max_digits=12, decimal_places=3)
    rejqty = serializers.DecimalField(max_digits=12, decimal_places=3)