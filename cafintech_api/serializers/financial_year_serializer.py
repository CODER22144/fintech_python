from rest_framework import serializers

class FinancialYearSerializer(serializers.Serializer):
    Fy = serializers.CharField(max_length=9)
    SDate = serializers.CharField(max_length=20)
    EDate = serializers.CharField(max_length=20)
    IsActive = serializers.CharField(max_length=10)
    # Example field definitions for FinancialYearSerializer
    # [
    #     {"id": "Fy", "name": "Financial Year", "isMandatory": True, "inputType": "text"},
    #     {"id": "SDate", "name": "Start Date", "isMandatory": True, "inputType": "text"},
    #     {"id": "EDate", "name": "End Date", "isMandatory": True, "inputType": "text"},
    #     {"id": "IsActive", "name": "Is Active", "isMandatory": True, "inputType": "text"}
    # ]