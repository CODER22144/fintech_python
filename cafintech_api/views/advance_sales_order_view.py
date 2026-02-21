from django.db import connections

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.sales_order_details_serializer import SaleOrderDetailSerializer
from cafintech_api.serializers.sales_order_serializer import SalesOrderSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addAdvanceSaleOrderDetails(request):
    try:
        request.data['userId'] = request.user.userId
        orderSerializer = SalesOrderSerializer(data=request.data)
        orderDetailsSerializer = SaleOrderDetailSerializer(data=request.data['orderdetails'], many=True)
        if(orderSerializer.is_valid() and orderDetailsSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [sales].[uspAddOrderAdvance] ?",(json.dumps(request.data),))
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