from rest_framework import serializers

class RequirementDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3)