import json
from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message

from cafintech_api.views.bill_receipt_view import ConvertToJson
from fintech_reports.serializers.bp_ob_material_report_serializer import BPObMaterialReportSerializer
from fintech_reports.serializers.ob_material_report_serializer import OBMaterialReportSerializer

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBusinessPartnerObMaterialReport(request):
    try:
        serializer = BPObMaterialReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[uspBusinessPartnerObMaterialReport] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
