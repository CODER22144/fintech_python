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
from fintech_reports.serializers.gr_report_serializer import GrReportSerializer
    
def grDetails(request):
    carId = request.GET.get('carId')
    fromDate = request.GET.get('fromDate')
    toDate = request.GET.get('toDate')
    cursor = connections[request.GET.get('cid')].cursor()

    json_input = {
        "carId": carId,
        "fromDate": fromDate,
        "toDate": toDate
    }
    
    cursor.execute(f"EXEC [sales].[uspGetGrDetails] %s", (json.dumps(json_input),))
    json_data = [data[0] for data in cursor.fetchall()]
    json_data = "".join(json_data)
    json_data = json.loads(json_data)

    tax = 0
    amount = 0
    freight = 0


    for i in json_data:
        tax += i['sumtaxableAmount']
        amount += i['sumtamount']
        if(i['freight'] is not None):
            freight += i['freight']
    
    context = {
        "grDetails" : json_data,
        "tax" : tax,
        "amount" : amount,
        "freight" : freight if freight != 0 else None
    }
    cursor.close()
    return render(request, "grDetails.html", context)