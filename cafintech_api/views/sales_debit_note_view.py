from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.sale_debit_note_serializer import SaleDbNoteSerializer
from cafintech_api.serializers.sales_debit_note_details_serializer import SaleDbNoteDetailSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addSaleDebitNote(request):
    try:
        serializer = SaleDbNoteSerializer(data=request.data, many=True)
        # detailsSerializer = SaleDbNoteDetailSerializer(data=request.data['SaleDbnoteItemDetails'], many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddSaleDbnote] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        errors = {}
        if not serializer.is_valid():
            errors["SalesDBNote"] = serializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getInvoiceType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from mastcode.InvoiceType")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)