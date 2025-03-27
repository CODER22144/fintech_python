from rest_framework import serializers

class JobWorkOutDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=50)
    qty = serializers.IntegerField()