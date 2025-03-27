from rest_framework import serializers

class MaterialIqsSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length = 15)
    iqsn = serializers.IntegerField()
    testType = serializers.CharField(max_length = 30)
    testItem = serializers.CharField(max_length = 30)
    testName = serializers.CharField(max_length = 20)
    lowerLimit = serializers.CharField(max_length = 20)
    higherLimit = serializers.CharField(max_length = 20)
