from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.inward_details_serializer import InwardDetailSerializer
from cafintech_api.serializers.inward_voucher_serializer import InwardVoucherSerializer, InwardVoucherSingleSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createInwardVoucher(request):
    try:
        inwardSerializer = InwardVoucherSerializer(data=request.data, many=True)
        if(inwardSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddInwardVoucher] ?",(json.dumps(inwardSerializer.data),))
            cursor.close()
            return Response(inwardSerializer.data)
        errors = {}
        if not inwardSerializer.is_valid():
            errors["InwardVoucher"] = inwardSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def importInwardVoucherSingle(request):
    try:
        inwardSerializer = InwardVoucherSingleSerializer(data=request.data, many=True)
        if(inwardSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddInwardVoucherSingle] ?",(json.dumps(inwardSerializer.data),))
            cursor.close()
            return Response(inwardSerializer.data)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getDiscountPercentageType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from mastcode.DiscountPercentType")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)