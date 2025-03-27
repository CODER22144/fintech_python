from django.forms import ValidationError
from rest_framework import serializers
import re

class company_serializer(serializers.Serializer):
    compGstin = serializers.CharField(max_length=15, allow_null=True, required=False)
    legalName = serializers.CharField(max_length=100)
    tradeName = serializers.CharField(max_length=100, allow_null=True, required=False)
    compAdd = serializers.CharField(max_length=100)
    compAdd1 = serializers.CharField(max_length=100,allow_null=True, required=False)
    compCity = serializers.CharField(max_length=50)
    compZipCode = serializers.CharField(max_length=6)
    compStateCode = serializers.IntegerField()
    compPhone = serializers.CharField(max_length=12)
    compEmail = serializers.EmailField()
    compCIN = serializers.CharField(max_length=21, allow_null=True, required=False)
    compPAN = serializers.CharField(max_length=10, allow_null=True, required=False)
    bankName = serializers.CharField(max_length=50, allow_null=True, required=False)
    accountNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    ifscCode = serializers.CharField(max_length=11, allow_null=True, required=False)
    adCode = serializers.CharField(max_length=15, allow_null=True, required=False)
    swiftCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    compLogo = serializers.CharField(max_length=200, allow_null=True, required=False)
    compDbName = serializers.CharField(max_length=30, allow_null=True, required=False)
    
    def validate_compPAN(self, value):
        if value:
            if not re.match(r"[A-Z]{5}[0-9]{4}[A-Z]{1}", value):
                raise ValidationError("PAN number not valid.")
        return value
    
