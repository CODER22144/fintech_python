from rest_framework import serializers

class MaterialTechDetailsSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    drawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    images = serializers.CharField(max_length=100, allow_null=True, required=False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    qcformat = serializers.CharField(max_length=100, allow_null=True, required=False)
    cp = serializers.CharField(max_length=100, allow_null=True, required=False)
    fmea = serializers.CharField(max_length=100, allow_null=True, required=False)
    pfd = serializers.CharField(max_length=100, allow_null=True, required=False)
    vendrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    ccr = serializers.CharField(max_length=100, allow_null=True, required=False)

