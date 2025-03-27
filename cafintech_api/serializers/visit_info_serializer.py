from django.forms import ValidationError
from rest_framework import serializers

class VisitInfoSerializer(serializers.Serializer):
    userId = serializers.CharField(max_length=20)                           # Dropdown from mastcode.Resources(resId)
    bpName = serializers.CharField(max_length=100)
    cperson = serializers.CharField(max_length=100)
    cno = serializers.CharField(max_length=10)
    popVisit = serializers.CharField(max_length=100)
    brType = serializers.CharField(max_length=1)                  # Drop Down [mastcode].[BusinessRelationType](brtid)
    bsecured = serializers.CharField(max_length=1)                # Drop Down [mastcode].[YesNo](yn)
    liveImage = serializers.CharField(allow_null=True)
    geoLocation = serializers.CharField(max_length=100,allow_null=True,required=False)

    def validate_liveImage(self, value):
        if value == None or value == "":
            raise ValidationError("Required Image")
        return value