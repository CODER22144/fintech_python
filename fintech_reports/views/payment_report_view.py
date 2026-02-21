from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.payment_report_serializer import BillPendingSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBillPending(request):
    try:
        serializer = BillPendingSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspGetBillPending] ?",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
