from django.db import connections

from django.shortcuts import render
from rest_framework.response import Response
from CaFinTech.utility import generate_error_message, getDbCursor
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
import json

from fintech_reports.serializers.ledger_report_serializer import LedgerReportSerializer
from fintech_reports.serializers.ledger_serializer import LedgerSerializer
from fintech_reports.serializers.trial_balance_report_serializer import TrialBalanceReportSerializer


def getLedgerReport(request):
    try:
        lcode = request.GET.get("lcode")
        fromDate = request.GET.get("fromDate")
        toDate = request.GET.get("toDate")

        serializer = LedgerSerializer(data={'lcode':lcode, 'fromDate':fromDate, 'toDate':toDate})    
        if(serializer.is_valid()):
            cursor = connections[request.GET.get("cid")].cursor()
            cursor.execute(f"EXEC [fiac].[uspGetLedger] ?",(json.dumps(serializer.data),))
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
            cursor.execute(f"EXEC [fiac].[uspGetTrial] ?",(json.dumps(serializer.data),))
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
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getLedgerRep(request):
    try:
        serializer = LedgerReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [gl].[uspGetGeneralLedger] ?",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getTrialBalanceReport(request):
    try:
        serializer = TrialBalanceReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspGetTrial] ?",(json.dumps(serializer.data),))
            json_data = [data[0] for data in cursor.fetchall()]
            json_data = "".join(json_data)
            cursor.close()
            return Response(json.loads(json_data))
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)