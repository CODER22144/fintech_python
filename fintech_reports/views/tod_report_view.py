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
    
def getTodReport(request):
    bpCode = request.GET.get('bpCode')
    periodId = request.GET.get('periodId')
    stateid = request.GET.get('stateid')
    cursor = connections[request.GET.get('cid')].cursor()

    json_input = {
        "bpCode": bpCode if bpCode != 'null' else None,
        "periodId": periodId,
        "stateid": stateid if stateid != 'null' else None
    }
    
    cursor.execute(f"EXEC [sales].[TodReport] %s", (json.dumps(json_input),))
    json_data = [data[0] for data in cursor.fetchall()]
    json_data = "".join(json_data)
    json_data = json.loads(json_data if json_data != '' else "[]")

    sumArr = [0,0,0,0,0,0,0,0,0,]


    for i in json_data:
        sumArr[0] += i['samount']
        sumArr[1] += i['ramount']
        sumArr[2] += i['todamount']
        sumArr[3] += i['todrate']
        sumArr[4] += i['tod1amount']
        sumArr[5] += i['tod2amount']
        sumArr[6] += i['tod3amount']
        sumArr[7] += i['tod4amount']
        sumArr[8] += i['tod5amount']
        
    
    context = {
        "tod" : json_data,
        "sum" : sumArr,
    }
    cursor.close()
    return render(request, "tod.html", context)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPeriod(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetCalPeriod]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)