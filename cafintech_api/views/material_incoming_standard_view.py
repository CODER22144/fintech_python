from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.ledger_codes_serializer import LedgerCodesSerializer
from cafintech_api.serializers.material_incoming_standard_serializer import MaterialIncomingStandardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialIncomingStandard(request):
    try:
        serializer = MaterialIncomingStandardSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddMaterialIncomingStandard] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllMaterialIncomingStandard(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetMaterialIncomingStandard]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteMaterialIncomingStandard(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspDeleteMaterialIncomingStandard] %s", (request.data['misId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getTestType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select testName, testName as [name] from [mastcode].[TestType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)