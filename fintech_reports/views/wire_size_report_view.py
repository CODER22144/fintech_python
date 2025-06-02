from django.db import connections

from django.shortcuts import render
from rest_framework.response import Response
from CaFinTech.utility import generate_error_message
import json

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
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()

        context = {
            "ws" : json.loads(json_data),
        }
        cursor.close()
        return render(request, "wire_size.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
