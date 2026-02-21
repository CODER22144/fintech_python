from rest_framework import serializers

class PaymentOutwardSerializer(serializers.Serializer):
    payId = serializers.IntegerField(required=False, allow_null=True)
    Dt = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10)
    crCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=18, decimal_places=2)
    mop = serializers.CharField(max_length=20)
    refNo = serializers.CharField(max_length=30, required=False, allow_null=True)
    refDate = serializers.CharField(max_length=20,required=False, allow_null=True)
    narration = serializers.CharField(max_length=200, required=False, allow_null=True)

class PaymentOutwardReportSerializer(serializers.Serializer):
    payId = serializers.IntegerField(required=False, allow_null=True)
    fromDate = serializers.CharField(max_length=20, required=False, allow_null=True)
    toDate = serializers.CharField(max_length=20, required=False, allow_null=True)
    lcode = serializers.CharField(max_length=10,required=False, allow_null=True)
    adjusted = serializers.CharField(max_length=1,required=False, allow_null=True)

class PaymentInSerializer(serializers.Serializer):
    payId = serializers.IntegerField(required=False, allow_null=True)
    Dt = serializers.CharField(max_length=20)
    lcode = serializers.CharField(max_length=10)
    dbCode = serializers.CharField(max_length=10)
    amount = serializers.DecimalField(max_digits=18, decimal_places=2)
    mop = serializers.CharField(max_length=20)
    refNo = serializers.CharField(max_length=30, required=False, allow_null=True)
    refDate = serializers.CharField(max_length=20,required=False, allow_null=True)
    narration = serializers.CharField(max_length=200, required=False, allow_null=True)
