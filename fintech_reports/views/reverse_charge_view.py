from django.db import connections

from django.http import JsonResponse
from django.shortcuts import render, redirect
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
    
def getReverseCharge(request):
    slId = request.GET.get('slId')
    lcode = request.GET.get('lcode')
    fdate = request.GET.get('fdate')
    tdate = request.GET.get('tdate')

    cursor = connections[request.GET.get('cid')].cursor()

    json_input = {
        "slId": slId   if slId  != 'null' else None,
        "lcode": lcode if lcode != 'null' else None,
        "fdate": fdate if fdate != 'null' else None,
        "tdate": tdate if tdate != 'null' else None
    }
    
    cursor.execute(f"EXEC [fiac].[ReversechargeReport] %s", (json.dumps(json_input),))
    json_data = ConvertToJson(cursor)
    json_data = json_data

    sumArr = [0,0,0,0,0,0,0]


    for i in json_data:
        sumArr[0] += i['amount']
        sumArr[1] += i['discountAmount']
        sumArr[2] += i['taxAmount']
        sumArr[3] += i['igstAmount']
        sumArr[4] += i['cgstAmount']
        sumArr[5] += i['sgstAmount']
        sumArr[6] += i['tamount']
    
    context = {
        "rc" : json_data,
        "sum" : sumArr,
    }
    cursor.close()
    return render(request, "reverseCharge.html", context)


