from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.inward_details_serializer import InwardDetailSerializer
from cafintech_api.serializers.inward_serializer import InwardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addInward(request):
    try:
        inwardSerializer = InwardSerializer(data=request.data)
        if(inwardSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddInward] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(inwardSerializer.data)
        errors = {}
        if not inwardSerializer.is_valid():
            errors["Inward"] = inwardSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addInwardDetails(request):
    try:
        inwardSerializer = InwardSerializer(data=request.data, many=True)
        if(inwardSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [fiac].[uspAddInward] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(inwardSerializer.data)
        errors = {}
        if not inwardSerializer.is_valid():
            errors["Inward"] = inwardSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getTdsCode(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetTdsType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getSupplierType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [mastcode].[SupplierType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getTdsRate(request, tdsCode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from mastcode.TdsType where TdsCode =  ?",(tdsCode, ))
        json_data = ConvertToJson(cursor)
        if(len(json_data) == 0):
              return Response(data={"error_message" : "Invalid HSN"}, status=500, exception=e)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteInward(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspDeleteInward] ?", (request.data['transId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteInwardVoucher(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[uspDeleteInwardVoucher] ?", (request.data['transId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)