from rest_framework import serializers

class JournalVoucherSerializer(serializers.Serializer):
    tDate = serializers.CharField(max_length = 50)
    crCode = serializers.CharField(max_length = 20)
    dbCode = serializers.CharField(max_length = 20)
    naration = serializers.CharField(max_length = 100)
    amount = serializers.DecimalField(max_digits=12, decimal_places=3)
