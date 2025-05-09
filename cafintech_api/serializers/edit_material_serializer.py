from rest_framework import serializers

class EditMaterialSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    prate = serializers.DecimalField(max_digits=12, decimal_places=3, allow_null=True, required=False)
    saleDescription = serializers.CharField(max_length=50, allow_null=True, required=False)
    mrp = serializers.DecimalField(max_digits=12, decimal_places=2)
    listPrice = serializers.DecimalField(max_digits=12, decimal_places=2)

