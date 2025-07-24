from django.db import connections

from django.http import HttpResponse, JsonResponse
from django.shortcuts import redirect, render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.settings import File_Path, path_wkhtmltopdf
import pdfkit
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.financial_crnote_serializer import FinacialCreditNoteSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.payment_report_serializer import PaymentReportSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createFinancialCreditNote(request):
    try:
        serializer = FinacialCreditNoteSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddFinancialCrnote] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getTodRate(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from mastcode.RateTod")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCreditNoteType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetFcnType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getFinancialCrNoteReport(request):
    try:
        serializer = PaymentReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"exec [fiac].[uspGetFinancialCrnoteReport] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getFcsno(request, inv, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"exec [fiac].[uspGetFinancialById] %s",(inv,))
        json_data = ConvertToJson(cursor)

        empty = [x for x in range(0, 30)]

        context = {
            "fiac" : json_data[0],
            "empty" : empty,
        }
        cursor.close()
        return render(request, "fcn_dsp.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getFcsnoPdf(request, fcns, cid):
    url = 'http://erpapi.rcinz.com/get-fcsno/'+fcns + "/" + cid
    redirectTO = 'FCNS_'+fcns+'_'+cid+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://erpapi.rcinz.com/media/docs/'+redirectTO)