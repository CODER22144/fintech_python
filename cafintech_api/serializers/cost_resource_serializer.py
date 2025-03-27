from rest_framework import serializers

class CostResourceSerializer(serializers.Serializer):
    rId = serializers.IntegerField()
    rName = serializers.CharField(max_length=30)
    wages = serializers.IntegerField()
