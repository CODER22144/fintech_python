from rest_framework import serializers

class DebitNoteReportSerializer(serializers.Serializer):
    docno = serializers.IntegerField(allow_null=True, required=False)
    drId = serializers.CharField(max_length=2, allow_null=True, required=False)
    daId = serializers.CharField(max_length=2, allow_null=True, required=False)
    slId = serializers.CharField(max_length=2, allow_null=True, required=False)
    stId = serializers.CharField(max_length=1, allow_null=True, required=False)
    bpCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    fdate = serializers.CharField(max_length=20)
    tdate = serializers.CharField(max_length=20)
    invoiceType = serializers.CharField(max_length=30, allow_null=True, required=False)
