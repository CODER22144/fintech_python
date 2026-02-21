from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.sales_order_details_serializer import SaleOrderDetailSerializer
from cafintech_api.serializers.sales_order_serializer import SalesOrderSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addSaleOrderDetails(request):
    try:
        # request.data['userId'] = request.user.userId
        orderSerializer = SalesOrderSerializer(data=request.data, many=True)
        if(orderSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"exec [sales].[uspAddSale] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(orderSerializer.data)
        errors = {}
        if not orderSerializer.is_valid():
            errors["Sale"] = orderSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getShipping(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select shipCode, shipName,bpCode from [mastcode].[BPShipping]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllOrder(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [sales].[uspGetOrder]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPaymentTerm(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select disc, pterm from [mastcode].[PaymentTerm]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getOrderMaterialByOrderId(request, orderId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [sales].[uspGetByIdOrderDetails] ?",(orderId,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addOrderMaterial(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [sales].[uspAddOrderMaterial] ?",(json.dumps(request.data),))
        cursor.close()
        return Response(request.data)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteOrderMaterial(request, odId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [sales].[uspDeleteOrderMaterial] ?", (odId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteWholeOrder(request, orderId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [sales].[uspDeleteOrder] ?", (orderId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)