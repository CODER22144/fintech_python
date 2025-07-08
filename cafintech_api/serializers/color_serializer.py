from rest_framework import serializers

class ColorSerializer(serializers.Serializer):
    colNo = serializers.CharField(max_length=8)
    colName = serializers.CharField(max_length=50)
