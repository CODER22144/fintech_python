from rest_framework import serializers

class ProductBreakupSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    sDescription = serializers.CharField(max_length=100)
    lDescription = serializers.CharField(max_length=100, allow_null=True, required=False)
    listRate = serializers.DecimalField(max_digits=12, decimal_places=3)
    mrp = serializers.DecimalField(max_digits=12, decimal_places=3)
    oemRate = serializers.DecimalField(max_digits=12, decimal_places=3)
    stdPack = serializers.IntegerField()
    mstPack = serializers.IntegerField()
    jamboPack = serializers.IntegerField()
    revisionNo = serializers.CharField(max_length=10, allow_null=True, required=False)
    grossWeight = serializers.DecimalField(max_digits=12, decimal_places=3)
    netWeight = serializers.DecimalField(max_digits=12, decimal_places=3)
    csId = serializers.CharField(max_length=2)
    remarks = serializers.CharField(max_length=200, allow_null=True, required=False)

    processing = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    rejection = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    icc = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    overhead = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
    profit = serializers.DecimalField(max_digits=5, decimal_places=2, default=0)
