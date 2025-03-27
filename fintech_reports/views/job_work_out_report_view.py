from django.db import connections

from django.http import JsonResponse
from django.shortcuts import redirect, render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json
from CaFinTech.settings import File_Path, path_wkhtmltopdf
import pdfkit

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.job_work_out_report_serializer import JobWorkoutReportSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getJobWorkoutReport(request):
    try:
        serializer = JobWorkoutReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [inven].[JobWorkOutReport] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getJobworkoutformat(request, docno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [inven].[uspGetJobWorkOutByDocno] %s",(docno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)[0]

        if(len(json_data['jwd']) <= 35):
            for i in range(len(json_data['jwd']), 35):
                json_data['jwd'].append({'icode' : ''})

        context = {
            "order" : json_data,
        }
        cursor.close()
        return render(request, "jwo.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getJobworkoutformatpdf(request, docno, cid):
    url = 'http://mapp.rcinz.com/get-jwo/'+docno + "/" + cid
    redirectTO = 'JWO_'+docno+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://mapp.rcinz.com/media/docs/'+redirectTO)