from rest_framework import serializers

class MaterialIncomingStandardSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    misSno = serializers.IntegerField()
    testType = serializers.CharField(max_length=30)
    isnpItem = serializers.CharField(max_length=30)
    instName = serializers.CharField(max_length=20, allow_null=True, required=False)
    lLimit = serializers.CharField(max_length=40)
    hLimit = serializers.CharField(max_length=40)
