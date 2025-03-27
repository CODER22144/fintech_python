from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.dl_challan_serializer import DlChallanDetailSerializer, DlChallanSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addDlChallan(request):
    try:
        serializer = DlChallanSerializer(data=request.data)
        serializerDetails = DlChallanDetailSerializer(data=request.data['DlChallanDetails'], many=True)
        if(serializer.is_valid() and serializerDetails.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [inven].[uspAddDlChallan] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        errors = {}
        if not serializer.is_valid():
            errors["DLChallan"] = serializer.errors
        if not serializerDetails.is_valid():
            errors["DLChallan_Details"] = serializerDetails.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getChallanType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspGetDlChallanType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)