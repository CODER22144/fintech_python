from django.db import connections

from rest_framework.response import Response
from CaFinTech.utility import generate_error_message, getDbCursor
from cafintech_api.views.bill_receipt_view import ConvertToJson

# ORDER SLIP

def getReqSlip(request, reqId, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [inven].[uspGetReqSlip] ?",(reqId,))
        json_data = ConvertToJson(cursor)

        # json_data = json.loads(json_data)[0]

        # if(len(json_data['d']) <= 35):
        #     for i in range(len(json_data['d']), 35):
        #         json_data['d'].append({'icode' : ''})

        context = {
            "req" : json_data,
            "init" : json_data[0],

        }
        cursor.close()
        return render(request, "req-slip.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
