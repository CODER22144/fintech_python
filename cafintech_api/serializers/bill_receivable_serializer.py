from rest_framework import serializers

class BillReceivableSerializer(serializers.Serializer):
    tdate = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10)
    crCode = serializers.CharField(max_length=10)
    naration = serializers.CharField(max_length=100)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    billNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    billDate = serializers.CharField(max_length=30, allow_null=True, required=False)
    DocProof = serializers.CharField(max_length=255, allow_null=True, required=False)
    

