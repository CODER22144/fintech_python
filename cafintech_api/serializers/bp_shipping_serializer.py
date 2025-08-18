from rest_framework import serializers

class BpShippingSerializer(serializers.Serializer):
    shipCode = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)
    Gstin = serializers.CharField(max_length=15, allow_null=True, required=False)
    LglNm = serializers.CharField(max_length=100)
    Addr1 = serializers.CharField(max_length=100)
    Addr2 = serializers.CharField(max_length=100, allow_null=True, required=False)
    Loc = serializers.CharField(max_length=50)
    Stcd = serializers.IntegerField()
    Pin = serializers.CharField(max_length=6)
    CntCode = serializers.CharField(max_length=2)
    Phone = serializers.CharField(max_length=10, allow_null=True, required=False)
