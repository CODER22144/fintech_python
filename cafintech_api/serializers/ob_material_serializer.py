from rest_framework import serializers

class OBMaterialSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    chrDescription = serializers.CharField(max_length=500)
    brate = serializers.DecimalField(max_digits=10, decimal_places=3)
    srate = serializers.DecimalField(max_digits=10, decimal_places=3)
    muUnit = serializers.CharField(max_length=8)
    rmType = serializers.CharField(max_length=2)
    materialGroup = serializers.CharField(max_length=2)
    mrp = serializers.CharField(max_length=2)
    oerate = serializers.CharField(max_length=2)
