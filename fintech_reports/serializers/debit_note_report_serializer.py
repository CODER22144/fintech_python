from rest_framework import serializers

class DebitNoteReportSerializer(serializers.Serializer):
    docId = serializers.IntegerField(allow_null=True, required=False)
    No = serializers.CharField(max_length=16, allow_null=True, required=False)
    RegRev = serializers.CharField(max_length=1, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    FDt = serializers.CharField(max_length=20)
    TDt = serializers.CharField(max_length=20)
