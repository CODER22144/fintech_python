from rest_framework import serializers

class ReqProductionSerializer(serializers.Serializer):
    reqId = serializers.IntegerField()
    matno = serializers.CharField(max_length=15)
    prqty = serializers.IntegerField(default=0)
    reqty = serializers.IntegerField(default=0)
