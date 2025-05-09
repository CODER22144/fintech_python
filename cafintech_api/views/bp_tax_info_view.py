from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json
from cafintech_api.serializers.bp_tax_info_serializer import BusinessPartnerTaxInfoSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createBusinessPartnerTaxInfo(request):
    try:
        serializer = BusinessPartnerTaxInfoSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [mastcode].[uspAddBPPayNTaxInfo] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateBusinessPartnerTaxInfo(request):
    try:
        serializer = BusinessPartnerTaxInfoSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [mastcode].[uspUpdateBPPayNTaxInfo] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getBpTaxInfoById(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetByIdBPPayNTaxInfo] %s", (request.data['taxId'], ))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)