from rest_framework import serializers

class BusinessPartnerOnboardSerializer(serializers.Serializer):
    bpCode = serializers.CharField(max_length=10)
    bpGSTIN = serializers.CharField(max_length=15, allow_null=True, required=False)
    bpName = serializers.CharField(max_length=100)
    bpAdd = serializers.CharField(max_length=100)
    bpAdd1 = serializers.CharField(max_length=100, allow_null=True, required=False)
    bpCity = serializers.CharField(max_length=50)
    bpState = serializers.IntegerField()
    bpZipCode = serializers.CharField(max_length=6)
    bpCountry = serializers.CharField(max_length=2)
    bpPhone = serializers.CharField(max_length=10)
    bpWhatsApp = serializers.CharField(max_length=10, allow_null=True, required=False)
    bpEmail = serializers.CharField(max_length=50)
    contactPerson = serializers.CharField(max_length=50)
    designation = serializers.CharField(max_length=20)

