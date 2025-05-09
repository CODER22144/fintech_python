from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.bank_upload_serializer import BankUploadSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadBankDetails(request):
    try:
        serializer = BankUploadSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddBankStatement] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
# @api_view(["POST"])
# @permission_classes([IsAuthenticated])
# def getByTransIdBankStatement(request):
#     try:
#         cursor = connections[request.user.cid.cid].cursor()
#         cursor.execute(f"exec [fiac].[uspGetByIdBankStatement] %s", (request.data['transId'],))
#         json_data = ConvertToJson(cursor)
#         return JsonResponse(json_data, safe=False)
#     except Exception as e:
#         return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def updateBankStatement(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspUpdateBankStatement] %s,%s", (request.data['transId'],request.data['lcode']))
        cursor.close()
        return Response(data = request.data, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadHdfc(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [fiac].[GetPaymentHdfc] %s",(json.dumps({"transDate" : request.data['transDate']}),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadKotak(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [fiac].[GetPaymentKotak] %s",(json.dumps({"transDate" : request.data['transDate']}),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)