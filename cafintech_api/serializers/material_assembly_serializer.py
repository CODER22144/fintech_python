from rest_framework import serializers

class MaterialAssemblySerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    rmType = serializers.CharField(max_length=2)
    profit = serializers.IntegerField()
    rejection = serializers.IntegerField()
    overhead = serializers.IntegerField()
    processing = serializers.IntegerField()
    pic = serializers.CharField(max_length=100, allow_null=True, required=False)
    drawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required=False)
    revisionNo = serializers.CharField(max_length=10)
    csId = serializers.CharField(max_length=2)
    icc = serializers.IntegerField()

    stdPack = serializers.IntegerField(allow_null=True, required=False)
    mstPack = serializers.IntegerField(allow_null=True, required=False)
    jamboPack = serializers.IntegerField(allow_null=True, required=False)
    grossWeight = serializers.DecimalField(max_digits=10, decimal_places=3, allow_null=True, required=False)
    netWeight = serializers.DecimalField(max_digits=10, decimal_places=3, allow_null=True, required=False)