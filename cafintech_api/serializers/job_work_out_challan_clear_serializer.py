from django.forms import ValidationError
from rest_framework import serializers

class JobWorkOutChallanClearSerializer(serializers.Serializer):
    docno = serializers.IntegerField()
    tDate = serializers.CharField(max_length=20)
    DocProof = serializers.CharField(max_length=100)
