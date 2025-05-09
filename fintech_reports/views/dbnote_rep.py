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

# SALES DEBITNOTE

def getDbSalesnoteSaleFormat(request, docno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [fiac].[uspGetSaleDbNoteBydocno] %s",(docno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)

        json_data = json.loads(json_data)

        # json_data = json.loads(json_data)[0]

        if(len(json_data['itemList']) <= 30):
            for i in range(len(json_data['itemList']), 30):
                json_data['itemList'].append({'' : ''})

        context = {
            "db" : json_data,
        }
        cursor.close()
        return render(request, "dbnote_sale.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

def getDebitNoteFormat(request, docno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [fiac].[uspGetDbNoteBydocno] %s",(docno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)

        json_data = json.loads(json_data)

        # json_data = json.loads(json_data)[0]

        if(len(json_data['itemList']) <= 30):
            for i in range(len(json_data['itemList']), 30):
                json_data['itemList'].append({'' : ''})

        context = {
            "db" : json_data,
        }
        cursor.close()
        return render(request, "debit_note.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getPRTaxInvoiceFormat(request, docno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [fiac].[uspGetPRTaxInvoiceBydocno] %s",(docno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)

        json_data = json.loads(json_data)

        # json_data = json.loads(json_data)[0]

        if(len(json_data['itemList']) <= 30):
            for i in range(len(json_data['itemList']), 30):
                json_data['itemList'].append({'' : ''})

        context = {
            "db" : json_data,
        }
        cursor.close()
        return render(request, "PR-tax-invoice.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getEDbNote(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetEDbNote] %s",(request.data['docno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        cursor.close()
        return Response(json_data, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getEDbSaleNote(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetESaleDbNote] %s",(request.data['docno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        cursor.close()
        return Response(json_data, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getEPRTaxInvoice(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetEPRTaxInvoice] %s",(request.data['docno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        cursor.close()
        return Response(json_data, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)


