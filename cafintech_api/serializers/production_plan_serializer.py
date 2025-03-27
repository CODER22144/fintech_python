from rest_framework import serializers

class ProductionPlanSerializer(serializers.Serializer):
    ppId = serializers.CharField(max_length=6)
    matno = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
