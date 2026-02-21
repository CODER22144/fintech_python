from rest_framework import serializers

class LedgerCodesSerializer(serializers.Serializer):
    lcode = serializers.CharField(max_length=10)
    lname = serializers.CharField(max_length=50)
    ltype = serializers.CharField(max_length=1)
    agCode = serializers.CharField(max_length=5)
    lstatus = serializers.CharField(max_length=1)
    remark = serializers.CharField(max_length=100, allow_null=True, required=False)
    
    add = serializers.CharField(max_length=100, allow_null=True, required=False)
    add1 = serializers.CharField(max_length=100, allow_null=True, required=False)
    city = serializers.CharField(max_length=50, allow_null=True, required=False)
    Stcd = serializers.IntegerField(allow_null=True, required=False)
    zipCode = serializers.CharField(max_length=6, allow_null=True, required=False)
    distance = serializers.IntegerField(allow_null=True, required=False)
    country = serializers.CharField(max_length=2, allow_null=True, required=False)
    phone = serializers.CharField(max_length=10, allow_null=True, required=False)
    altPhone = serializers.CharField(max_length=10, allow_null=True, required=False)
    email = serializers.CharField(max_length=50, allow_null=True, required=False)

    crDays = serializers.IntegerField(allow_null=True, required=False, default=0)
    paymentTerm = serializers.CharField(max_length=100, allow_null=True, required=False)
    SupTyp = serializers.CharField(max_length=10, allow_null=True, required=False)
    regId = serializers.CharField(max_length=3, allow_null=True, required=False)
    Gstin = serializers.CharField(max_length=15, allow_null=True, required=False)
    rc = serializers.CharField(max_length=1, default='N', allow_null=True, required=False)
    isEcom = serializers.CharField(max_length=1, default='N', allow_null=True, required=False)
    tdsCode = serializers.CharField(max_length=10, allow_null=True, required=False)
    igstOnIntra = serializers.CharField(max_length=1, default='N')

    bankAcNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    bankName = serializers.CharField(max_length=50, allow_null=True, required=False)
    bankAcName = serializers.CharField(max_length=50, allow_null=True, required=False)
    ifscCode = serializers.CharField(max_length=11, allow_null=True, required=False)
    swiftCode = serializers.CharField(max_length=20, allow_null=True, required=False)

    discType = serializers.CharField(max_length=1, allow_null=True, required=False)
    discRate = serializers.DecimalField(max_digits=5, decimal_places=2, allow_null=True, required=False, default='0.00')
    loyaltyDisc = serializers.DecimalField(max_digits=5, decimal_places=2, allow_null=True, required=False, default='0.00')
    paymentDisc = serializers.DecimalField(max_digits=5, decimal_places=2, allow_null=True, required=False, default='0.00')

    workstation = serializers.CharField(max_length=20)
    userid = serializers.CharField(max_length=50)

