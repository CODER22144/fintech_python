from rest_framework import serializers

class ManufacturingReportSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)