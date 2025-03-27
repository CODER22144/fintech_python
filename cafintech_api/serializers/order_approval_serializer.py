from rest_framework import serializers

class OrderApprovalSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    approval = serializers.CharField(max_length=1)
    reasonDenied = serializers.CharField(max_length=100, allow_null=True, required=False)
