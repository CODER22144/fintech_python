from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.bank_upload_serializer import BankUploadSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadBankDetails(request):
    try:
        serializer = BankUploadSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddBankStatement] ?",(json.dumps(serializer.data),))
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
#         cursor = getDbCursor(request.user)
#         cursor.execute(f"exec [fiac].[uspGetByIdBankStatement] ?", (request.data['transId'],))
#         json_data = ConvertToJson(cursor)
#         return JsonResponse(json_data, safe=False)
#     except Exception as e:
#         return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def updateBankStatement(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspUpdateBankStatement] ?,?", (request.data['transId'],request.data['lcode']))
        cursor.close()
        return Response(data = request.data, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadHdfc(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[GetPaymentHdfc] ?",(json.dumps({"transDate" : request.data['transDate']}),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def uploadKotak(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[GetPaymentKotak] ?",(json.dumps({"transDate" : request.data['transDate']}),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def uncliamedPayments(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[UnclaimedBankStatement]")
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json.loads(json_data))
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def claimPayment(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[ClaimBankStatement] ?", (json.dumps(request.data),))
        cursor.close()
        return Response(data = request.data, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def claimedPayments(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[BankStatementPendingPost]")
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json.loads(json_data))
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def postBankStatementPendings(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[BankStatementPost]")
        cursor.close()
        return Response(data = {"status" : "ok"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)