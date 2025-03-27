from rest_framework import serializers

class DlChallanSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    ctId = serializers.CharField(max_length=1)
    matnoReturn = serializers.CharField(max_length=15, required=False, allow_null=True)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3, required=False, allow_null=True)


class DlChallanDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)
