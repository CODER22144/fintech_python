from rest_framework import serializers

class OrderGoodsDispatchSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=16)
    Dt = serializers.CharField(max_length=20)
    carId = serializers.IntegerField(allow_null=True, required=False)
    mof = serializers.CharField(max_length=1)
    TransMode = serializers.CharField(max_length=1)
    TransId = serializers.CharField(max_length=15,allow_null=True, required=False)
    TransName = serializers.CharField(max_length=100, allow_null=True, required=False)
    Distance = serializers.IntegerField()
    TransDocNo = serializers.CharField(max_length=15, allow_null=True, required=False)
    TransDocDt = serializers.CharField(max_length=20, allow_null=True, required=False)
    VehNo = serializers.CharField(max_length=20)
    VehType = serializers.CharField(max_length=1)

