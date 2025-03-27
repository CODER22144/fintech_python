from rest_framework import serializers

class BankUploadSerializer(serializers.Serializer):
    transDate = serializers.CharField(max_length=50)
    transDescription = serializers.CharField(max_length=250)
    refNumber = serializers.CharField(max_length=50, allow_null=True, required=False)
    valueDate = serializers.CharField(max_length=20)
    withdrawal = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True, required=False)
    deposit = serializers.DecimalField(max_digits=12, decimal_places=2, allow_null=True, required=False)
    bankCode = serializers.CharField(max_length=10)
    lcode = serializers.CharField(max_length=10)
    postMethod = serializers.CharField(max_length=1)
    naration = serializers.CharField(max_length=100, allow_null=True, required=False)
