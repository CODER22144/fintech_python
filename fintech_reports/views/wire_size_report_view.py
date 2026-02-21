from django.db import connections

from django.http import JsonResponse
from django.shortcuts import render
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.wire_size_report_serializer import WireSizeReportSerializer, WsReportSerializer

def getWireSizeReport(request):
    try:
        matno = request.GET.get("matno")
        repId = request.GET.get("repId")
        soId = request.GET.get("soId")

        serializer = WireSizeReportSerializer(data={'matno':matno, 'repId':repId, 'soId':soId})    
        if(serializer.is_valid()):
            cursor = connections[request.GET.get("cid")].cursor()
            cursor.execute(f"EXEC [cost].[WireSizeTl] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            

        context = {
            "ws" : json_data[0],
            "details" : json.loads(json_data[0]['wiredetail'])
        }
        cursor.close()
        return render(request, "wire_size.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getWsReport(request):
    try:
        serializer = WsReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[WireSizeReport] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getPbCostingReport(request):
    try:
        serializer = WsReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[ProductBreakupCostReport] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getPartAssemblyCosting(request):
    try:
        serializer = WsReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[PartAssemblyCostReport] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getPartSubAssemblyCosting(request):
    try:
        serializer = WsReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[PartSubAssemblyCostReport] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialAssemblyCosting(request):
    try:
        serializer = WsReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[MaterialAssemblyCostReport] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
