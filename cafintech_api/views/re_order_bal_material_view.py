from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.re_order_balance_material_serializer import ReOrderBalanceMaterialSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def reportReOrderBalanceMaterial(request):
    try:
        request.data['userid'] = request.user.userId
        request.data['roleid'] = request.user.roles.role_id
        serializer = ReOrderBalanceMaterialSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[ReOrderBalanceMaterial] %s",(json.dumps(request.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createBalanceOrder(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [sales].[uspCreateBalanceOrder] %s",(request.data['orderId'],))
        cursor.close()
        return Response(data={"status" : "success", "message": "Order Created Successfully"}, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)