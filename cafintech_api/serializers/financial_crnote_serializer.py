from rest_framework import serializers

class FinacialCreditNoteSerializer(serializers.Serializer):
    fcnsno = serializers.IntegerField()
    tDate = serializers.CharField(max_length = 20)
    fcnType = serializers.CharField(max_length = 50)
    lcode = serializers.CharField(max_length = 10)
    dbCode = serializers.CharField(max_length = 10)
    naration = serializers.CharField(max_length = 100)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0)
    rtod = serializers.DecimalField(max_digits=5, decimal_places=2, default=0) # Drop down [mastcode].[RateTod](rtod) 
    tamount = serializers.DecimalField(max_digits=12, decimal_places=2, default=0) # Calculation tamount = amount * rtod * .01