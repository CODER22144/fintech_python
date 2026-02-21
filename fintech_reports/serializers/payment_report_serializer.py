from rest_framework import serializers

class PaymentReportSerializer(serializers.Serializer):
    fdate = serializers.CharField(max_length=20, allow_null=True, required=False)
    tdate = serializers.CharField(max_length=20, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    dbcode = serializers.CharField(max_length=10, allow_null=True, required=False)

class BillPendingSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    iday = serializers.IntegerField(allow_null=True, required=False, default=0)
    stcode = serializers.CharField(max_length=2, allow_null=True, required=False)