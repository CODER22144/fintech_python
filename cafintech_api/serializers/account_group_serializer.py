from rest_framework import serializers

class AccountGroupSerializer(serializers.Serializer):
    agCode = serializers.CharField(max_length=5)
    agDescription = serializers.CharField(max_length=50)
    mgcode = serializers.CharField(max_length=5, allow_null=True, required=False)
    isTr = serializers.CharField(max_length=1)
    isPl = serializers.CharField(max_length=1)
    isBl = serializers.CharField(max_length=1)
