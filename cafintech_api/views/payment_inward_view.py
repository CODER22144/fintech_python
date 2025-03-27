from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.payment_inward_serializer import PaymentInwardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentInward(request):
    try:
        serializer = PaymentInwardSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddPaymentInward] %s",(json.dumps(serializer.data),))
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
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetUnAdjustedPaymentInward]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPaymentPendingByLcode(request, lcode):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetPaymentPendingByLcode] %s", (lcode, ))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getPaymentPendingByTransIdVtype(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetPaymentPendingByTransId] %s,%s", (request.data['transId'], request.data['vType']))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)