from rest_framework import serializers

class MaterialAssemblyDetailsSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    partno = serializers.CharField(max_length=15)
    qty = serializers.DecimalField(max_digits=12, decimal_places=5)
    pLength = serializers.DecimalField(max_digits=12, decimal_places=2)
    unit = serializers.CharField(max_length=8)
    tno = serializers.IntegerField()
    rmType = serializers.CharField(max_length=2)
