from rest_framework import serializers

class TodSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    periodId = serializers.CharField(max_length=2)
    stateid = serializers.IntegerField()
