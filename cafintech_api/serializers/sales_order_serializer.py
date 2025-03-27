from rest_framework import serializers

class SalesOrderSerializer(serializers.Serializer):
    custCode = serializers.CharField(max_length=10)
    shipCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    carId = serializers.CharField(max_length=10)
    poNo = serializers.CharField(max_length=30, allow_null=True, required=False)
    poDate = serializers.CharField(max_length=30, allow_null=True, required=False)
    transmode = serializers.CharField(max_length=1, allow_null=True, required=False)
    privateMark = serializers.CharField(max_length=20, allow_null=True, required=False)
    mop = serializers.CharField(max_length=1)
    mof = serializers.CharField(max_length=1)
    userId = serializers.CharField(max_length=500, allow_null=True, required=False)
