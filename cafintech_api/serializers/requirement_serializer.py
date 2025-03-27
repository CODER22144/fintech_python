from rest_framework import serializers

class RequirementSerializer(serializers.Serializer):
    dcode = serializers.IntegerField()
    rtId = serializers.CharField(max_length=1)
    mode = serializers.CharField(max_length=1)
    matno = serializers.CharField(max_length=15, required=False, allow_null=True)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3, default=0)
