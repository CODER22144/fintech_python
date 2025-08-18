from rest_framework import serializers

class ExportOrderSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=16)
    goodsDescription = serializers.CharField(max_length=100, allow_null=True, required=False)
    termOfDelivery = serializers.CharField(max_length=200, allow_null=True, required=False)
    lutno = serializers.CharField(max_length=30, allow_null=True, required=False)
    portOfLoading = serializers.CharField(max_length=100, allow_null=True, required=False)
    placeOfReceipt = serializers.CharField(max_length=100, allow_null=True, required=False)
    portDischarge = serializers.CharField(max_length=100, allow_null=True, required=False)
    CntCode = serializers.CharField(max_length=2, allow_null=True, required=False)
    finalDestination = serializers.CharField(max_length=100, allow_null=True, required=False)
    RefClm = serializers.CharField(max_length=1, allow_null=True, required=False)
    ForCur = serializers.CharField(max_length=16)
    cost = serializers.DecimalField(max_digits=12, decimal_places=2)
    insurance = serializers.DecimalField(max_digits=12, decimal_places=2)
    freight = serializers.DecimalField(max_digits=12, decimal_places=2)
    pkt = serializers.IntegerField()
    gwt = serializers.DecimalField(max_digits=12, decimal_places=3)
    nwt = serializers.DecimalField(max_digits=12, decimal_places=3)
    ExpDuty = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True, required=False)
    shipBNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    shipBDt = serializers.CharField(max_length=20, allow_null=True, required=False)
    
