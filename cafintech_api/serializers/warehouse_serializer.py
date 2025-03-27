from rest_framework import serializers

class WarehouseSerializer(serializers.Serializer):
   whcode = serializers.CharField(max_length = 5)
   whName = serializers.CharField(max_length = 50)
   whAdd = serializers.CharField(max_length = 100)
   whAdd1 = serializers.CharField(max_length = 100)
   whCity = serializers.CharField(max_length = 50)
   whState = serializers.IntegerField()
   whZipCode = serializers.CharField(max_length = 6)
   whCountry = serializers.CharField(max_length = 2)
   whContactPerson = serializers.CharField(max_length = 50)
   whPhone = serializers.CharField(max_length = 12)