from rest_framework import serializers

class DbNoteDispatchSerializer(serializers.Serializer):
    docno = serializers.IntegerField()
    dispDate = serializers.CharField(max_length=20)
    trasportName = serializers.CharField(max_length=100, allow_null=True, required=False)
    vehicleNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    ewayBillNo = serializers.CharField(max_length=30, allow_null=True, required=False)