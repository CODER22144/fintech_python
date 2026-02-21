from rest_framework import serializers
from cafintech_api.models.form_json import JsonForm

class JsonFormSerializer(serializers.ModelSerializer):
    class Meta:
        model = JsonForm
        fields = '__all__'
