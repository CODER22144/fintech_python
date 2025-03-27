from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.production_plan_serializer import ProductionPlanSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductionPlan(request):
    try:
        serializer = ProductionPlanSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [inven].[uspAddProductionPlan] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByIdProductionPlan(request, ppid):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspGetByIdProductionPlan] %s", (ppid, ))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteProductionPlan(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspDeleteProductionPlan] %s", (request.data['ppid'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteAllProductionPlan(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspDeleteAllProductionPlan] %s", (request.data['ppid'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
