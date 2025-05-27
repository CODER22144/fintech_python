from rest_framework import serializers

class MaterialAssemblyProcessingSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    wpId = serializers.IntegerField()
    orderBy = serializers.IntegerField()
    rId = serializers.IntegerField()
    rQty = serializers.IntegerField()
    dayProduction = serializers.IntegerField()

