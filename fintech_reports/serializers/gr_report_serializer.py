from rest_framework import serializers

class GrReportSerializer(serializers.Serializer):
    brid = serializers.IntegerField(allow_null=True, required=False)
    grno = serializers.IntegerField(allow_null=True, required=False)
    fromDate = serializers.CharField(allow_null=True, required=False, max_length=20)
    toDate = serializers.CharField(allow_null=True, required=False, max_length=20)