from rest_framework import serializers

class EvOrderSerializer(serializers.Serializer):
    poId = serializers.IntegerField()
    validUpTo = serializers.CharField(max_length = 20)
    remark = serializers.CharField(max_length = 100)