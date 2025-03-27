from rest_framework import serializers

class PartAssemblyProcessingSerializer(serializers.Serializer):
    wpId = serializers.IntegerField()
    orderBy = serializers.IntegerField()
    rId = serializers.IntegerField()
    rQty = serializers.IntegerField()
    dayProduction = serializers.IntegerField()
    matno = serializers.CharField(max_length=15)
