from django.db import connections

from django.shortcuts import render, redirect
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from CaFinTech.settings import File_Path, path_wkhtmltopdf
from fintech_reports.serializers.purchase_order_item_report_serializer import PurchaseOrderItemReportSerializer
from fintech_reports.serializers.purchase_order_report_serailizer import PurchaseOrderReportSerializer
import pdfkit


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getPurchaseOrderDetails(request):
    try:
        serializer = PurchaseOrderReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[PurchaseOrderRep] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)


def purchaseOrderInvoice(request, orderId,cid):
    cursor = connections[cid].cursor()
    serializer = PurchaseOrderReportSerializer(data={"poId" : orderId})
    if(serializer.is_valid()):
        cursor.execute(f"EXEC [purchase].[uspGetPurchaseOrderByPoId] %s",(orderId,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        context = {
            "data" : json.loads(json_data)[0],
        }
        cursor.close()
        return render(request, "po_order.html", context)
    
def convertToPdf(request, orderId, cid):
    url = 'http://erpapi.rcinz.com/purchase-order-invoice/'+orderId + "/" +cid
    redirectTO = 'PRO'+orderId+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://erpapi.rcinz.com/media/docs/'+redirectTO)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getPurchaseOrderItemReport(request):
    try:
        serializer = PurchaseOrderItemReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[PurchaseOrderItemRep] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)