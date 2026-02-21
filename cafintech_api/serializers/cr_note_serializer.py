from rest_framework import serializers

from cafintech_api.serializers.dbnote_details_serializer import DbNoteDetailSerializer

class CrNoteSerializer(serializers.Serializer):
    Dt = serializers.CharField(max_length = 20)
    lcode = serializers.CharField(max_length = 10)
    drId = serializers.CharField(max_length = 2)
    daId = serializers.CharField(max_length = 2)
    dbCode = serializers.CharField(max_length = 10)
    SaleCrnoteItemDetails = DbNoteDetailSerializer(many=True)