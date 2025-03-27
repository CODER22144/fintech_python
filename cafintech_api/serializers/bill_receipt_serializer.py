from django.forms import ValidationError
from rest_framework import serializers

class BillReceiptSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10,required=False, allow_null = True)
    bt = serializers.CharField(max_length = 1)
    bpName = serializers.CharField(max_length=200)
    billNo = serializers.CharField(max_length = 16, required=False, allow_null=True)
    billDate = serializers.CharField(max_length = 20, required=False, allow_null=True)   
    billAmount = serializers.DecimalField(default = 0, max_digits=12, decimal_places=2)
    crtp = serializers.CharField(max_length = 1)
    transmode = serializers.CharField(max_length = 1)
    carrierName = serializers.CharField(max_length= 50, required=False, allow_null=True)
    vehicleNo = serializers.CharField(max_length = 20, required=False, allow_null=True)
    dcgrNo = serializers.CharField(max_length = 16,required=False, allow_null = True)
    dcgrDate = serializers.CharField(max_length = 20,required=False, allow_null = True)
    nopkt = serializers.IntegerField(default=0)  
    docImage = serializers.CharField(allow_null = True)

    def validate_docImage(self, value):
        if value == None or value == "":
            raise ValidationError("Please update the mandatory documents")
        return value
