from django.db import connections

from django.shortcuts import render, redirect
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json


from CaFinTech.settings import File_Path, path_wkhtmltopdf
import pdfkit
from fintech_reports.serializers.gr_report_serializer import GrReportSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getGrRep(request):
    try:
        serializer = GrReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[GRRep] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def srvFormat(request, grno, cid):
    cursor = connections[cid].cursor()
    serializer = GrReportSerializer(data={"grno" : grno})
    if(serializer.is_valid()):
        cursor.execute(f"EXEC [purchase].[GRRep] %s",(json.dumps(serializer.data),))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)

        json_data = json.loads(json_data)[0]

        if len(json_data['grd']) < 15:
            for i in range(len(json_data['grd']), 15):
                json_data['grd'].append({})

        context = {
            "gr" : json_data,
        }
        cursor.close()
        return render(request, "srvformat.html", context)
    
def srvFormatPdf(request, grno, cid):
    url = 'http://mapp.rcinz.com/srv/'+grno + "/" +cid
    redirectTO = 'SRV'+grno+'.pdf'
    filename = File_Path + "\\" +redirectTO
    
    config = pdfkit.configuration(wkhtmltopdf=path_wkhtmltopdf)
    pdfkit.from_url(url,filename, configuration=config)
    return redirect('http://mapp.rcinz.com/media/docs/'+redirectTO)