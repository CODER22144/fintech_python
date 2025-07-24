from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.material_stock_serializer import MaterialStockSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getMenu(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetMenu]")
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(data=json.loads(json_data), status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
