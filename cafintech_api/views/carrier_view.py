from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.carrier_serializer import CarrierSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCarrier(request):
    try:
        serializer = CarrierSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspAddCarrier] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateCarrier(request):
    try:
        serializer = CarrierSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspUpdateCarrier] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getByIdCarrier(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetCarrier] ?", (json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteCarrier(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspDeleteCarrier] ?", (request.data['carId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getAllCarrier(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetCarrier] ?", (json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)