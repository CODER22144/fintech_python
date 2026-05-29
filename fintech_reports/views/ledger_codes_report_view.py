from django.db import connections

from django.http import JsonResponse
from django.shortcuts import redirect, render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.settings import File_Path, path_wkhtmltopdf
from CaFinTech.utility import generate_error_message, getDbCursor, getDbCursorByCid
import json
import pdfkit
import uuid

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.ledger_code_report import LedgerCodeReportSerializer
from fintech_reports.serializers.ledger_report_serializer import LedgerReportSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getLedgerCodeReport(request):
    try:
        serializer = LedgerCodeReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspGetLedgerCodes] ?",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getLedgersReport(request):
    try:
        serializer = LedgerReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [gl].[uspGetLedger] ?",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getLedgerReportPDF(request):
    try:
        lcode = request.GET.get("lcode")
        fromDate = request.GET.get("fromDate")
        toDate = request.GET.get("toDate")

        serializer = LedgerReportSerializer(data={'lcode':lcode, 'fromDate':fromDate, 'toDate':toDate})    
        if(serializer.is_valid()):
            cursor = getDbCursorByCid(request.GET.get("cid"))
            cursor.execute(f"EXEC [gl].[uspGetLedger] ?",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()

        context = {
            "ledger" : json.loads(json_data),
        }
        return render(request, "ledger_pdf.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

def convertToPdf(request):
    lcode = request.GET.get("lcode")
    fromDate = request.GET.get("fromDate")
    toDate = request.GET.get("toDate")
    cid = request.GET.get("cid")

    url = f'http://remoteapi.rcinz.com/get-ledger-report-html/?fromDate={fromDate}&toDate={toDate}&lcode={lcode}&cid={cid}'
    redirectTO = 'LG_'+lcode+'_'+str(uuid.uuid4())+'.pdf'
    filename = File_Path + "\\ledger\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://remoteapi.rcinz.com/media/docs/ledger/'+redirectTO)