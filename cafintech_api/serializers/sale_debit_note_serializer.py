from rest_framework import serializers

from cafintech_api.serializers.sales_debit_note_details_serializer import SaleDbNoteDetailSerializer

class SaleDbNoteSerializer(serializers.Serializer):
    No = serializers.CharField(max_length = 30,allow_null=True, required = False)
    Dt = serializers.CharField(max_length = 20)
    lcode = serializers.CharField(max_length = 10)
    drId = serializers.CharField(max_length = 2)
    daId = serializers.CharField(max_length = 2)
    crCode = serializers.CharField(max_length = 10)
    SaleDbnoteItemDetails = SaleDbNoteDetailSerializer(many=True)