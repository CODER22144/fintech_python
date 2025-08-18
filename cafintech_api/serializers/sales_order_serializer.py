from rest_framework import serializers

class SalesOrderSerializer(serializers.Serializer):
    No = serializers.CharField(max_length=16, allow_null=True, required=False)
    Dt = serializers.CharField(max_length=20, allow_null=True, required=False)
    lcode = serializers.CharField(max_length=10)
    curCode = serializers.CharField(max_length=7, allow_null=True, required=False) # DEF: INR | DROPDOWN
    conRate = serializers.DecimalField(max_digits=6, decimal_places=2) # DEF: 1.00
    orderId = serializers.IntegerField(allow_null=True, required=False)
    poNo = serializers.CharField(max_length=30, allow_null=True, required=False)
    poDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    privateMark = serializers.CharField(max_length=20, allow_null=True, required=False)
    shipId = serializers.IntegerField(allow_null=True, required=False)


    # custCode = serializers.CharField(max_length=10)
    # carId = serializers.CharField(max_length=10)
    # transmode = serializers.CharField(max_length=1, allow_null=True, required=False)
    # mop = serializers.CharField(max_length=1)
    # mof = serializers.CharField(max_length=1)
    # userId = serializers.CharField(max_length=500, allow_null=True, required=False)
