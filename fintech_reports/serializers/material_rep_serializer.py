from rest_framework import serializers

class MaterialRepSerializer(serializers.Serializer):
    materialType = serializers.CharField(max_length=2)
    materialGroup = serializers.CharField(max_length=5, allow_null=True, required = False)
    gstTaxRate = serializers.DecimalField(max_digits=5, decimal_places=2, allow_null=True, required = False)
    hsnCode = serializers.CharField(max_length=10, allow_null=True, required = False)
    mst = serializers.CharField(max_length=1, allow_null=True, required = False)
    fmatno = serializers.CharField(max_length=15, allow_null=True, required = False)
    tmatno = serializers.CharField(max_length=15, allow_null=True, required = False)
    fdoentry = serializers.CharField(max_length=20, allow_null=True, required = False)
    tdoentry = serializers.CharField(max_length=20, allow_null=True, required = False)

