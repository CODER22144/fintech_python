from rest_framework import serializers

class SalesReportSerializer(serializers.Serializer):
    igstOnIntra = serializers.CharField(max_length=1, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
    
