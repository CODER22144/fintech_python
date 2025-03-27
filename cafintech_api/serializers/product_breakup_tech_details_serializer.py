from rest_framework import serializers

class ProductBreakupTechDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    pic = serializers.CharField(max_length=100, allow_null=True, required=False)
    drawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    qc = serializers.CharField(max_length=100, allow_null=True, required=False)
    cp = serializers.CharField(max_length=100, allow_null=True, required=False)
    fmea = serializers.CharField(max_length=100, allow_null=True, required=False)
    pfd = serializers.CharField(max_length=100, allow_null=True, required=False)
    ccr = serializers.CharField(max_length=100, allow_null=True, required=False)
