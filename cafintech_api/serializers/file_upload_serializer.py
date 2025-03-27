# myapp/serializers.py

from rest_framework import serializers
from ..models.upload import FileUpload

class UploadedFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = FileUpload
        fields = "__all__"
