from rest_framework import serializers

class ReqIssueSerializer(serializers.Serializer):
    reqId = serializers.IntegerField()
    matno = serializers.CharField(max_length=15)
    qty = serializers.CharField(max_length=30)
