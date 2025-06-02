from django.db import connections

from django.shortcuts import render
from rest_framework.response import Response
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.wire_size_report_serializer import WireSizeReportSerializer

def getWireSizeReport(request):
    try:
        matno = request.GET.get("matno")
        repId = request.GET.get("repId")
        soId = request.GET.get("soId")

        serializer = WireSizeReportSerializer(data={'matno':matno, 'repId':repId, 'soId':soId})    
        if(serializer.is_valid()):
            cursor = connections[request.GET.get("cid")].cursor()
            cursor.execute(f"EXEC [cost].[WireSizeTl] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            

        context = {
            "ws" : json_data[0],
            "details" : json.loads(json_data[0]['wiredetail'])
        }
        cursor.close()
        return render(request, "wire_size.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
