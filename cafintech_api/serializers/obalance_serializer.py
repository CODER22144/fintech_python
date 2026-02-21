from rest_framework import serializers

class OBalanceSerializer(serializers.Serializer):
    ObId = serializers.IntegerField(allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)
    Fy = serializers.CharField(max_length=9)
    DrAmt = serializers.DecimalField(max_digits=18, decimal_places=2)
    CrAmt = serializers.DecimalField(max_digits=18, decimal_places=2)

