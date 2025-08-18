# myapp/serializers.py

from rest_framework import serializers
from ..models.upload import BillReceiptUpload, FileUpload

class UploadedFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = FileUpload
        fields = "__all__"

class UploadedBrSerializer(serializers.ModelSerializer):
    class Meta:
        model = BillReceiptUpload
        fields = ['file']