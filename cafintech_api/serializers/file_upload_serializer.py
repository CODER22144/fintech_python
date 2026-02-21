# myapp/serializers.py

from rest_framework import serializers
from ..models.upload import BillReceiptUpload, FileUpload, JvoucherUpload, CompanyUpload

class UploadedFileSerializer(serializers.ModelSerializer):
    class Meta:
        model = FileUpload
        fields = "__all__"

class UploadedBrSerializer(serializers.ModelSerializer):
    class Meta:
        model = BillReceiptUpload
        fields = ['file']

class UploadedJvoucherSerializer(serializers.ModelSerializer):
    class Meta:
        model = JvoucherUpload
        fields = ['file']

class UPloadCompanySerializer(serializers.ModelSerializer):
    class Meta:
        model = CompanyUpload
        fields = ['file']