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
import pdfkit
from collections import defaultdict


def getExpOrder(request, inv, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetExpOrderByorderId] %s",(inv,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        # hsnList = json_data[0]['hsnList']
        # grouped_data = defaultdict(lambda: {"hsn": [], "totalTaxableAmount": 0, "totaligstAmount": 0, "totalCgstAmount": 0, "totalSgstAmount": 0, "totalQty" : 0})

        # for hsn in hsnList:
        #     rate = hsn['igstRate']
        #     grouped_data[rate]['hsn'].append(hsn)
        #     grouped_data[rate]['totalTaxableAmount'] += hsn['sumTaxableAmount']
        #     grouped_data[rate]['totaligstAmount'] += hsn['sumigstAmount']
        #     grouped_data[rate]['totalCgstAmount'] += hsn['sumCgstAmount']
        #     grouped_data[rate]['totalSgstAmount'] += hsn['sumSgstAmount']
        #     grouped_data[rate]['totalQty'] += hsn['sumQty']

        #     grouped_data[rate]['totalTaxableAmount'] = round(grouped_data[rate]['totalTaxableAmount'], 2)

        if(len(json_data[0]['d']) <= 35):
            for i in range(len(json_data[0]['d']), 35):
                json_data[0]['d'].append({'icode' : ''})

        context = {
            "sale" : json_data[0],
            # 'hsnList' : list(grouped_data.values())
        }
        cursor.close()
        return render(request, "expOrder.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getExpOrderPdf(request, inv, cid):
    url = 'http://erpapi.rcinz.com/get-exp-order/'+inv + "/" + cid
    redirectTO = 'EXP_'+inv+'_'+cid+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://erpapi.rcinz.com/media/docs/'+redirectTO)


def getExpInvoice(request, inv, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetExpInvoiceByInvno] %s",(inv,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)

        if(len(json_data[0]['d']) <= 35):
            for i in range(len(json_data[0]['d']), 35):
                json_data[0]['d'].append({'icode' : ''})

        context = {
            "sale" : json_data[0],
        }
        cursor.close()
        return render(request, "exp_invoice.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getExpInvoicePdf(request, inv, cid):
    url = 'http://erpapi.rcinz.com/get-exp-inv/'+inv + "/" + cid
    redirectTO = 'EXPINV_'+inv+'_'+cid+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://erpapi.rcinz.com/media/docs/'+redirectTO)

