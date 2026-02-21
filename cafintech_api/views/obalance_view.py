from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.obalance_report_serializer import OBalanceReportSerializer
from cafintech_api.serializers.obalance_serializer import OBalanceSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addOBalance(request):
    try:
        serializer = OBalanceSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddOpening] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateObalance(request):
    try:
        serializer = OBalanceSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspUpdateOpening] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getByIdOBalance(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetOpening] ?", (json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteOBlance(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspDeleteOpening] ?", (request.data['ObId'],))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
# @api_view(["GET"])
# @permission_classes([IsAuthenticated])
# def getObId(request):
#     try:
#         cursor = getDbCursor(request.user)
#         cursor.execute(f"exec [mastcode].[uspGetOBType]")
#         json_data = ConvertToJson(cursor)
#         return JsonResponse(json_data, safe=False)
#     except Exception as e:
#         return Response(data=generate_error_message(e), status=500, exception=e)
    
# @api_view(["GET"])
# @permission_classes([IsAuthenticated])
# def getBalanceType(request):
#     try:
#         cursor = getDbCursor(request.user)
#         cursor.execute(f"select * from [mastcode].[BalType]")
#         json_data = ConvertToJson(cursor)
#         return JsonResponse(json_data, safe=False)
#     except Exception as e:
#         return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getOBalanceReport(request):
    try:
        serializer = OBalanceReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspGetOpening] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
