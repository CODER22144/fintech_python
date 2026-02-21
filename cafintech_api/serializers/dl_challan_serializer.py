from rest_framework import serializers

class DlChallanSerializer(serializers.Serializer):
    No = serializers.IntegerField(allow_null=True, required=False)
    Dt = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10, allow_null=True, required=False)
    taxApplies = serializers.CharField(max_length=1)
    movementReason = serializers.CharField(max_length=30)
    Remarks = serializers.CharField(max_length=250, allow_null=True, required=False)
    prodNo = serializers.CharField(max_length=15, allow_null=True, required=False)
    qty = serializers.DecimalField(max_digits=12, decimal_places=3, allow_null=True, required=False)
    transMode = serializers.CharField(max_length=1)
    transId = serializers.CharField(max_length=15, allow_null=True, required=False)
    vehicleNo = serializers.CharField(max_length=15, allow_null=True, required=False)
    transDocNo = serializers.CharField(max_length=16, allow_null=True, required=False)
    transDocDate = serializers.CharField(max_length=20, allow_null=True, required=False)
    ewayBillNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    ewayBillDate = serializers.CharField(max_length=20, allow_null=True, required=False)

class DlChallanDetailSerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    Qty = serializers.DecimalField(max_digits=12, decimal_places=3)