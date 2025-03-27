from rest_framework import serializers

class JobWorkoutReportSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=30, allow_null=True, required=False)
    tdate = serializers.CharField(max_length=30, allow_null=True, required=False)