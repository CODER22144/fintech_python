from rest_framework import serializers

class BpBreakupSerializer(serializers.Serializer):
    bpbId = serializers.IntegerField(allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=10)
    matno = serializers.CharField(max_length=15)
    rmType = serializers.CharField(max_length=2)
    processing = serializers.DecimalField(max_digits=5, decimal_places=2)
    rejection = serializers.DecimalField(max_digits=5, decimal_places=2)
    icc = serializers.DecimalField(max_digits=5, decimal_places=2)
    overhead = serializers.DecimalField(max_digits=5, decimal_places=2)
    profit = serializers.DecimalField(max_digits=5, decimal_places=2)
    pic = serializers.CharField(max_length=100, allow_null=True, required=False)
    drawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    csId = serializers.CharField(max_length=2)

