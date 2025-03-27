from rest_framework import serializers

class ReqPackedSerializer(serializers.Serializer):
    packId = serializers.IntegerField()
    matno = serializers.CharField(max_length=15)
    pkdqty = serializers.IntegerField()
