from rest_framework import serializers

class SQLConditionSerializer(serializers.Serializer):
    columnName = serializers.CharField(max_length=256)
    operator = serializers.CharField(max_length=10)
    value = serializers.CharField(max_length=256)

class SQLQuerySerializer(serializers.Serializer):
    tableName = serializers.CharField(max_length=256)
    selectCols = serializers.CharField(max_length=1000)