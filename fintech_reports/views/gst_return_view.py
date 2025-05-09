from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.gst_return_serializer import GSTReturnSerializer
from fintech_reports.serializers.mat_report_serializer import MatReportSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getB2b(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[GetB2b] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getB2c(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[GetB2c] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getB2Cl(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[GetB2Cl] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getGstHsnSummary(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[GetGstHsnSummary] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getCrDrNote(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[GetCrDbNote] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getDocType(request):
    try:
        serializer = GSTReturnSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[GetDocType] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
                                  