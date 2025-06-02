from rest_framework import  serializers

class BPObMaterialReportSerializer(serializers.Serializer):
    fmatno = serializers.CharField(max_length=15, allow_null=True, required=False)
    tmatno = serializers.CharField(max_length=15, allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)

