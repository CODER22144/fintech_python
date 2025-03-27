from rest_framework import serializers

class PurchaseOrderReportSerializer(serializers.Serializer):
    poId = serializers.IntegerField(allow_null=True, required=False)
    fromDate = serializers.CharField(allow_null=True, required=False, max_length=20)
    toDate = serializers.CharField(allow_null=True, required=False, max_length=20)
