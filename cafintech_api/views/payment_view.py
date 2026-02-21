from django.db import connections

from cafintech_api.serializers.payment_clear_serializer import PaymentClearSerializer
from cafintech_api.serializers.payment_serializer import PaymentSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPayment(request):
    try:
        serializer = PaymentSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddPayment] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPayType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [mastcode].[PayType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getVoucherType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetBillPendingType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBillPendingByLcode(request, lCode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetBillPendingByLcode] ?", (lCode,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getBillPendingByTransId(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetBillPendingByTransIdVtype] ?,?", (request.data['transId'], request.data['vType']))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPaymentAdvancePending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetPaymentAdvance]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentClear(request):
    try:
        serializer = PaymentClearSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddPaymentClear] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deletePaymentClear(request, id):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspDeletePaymentClear] ?", (id, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByTransIdBillPending(request, transId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetBillPendingByTransId] ?", (transId,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getInwardClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetInwardClear] ?,?", (request.data['transId'], request.data['vType']))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getUnadjustedPayment(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetUnAdjustedPayment]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addDbNoteClear(request):
    try:
        serializer = PaymentClearSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddDbNoteClear] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPrTaxInvoiceClear(request):
    try:
        serializer = PaymentClearSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddPRTaxInvoiceClear] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCrNoteClear(request):
    try:
        serializer = PaymentClearSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddCrNoteClear] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getPaymentOutAdvance(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [fiac].[PaymentOutAdvance]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentOutwardAdvClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[PaymentOutAdvance_Post]")
        cursor.close()
        return Response(data={"status" : "OK"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getDebitNotePending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [fiac].[DbnotePostPending]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addDebitNoteClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[Dbnote_Post]")
        cursor.close()
        return Response(data={"status" : "OK"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
# PAYMENT PENDING IN ADVANCE WITH POST

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getPaymentInAdvance(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [fiac].[PaymentInAdvance]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentInAdvClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[PaymentInAdvance_Post]")
        cursor.close()
        return Response(data={"status" : "OK"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
# CREDIT NOTE PENDING POST

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getCreditNotePending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [sales].[SaleCrnotePostPending]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCreditNoteClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [sales].[SaleCrnote_Post]")
        cursor.close()
        return Response(data={"status" : "OK"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
# FINANCIAL CREDIT NOTE PENDING POST

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getFinancialCreditNotePending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspGetFinancialCrnotePostPending]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addFinancialCreditNoteClear(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [fiac].[FinancialCrnote_Post]")
        cursor.close()
        return Response(data={"status" : "OK"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)