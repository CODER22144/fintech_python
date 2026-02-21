from rest_framework import serializers

class JobWorkoutReportSerializer(serializers.Serializer):
    igstOnIntra = serializers.CharField(max_length=2, allow_null=True, required=False),    
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=30, allow_null=True, required=False)
    tdate = serializers.CharField(max_length=30, allow_null=True, required=False)