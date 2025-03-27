from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.ledger_codes_serializer import LedgerCodesSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addWorkProcess(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspAddWorkProcess] %s",(json.dumps(request.data),))
        cursor.close()
        return Response(request.data)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateWorkProcess(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspUpdateWorkProcess] %s",(json.dumps(request.data),))
        cursor.close()
        return Response(request.data)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllWorkProcess(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetWorkProcess]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getAByIdWorkProcess(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetByIdWorkProcess] %s", (request.data['wpId'],))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteWorkProcess(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspDeleteWorkProcess] %s", (request.data['wpId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
