from rest_framework import serializers

class BpShippingSerializer(serializers.Serializer):
    shipCode = serializers.IntegerField()
    bpCode = serializers.CharField(max_length = 10)
    shipName = serializers.CharField(max_length = 100)
    shipAdd = serializers.CharField(max_length = 100)
    shipAdd1 = serializers.CharField(max_length = 100, allow_null=True, required=False)
    shipCity = serializers.CharField(max_length = 50)
    shipState = serializers.IntegerField()
    shipZipCode = serializers.CharField(max_length = 6)
    shipCountry = serializers.CharField(max_length = 2)
    shipPhone = serializers.CharField(max_length = 10, allow_null=True, required=False)
    shipGSTIN = serializers.CharField(max_length = 15, allow_null=True, required=False)