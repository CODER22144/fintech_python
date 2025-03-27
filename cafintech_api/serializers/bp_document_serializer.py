from rest_framework import serializers

class BusinessPartnerDocumentSerializer(serializers.Serializer):
   bpCode = serializers.CharField(max_length = 10)
   bpRegform = serializers.CharField(max_length = 100)
   gstreg06 = serializers.CharField(max_length = 100)
   mcaMasterData = serializers.CharField(max_length = 100)
   paymentProof = serializers.CharField(max_length = 100)
   panCard = serializers.CharField(max_length = 100)
   aadharCard = serializers.CharField(max_length = 100)
   msmeNo = serializers.CharField(max_length = 20)
   msmeCertificate = serializers.CharField(max_length = 100)
   balanceSheet = serializers.CharField(max_length = 100)
