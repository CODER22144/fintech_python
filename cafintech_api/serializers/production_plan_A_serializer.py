from rest_framework import serializers

class ProductionPlanASerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    qty = serializers.IntegerField()
    remark = serializers.CharField(max_length=20, allow_null=True, required=False)
