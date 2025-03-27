from rest_framework import serializers

class ReqPackingSerializer(serializers.Serializer):
    prodId = serializers.IntegerField()
    matno = serializers.CharField(max_length=15)
    pkqty = serializers.IntegerField(default = 0)
