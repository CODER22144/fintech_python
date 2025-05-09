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
from fintech_reports.serializers.payment_report_serializer import PaymentReportSerializer
from fintech_reports.serializers.sales_order_report_serializer import SalesOrderReportSerializer
from fintech_reports.serializers.sales_report_serializer import SalesReportSerializer

# ORDER SLIP

def getReqSlip(request, reqId, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [inven].[uspGetReqSlip] %s",(reqId,))
        json_data = ConvertToJson(cursor)

        # json_data = json.loads(json_data)[0]

        # if(len(json_data['d']) <= 35):
        #     for i in range(len(json_data['d']), 35):
        #         json_data['d'].append({'icode' : ''})

        context = {
            "req" : json_data,
            "init" : json_data[0],

        }
        cursor.close()
        return render(request, "req-slip.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
