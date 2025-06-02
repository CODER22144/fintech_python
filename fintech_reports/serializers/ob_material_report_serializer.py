from rest_framework import serializers

class OBMaterialReportSerializer(serializers.Serializer):
    fmatno = serializers.CharField(max_length=15, allow_null=True, required=False)
    tmatno = serializers.CharField(max_length=15, allow_null=True, required=False)
    materialGroup = serializers.CharField(max_length=5, allow_null=True, required=False)

