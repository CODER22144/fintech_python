from rest_framework import serializers

class PartAssemblySerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    pic = serializers.CharField(max_length=100, allow_null=True, required = False)
    drawing = serializers.CharField(max_length=100, allow_null=True, required = False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required = False)
    revisionNo = serializers.CharField(max_length=10, allow_null=True, required = False)
    csId = serializers.CharField(max_length=2)

    processing = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    rejection = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    icc = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    overhead = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    profit = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)