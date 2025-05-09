from rest_framework import serializers

class ReportSerializer(serializers.Serializer):
    userId = serializers.CharField(allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    brid = serializers.IntegerField(allow_null=True, required=False)