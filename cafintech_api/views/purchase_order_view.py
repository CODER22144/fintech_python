from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.purchase_order_details_serializer import PurchaseOrderDetailsSerializer
from cafintech_api.serializers.purchase_order_serializer import PurchaseOrderSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createPurchaseOrder(request):
    try:
        orderSerializer = PurchaseOrderSerializer(data=request.data)
        orderDetailsSerializer = PurchaseOrderDetailsSerializer(data=request.data['PurchaseOrderDetails'], many=True)
        if(orderSerializer.is_valid() and orderDetailsSerializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[uspAddPurchaseOrder] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(orderSerializer.data)
        errors = {}
        if not orderSerializer.is_valid():
            errors["Order"] = orderSerializer.errors
        if not orderDetailsSerializer.is_valid():
            errors["Order_details"] = orderDetailsSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllPriority(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetAllPriority]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllPoType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetAllPoType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)