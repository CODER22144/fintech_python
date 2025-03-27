from rest_framework import serializers

class BusinessPartnerContactSerializer(serializers.Serializer):
   bpcid = serializers.IntegerField(allow_null=True, required=False)
   bpCode = serializers.CharField(max_length=10)
   cno = serializers.CharField(max_length=10)
   cperson = serializers.CharField(max_length=50)
   designation = serializers.CharField(max_length=20)
   emailid = serializers.CharField(max_length=50)