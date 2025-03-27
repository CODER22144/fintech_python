from rest_framework import serializers

class PartSubAssemblySerializer(serializers.Serializer):
    matno = serializers.CharField(max_length=15)
    pic = serializers.CharField(max_length=100, allow_null=True, required = False)
    drawing = serializers.CharField(max_length=100, allow_null=True, required = False)
    asdrawing = serializers.CharField(max_length=100, allow_null=True, required = False)
    revisionNo = serializers.CharField(max_length=10, allow_null=True, required = False)
    csId = serializers.CharField(max_length=2)