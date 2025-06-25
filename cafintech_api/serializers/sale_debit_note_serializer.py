from rest_framework import serializers

class SaleDbNoteSerializer(serializers.Serializer):
    # docno = serializers.IntegerField()
    docDate = serializers.CharField(max_length = 20)
    lcode = serializers.CharField(max_length = 10)
    invoiceType = serializers.CharField(max_length =30)
    drId = serializers.CharField(max_length = 2)
    daId = serializers.CharField(max_length = 2)
    crCode = serializers.CharField(max_length = 10)
    slId = serializers.CharField(max_length = 2)
    stId = serializers.CharField(max_length = 1)