from django.db import connections
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
from cafintech_api.serializers.export_order_serializer import ExportOrderSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

import json

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addExpOrder(request):
    try:
        serializer = ExportOrderSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC sales.uspAddExpOrder %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateExpOrder(request):
    try:
        serializer = ExportOrderSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [sales].[uspUpdateExpOrder] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteExpOrder(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [sales].[uspDeleteExpOrder] %s", (request.data['orderId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getExpOrderById(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [sales].[uspGetExpOrderById] %s", (request.data['orderId'], ))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCurrency(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetCurrency]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCurrency(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetCurrency]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPorts(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetPort]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

