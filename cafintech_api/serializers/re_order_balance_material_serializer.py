from rest_framework import serializers

class ReOrderBalanceMaterialSerializer(serializers.Serializer):
    orderId = serializers.IntegerField(required=False, allow_null=True)
    bpCode = serializers.CharField(max_length=10, required=False, allow_null=True)
    fromDate = serializers.CharField(max_length=20)
    toDate = serializers.CharField(max_length=20)
    userid = serializers.CharField(max_length=50)
    roleid = serializers.CharField(max_length=2)
