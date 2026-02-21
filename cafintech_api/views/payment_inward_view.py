from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.payment_inward_serializer import PaymentInwardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentInward(request):
    try:
        serializer = PaymentInwardSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddPaymentInward] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getUnadjustedPaymentInward(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetUnAdjustedPaymentInward]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPaymentPendingByLcode(request, lcode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetPaymentPendingByLcode] ?", (lcode, ))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getPaymentPendingByTransIdVtype(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetPaymentPendingByTransId] ?,?", (request.data['transId'], request.data['vType']))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def postPaymentInward(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[PaymentInwardPost] ?", (json.dumps({"fromDate" : request.data['fromDate']}), ))
        return Response(data={"status" : "ok"}, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getBankStatementByTransDate(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetBankStatementByTranDate] ?", (json.dumps({"fromDate" : request.data['fromDate']}), ))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
