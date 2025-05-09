from rest_framework import serializers

class ReqIssuePendingSerializer(serializers.Serializer):
    dcode = serializers.IntegerField(allow_null=True, required=False)
    rtId = serializers.CharField(max_length=1, allow_null=True, required=False)
    reqId = serializers.IntegerField(allow_null=True, required=False)
    matno = serializers.CharField(max_length=15, allow_null=True, required=False)
    fromDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    toDate = serializers.CharField(max_length=20, allow_null=True, required=False)
