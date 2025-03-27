from rest_framework import serializers

class MatReportSerializer(serializers.Serializer):
    materialType = serializers.CharField(max_length=2, allow_null=True, required = False)
    materialGroup = serializers.CharField(max_length=5, allow_null=True, required = False)
    fmatno = serializers.CharField(max_length=15, allow_null=True, required = False)
    tmatno = serializers.CharField(max_length=15, allow_null=True, required = False)
    mst = serializers.CharField(max_length=1)
