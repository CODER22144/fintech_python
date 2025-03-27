from rest_framework import serializers

class DbNoteAgainstCrNoteSerializer(serializers.Serializer):
    docno = serializers.IntegerField()
    recDate = serializers.CharField(max_length=20)
    crnNo = serializers.CharField(max_length=20, allow_null=True, required=False)
    crnDate = serializers.CharField(max_length=20, allow_null=True, required=False)