from rest_framework import serializers

from user.models import User
from user.models import ErrorLog

class user_serializer(serializers.ModelSerializer):

    class Meta:
        model = User
        fields = '__all__'


class error_log_serializer(serializers.ModelSerializer):
    class Meta:
        model = ErrorLog
        fields = '__all__'
        read_only_fields = ['id', 'created_at']
