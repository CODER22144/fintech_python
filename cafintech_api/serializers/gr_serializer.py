from rest_framework import serializers

class GRSerializer(serializers.Serializer):
    grDate = serializers.CharField(max_length = 20)
    brid = serializers.CharField(max_length = 20)
    it = serializers.CharField(max_length = 2, default="I")
    bpCode = serializers.CharField(max_length = 15)
    billNo = serializers.CharField(max_length = 16)
    billDate = serializers.CharField(max_length = 20)
