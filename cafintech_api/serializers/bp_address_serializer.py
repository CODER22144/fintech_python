from rest_framework import serializers

class BusinessPartnerAddressSerializer(serializers.Serializer):
   bpaCode = serializers.IntegerField(allow_null=True, required=False)
   bpCode = serializers.CharField(max_length = 10)
   bpaName = serializers.CharField(max_length = 100)
   bpaAdd = serializers.CharField(max_length = 100)
   bpaAdd1 = serializers.CharField(max_length = 100, allow_null=True, required=False)
   bpaCity = serializers.CharField(max_length = 50)
   bpaState = serializers.IntegerField()
   bpaZipCode = serializers.CharField(max_length = 6)
   bpaCountry = serializers.CharField(max_length = 2)
   bpaPhone = serializers.CharField(max_length = 10)
   bpaGSTIN = serializers.CharField(max_length = 15, allow_null=True, required=False)