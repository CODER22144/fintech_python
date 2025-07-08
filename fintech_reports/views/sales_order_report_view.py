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
import pdfkit

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.payment_pending_serializer import PaymentPendingSerializer
from fintech_reports.serializers.payment_report_serializer import PaymentReportSerializer
from fintech_reports.serializers.sales_order_report_serializer import SalesOrderReportSerializer
from fintech_reports.serializers.sales_report_serializer import SalesReportSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getSalesOrderReport(request):
    try:
        request.data['userid'] = request.user.userId
        request.data['roleid'] = request.user.roles.role_id
        serializer = SalesOrderReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[uspGetOrderReport] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

def getSaleOrderByOrderId(request, orderId, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetOrderByorderId] %s",(orderId,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)[0]

        if(len(json_data['d']) <= 35):
            for i in range(len(json_data['d']), 35):
                json_data['d'].append({'icode' : ''})

        context = {
            "order" : json_data,
        }
        cursor.close()
        return render(request, "proforma.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def convertSaleOrderToPdf(request, orderId, cid):
    url = 'http://mapp.rcinz.com/get-sales-order/'+orderId + "/" + cid
    redirectTO = 'SO_'+orderId+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://mapp.rcinz.com/media/docs/'+redirectTO)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
# PART OF SALES ORDER
def getPaymentPending(request):
    try:
        serializer = PaymentPendingSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspGetPaymentPending] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
# SALES REPORT
def getSalesReport(request):
    try:
        request.data['userid'] = request.user.userId
        request.data['roleid'] = request.user.roles.role_id
        serializer = SalesReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[uspGetSaleReport] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            print(json_data)
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
# ORDER SLIP

def getOrderSlip(request, orderId, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetOrderByorderId] %s",(orderId,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)[0]

        if(len(json_data['d']) <= 35):
            for i in range(len(json_data['d']), 35):
                json_data['d'].append({'icode' : ''})

        context = {
            "order" : json_data,
        }
        cursor.close()
        return render(request, "order_slip.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getOrderStatus(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [sales].[uspGetOrderProcessed] %s",(request.data['orderId'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getOrderClearValue(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [sales].[GetOrderClearValue] %s",(request.data['orderId'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getEInvoicePending(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec  [sales].[uspGetEInvoicePending] %s,%s",(request.user.userId,request.user.roles.role_id))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)