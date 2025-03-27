from rest_framework import serializers

class MaterialReturnSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
