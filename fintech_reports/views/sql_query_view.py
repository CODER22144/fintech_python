from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.sql_query_serializer import SQLConditionSerializer, SQLQuerySerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def executeSqlQuery(request):
    try:
        serializer = SQLQuerySerializer(data=request.data)
        conditions = SQLConditionSerializer(data=request.data['conditions'], many=True)
        if(conditions.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[usDynamicSql] ?,?,?",(request.data['tableName'], request.data['selectCols'],json.dumps(conditions.data),))
            json_data = ConvertToJson(cursor)
            row_headers=[x[0] for x in cursor.description]

            main_json = {
                "headers" : row_headers,
                "data" : json_data
                }

            cursor.close()
            return JsonResponse(main_json, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getColumns(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [mastcode.[uspGetColumns] ?", (request.data['tableName'],))
        data = cursor.fetchall()
        columns = [row[0] for row in data]
        types = {row[0] : row[1] for row in data}
        main_json = {
            "columns" : columns,
            "types" : types
            }
        cursor.close()
        return JsonResponse(main_json, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getColumnsDropdown(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [mastcode.[uspGetColumns] ?", (request.data['tableName'],))
        data = cursor.fetchall()
        types = [{"type" : row[0]} for row in data]
        cursor.close()
        return JsonResponse(types, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getOperators(request):
    try:
        operators = [
            {
            "display" : "Grater Than : >",
            "value" : ">"
            },
            {
            "display" : "Grater Than Equals To : >=",
            "value" : ">="
            },
            {
            "display" : "Less Than : <",
            "value" : "<"
            },
            {
            "display" : "Less Than : <=",
            "value" : "<="
            },
            {
            "display" : "Like",
            "value" : "LIKE"
            },
            {
            "display" : "Equals To",
            "value" : "="
            }
        ]
        return JsonResponse(operators, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
