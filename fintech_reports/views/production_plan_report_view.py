from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def productionPlanReport(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [inven].[ProductionPlanRep] ?,?",(request.data['ppId'], request.data['repId']))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)
        cursor.close()
        return Response(json_data, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getProductionPlanRepType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetPPRepType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)