from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.wire_size_details_serializer import WireSizeDetailSerializer
from cafintech_api.serializers.wize_size_serializer import WireSizeSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addWireSizeDetails(request):
    try:
        serializer = WireSizeSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddWireSize] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWireSizeByMatNo(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetWireSizeBymatno] ?",(matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCostStatus(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetCostStatus]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWireSizeDetailsByMatNo(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetWireSizeDetailsBymatno] ?",(matno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        return Response(json.loads(json_data))
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteWholeWireSizeDetails(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspDeleteWireSize] ?", (request.data['matno'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteSpecificWireDetail(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspDeleteWireSizeDetails] ?", (request.data['wireno'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addWireSizeMasterDetailsOnly(request):
    try:
        detailsSerializer = WireSizeDetailSerializer(data=request.data, many=True)
        if(detailsSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddWireSizeDetails] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(detailsSerializer.data)
        UNSUCCESSFUL_REQUEST['message'] = detailsSerializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateWireSizeDetails(request):
    try:
        detailsSerializer = WireSizeDetailSerializer(data=request.data)
        if(detailsSerializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspUpdateWireSizeDetails] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(detailsSerializer.data)
        UNSUCCESSFUL_REQUEST['message'] = detailsSerializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateWireSizeMaster(request):
    try:
        serializer = WireSizeSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspUpdateWireSize] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getColorCodes(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetColourCode]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWireRepType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetWireRepType]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWireSortType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetWireSortType]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)