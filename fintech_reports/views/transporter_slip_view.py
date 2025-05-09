from django.db import connections

from django.shortcuts import render
from rest_framework.response import Response
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson

def getTransporterSlip(request, inv, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetTransporterSlip] %s",(inv,))
        json_data = ConvertToJson(cursor)

        # if(len(json_data['itemList']) <= 35):
        #     for i in range(len(json_data['itemList']), 35):
        #         json_data['itemList'].append({'icode' : ''})

        context = {
            "transport" : json_data[0]
        }
        cursor.close()
        return render(request, "transporter_slip_dsp.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

def getAckSlip(request, inv, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [sales].[uspGetSaleAcknowledgment] %s",(inv,))
        json_data = ConvertToJson(cursor)

        # if(len(json_data['itemList']) <= 35):
        #     for i in range(len(json_data['itemList']), 35):
        #         json_data['itemList'].append({'icode' : ''})

        context = {
            "ack" : json_data[0]
        }
        cursor.close()
        return render(request, "acknowledgement_slip.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)