from rest_framework import serializers

class LineRejectionSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    matno = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
    # rate = serializers.DecimalField(max_digits=12, decimal_places=3)
