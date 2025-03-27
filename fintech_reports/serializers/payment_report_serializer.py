from rest_framework import serializers

class PaymentReportSerializer(serializers.Serializer):
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=30, allow_null=True, required=False)
