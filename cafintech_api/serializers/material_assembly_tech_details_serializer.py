from rest_framework import serializers

class MaterialAssemblyTechDetailsSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    qc = serializers.CharField(max_length=100, allow_null=True, required=False)
    cp = serializers.CharField(max_length=100, allow_null=True, required=False)
    fmea = serializers.CharField(max_length=100, allow_null=True, required=False)
    pfd = serializers.CharField(max_length=100, allow_null=True, required=False)
    ccr = serializers.CharField(max_length=100, allow_null=True, required=False)

