from decimal import Decimal
from django.db import connections

from django.http import JsonResponse
from django.shortcuts import render, redirect
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from CaFinTech.settings import File_Path, path_wkhtmltopdf

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.cr_note_invoice_serializer import CrNoteInvoiceSerializer

# ORDER SLIP

def getCrNoteFormat(request, docno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [fiac].[uspGetCrNoteBydocno] %s",(docno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)

        json_data = json.loads(json_data)

        # json_data = json.loads(json_data)[0]

        if(len(json_data['itemList']) <= 30):
            for i in range(len(json_data['itemList']), 30):
                json_data['itemList'].append({'' : ''})

        context = {
            "crnote" : json_data,
        }
        cursor.close()
        return render(request, "crnote.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getECrNote(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetECrNote] %s",(request.data['docno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        cursor.close()
        return Response(json_data, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addEinvoiceToCrNote(request):
    try:
        serializer = CrNoteInvoiceSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddCrDrNoteEInvoice] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)