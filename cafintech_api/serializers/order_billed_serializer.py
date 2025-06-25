from rest_framework import serializers

class OrderBilledSerializer(serializers.Serializer):
    orderid = serializers.IntegerField()
    docno = serializers.IntegerField()
    doctype = serializers.CharField(max_length=20, allow_null=True, required=False)
    docdate = serializers.CharField(max_length=20, allow_null=True, required=False)
    billValue = serializers.DecimalField(decimal_places=2, max_digits=12, allow_null=True, required=False)
    rgstin = serializers.CharField(max_length=16, allow_null=True, required=False)
    ewbno = serializers.CharField(max_length=15, allow_null=True, required=False)
    
    irn = serializers.CharField(max_length=64, allow_null=True, required=False)
    ackno = serializers.CharField(max_length=20, allow_null=True, required=False)
    ackdate = serializers.CharField(max_length=20, allow_null=True, required=False)
    sqrcode = serializers.CharField(max_length=50000, allow_null=True, required=False)
    status = serializers.CharField(max_length=10, allow_null=True, required=False)
