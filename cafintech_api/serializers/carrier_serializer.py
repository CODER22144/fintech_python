from rest_framework import serializers

class CarrierSerializer(serializers.Serializer):
    carId = serializers.IntegerField()
    carName = serializers.CharField(max_length=50)
    carGSTIN = serializers.CharField(max_length=15, allow_null=True, required=False)
    carAdd = serializers.CharField(max_length=100)
    carAdd1 = serializers.CharField(max_length=100, allow_null=True, required=False)
    carCity = serializers.CharField(max_length=50)
    carStateName = serializers.CharField(max_length=50)
    carZipCode = serializers.CharField(max_length=6)
    carCPerson = serializers.CharField(max_length=50, allow_null=True, required=False)
    carPhone = serializers.CharField(max_length=30, allow_null=True, required=False)