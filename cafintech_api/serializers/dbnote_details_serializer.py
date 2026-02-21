from rest_framework import serializers

class DbNoteDetailSerializer(serializers.Serializer):
    No = serializers.CharField(max_length = 30, allow_null = True, required = False)
    vtype = serializers.CharField(max_length=10, allow_null=True, required=False)
    wdocno = serializers.IntegerField(required=False, allow_null=True)
    matno = serializers.CharField(max_length=15, required=False, allow_null=True)
    OrgInvNo = serializers.CharField(max_length=16, allow_null=True, required=False)
    OrgInvDate = serializers.CharField(max_length=20, required=False, allow_null=True)
    PrdDesc = serializers.CharField(max_length=300, allow_null=True, required=False)
    HsnCd = serializers.CharField(max_length=8, allow_null=True, required=False)
    Qty = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    UnitPrice = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    Unit = serializers.CharField(max_length=8, allow_null=True, required=False)
    TotAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    Discount = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    AssAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)
    GstRt = serializers.DecimalField(max_digits=6, decimal_places=2, required=False, allow_null=True)
    GstAmt = serializers.DecimalField(max_digits=15, decimal_places=3, required=False, allow_null=True)