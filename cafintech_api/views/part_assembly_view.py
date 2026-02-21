from django.db import connections

from cafintech_api.serializers.part_assembly_detail_serializer import PartAssemblyDetailSerializer
from cafintech_api.serializers.part_assembly_processing_serializer import PartAssemblyProcessingSerializer
from cafintech_api.serializers.part_assembly_serializer import PartAssemblySerializer
from cafintech_api.serializers.payment_serializer import PaymentSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWorkProcess(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetWorkProcess]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getRmType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].uspGetRmType")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPartAssemblyByMatno(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetPartAssemblyByMatno] ?", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPartAssemblyDetailsByMatno(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetPartAssemblyDetailsBymatno] ?", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPartAssemblyProcessingByMatno(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspGetPartAssemblyProcessingBymatno] ?", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPartAssembly(request):
    try:
        serializer = PartAssemblySerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddPartAssembly] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPartAssemblyDetails(request):
    try:
        serializer = PartAssemblyDetailSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddPartAssemblyDetails] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPartAssemblyProcessing(request):
    try:
        serializer = PartAssemblyProcessingSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddPartAssemblyProcessing] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deletePartAssembly(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspDeletePartAssembly] ?", (matno, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deletePartAssemblyDetails(request, padId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspDeletePartAssemblyDetails] ?", (padId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deletePartAssemblyProcessing(request, papId):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[uspDeletePartAssemblyProcessing] ?", (papId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getPartAssemblyReport(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [cost].[PartAssemblyReport] ?", (request.data['matno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json_data)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getWorkInProgress(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [inven].[wip]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updatePartAssembly(request):
    try:
        serializer = PartAssemblySerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspUpdatePartAssembly] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)