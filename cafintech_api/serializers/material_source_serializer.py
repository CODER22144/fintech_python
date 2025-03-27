from rest_framework import serializers

class MaterialSourceSerializer(serializers.Serializer):
   
   matno = serializers.CharField(max_length=15)
   bpCode = serializers.CharField(max_length=10)
   matDescription = serializers.CharField(max_length=100)
   hsnCode = serializers.CharField(max_length=10)
   bpPartNo = serializers.CharField(max_length=30, allow_null=True, required=False)
   bpRate = serializers.DecimalField(default=0, max_digits=12, decimal_places=3)
   rateType = serializers.CharField(max_length=1)
   rateEf = serializers.CharField(max_length=12)
   moq = serializers.IntegerField()
   leadTime = serializers.IntegerField()
   bpRating = serializers.IntegerField()
