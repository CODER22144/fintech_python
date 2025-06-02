from rest_framework import serializers

class BpBreakupProcessingSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    matno = serializers.CharField(max_length=15)
    pId = serializers.CharField(max_length=15)
    lqty = serializers.DecimalField(max_digits=10, decimal_places=3)
    