from rest_framework import serializers

class BusinessPartnerTaxInfoSerializer(serializers.Serializer):
   bpCode = serializers.CharField(max_length = 10)
   crDays = serializers.IntegerField()
   paymentTerm = serializers.CharField(max_length = 100, allow_null=True, required=False)
   packing = serializers.CharField(max_length = 1, allow_null=True, required=False)
   freight = serializers.CharField(max_length = 1, allow_null=True, required=False)
   insurance = serializers.CharField(max_length = 1, allow_null=True, required=False)
   insurancePaid = serializers.CharField(max_length = 1, allow_null=True, required=False)
   cin = serializers.CharField(max_length = 20, allow_null=True, required=False)
   pan = serializers.CharField(max_length = 10, allow_null=True, required=False)
   tan = serializers.CharField(max_length = 20, allow_null=True, required=False)
   pfno = serializers.CharField(max_length = 20, allow_null=True, required=False)
   esino = serializers.CharField(max_length = 20, allow_null=True, required=False)
   mop = serializers.CharField(max_length = 1, allow_null=True, required=False)
   bankAcNo = serializers.CharField(max_length = 20, allow_null=True, required=False)
   bankAcType = serializers.CharField(max_length = 20, allow_null=True, required=False)
   bankAcName = serializers.CharField(max_length = 50, allow_null=True, required=False)
   bankName = serializers.CharField(max_length = 50, allow_null=True, required=False)
   bankBranch = serializers.CharField(max_length = 100, allow_null=True, required=False)
   ifscCode = serializers.CharField(max_length = 11, allow_null=True, required=False)
   swiftCode = serializers.CharField(max_length = 20, allow_null=True, required=False)