from rest_framework import serializers

class InwardBillReportSeralizer(serializers.Serializer):
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=30, allow_null=True, required=False)
    vtype = serializers.CharField(max_length=1, allow_null=True, required=False)
    slId = serializers.CharField(max_length=2, allow_null=True, required=False)
    stId = serializers.CharField(max_length=1, allow_null=True, required=False)
    rc = serializers.CharField(max_length=1, allow_null=True, required=False)
