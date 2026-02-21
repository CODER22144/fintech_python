from rest_framework import serializers

class ReportSerializer(serializers.Serializer):
    userId = serializers.CharField(allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    bt = serializers.CharField(max_length=1, allow_null=True, required=False)
    repType = serializers.CharField(max_length=1)
    brid = serializers.IntegerField(allow_null=True, required=False)