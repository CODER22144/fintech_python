from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.order_packaging_serializer import OrderPackagingSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addOrderPackaging(request):
    try:
        serializer = OrderPackagingSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[uspAddOrderPacking] %s",(json.dumps(serializer.data),))
            cursor.execute(f"EXEC [sales].[uspGetByIdOrderPacking] %s",(serializer.data['orderId'],))
            json_data = ConvertToJson(cursor)
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getOrderPackingPending(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [sales].[uspGetOrderPackingPending] %s,%s",(request.user.userId, request.user.roles.role_id))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPackedInfoByOrderId(request, orderId):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetByIdOrderPacking] %s",(orderId,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

