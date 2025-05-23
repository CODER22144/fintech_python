from django.db import connections

from django.shortcuts import render
from rest_framework.response import Response
from CaFinTech.utility import generate_error_message
import json

from fintech_reports.serializers.ledger_serializer import LedgerSerializer


def getLedgerReport(request):
    try:
        lcode = request.GET.get("lcode")
        fromDate = request.GET.get("fromDate")
        toDate = request.GET.get("toDate")

        serializer = LedgerSerializer(data={'lcode':lcode, 'fromDate':fromDate, 'toDate':toDate})    
        if(serializer.is_valid()):
            cursor = connections[request.GET.get("cid")].cursor()
            cursor.execute(f"EXEC [fiac].[uspGetLedger] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()

        context = {
            "ledger" : json.loads(json_data),
        }
        cursor.close()
        return render(request, "ledger.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getTrail(request):
    try:
        agCode = request.GET.get("agCode")
        fromDate = request.GET.get("fromDate")
        toDate = request.GET.get("toDate")

        serializer = LedgerSerializer(data={'agCode':agCode, 'fromDate':fromDate, 'toDate':toDate})    
        if(serializer.is_valid()):
            cursor = connections[request.GET.get("cid")].cursor()
            cursor.execute(f"EXEC [fiac].[uspGetTrial] %s",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()

        context = {
            "trial" : json.loads(json_data),
        }
        cursor.close()
        return render(request, "trial.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)