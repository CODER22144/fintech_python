from rest_framework import serializers

class JobWorkOutSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    jpId = serializers.CharField(max_length=2)
    goodsType = serializers.CharField(max_length=1)
    reqId = serializers.IntegerField(required=False, allow_null=True)
    matnoReturn = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
    transMode = serializers.CharField(required=False, allow_null=True, max_length=1)
    carId = serializers.IntegerField(required=False, allow_null=True)
    grNo = serializers.CharField(required=False, allow_null=True, max_length=25)
    grDate = serializers.CharField(required=False, allow_null=True, max_length=30)
    vehicleNo = serializers.CharField(required=False, allow_null=True, max_length=15)
    ewbno = serializers.CharField(required=False, allow_null=True, max_length=15)