from django.db import connections

from cafintech_api.serializers.product_breakup_details_serializer import ProductBreakupDetailSerializer
from cafintech_api.serializers.product_breakup_processing_serializer import ProductBreakupProcessingSerializer
from cafintech_api.serializers.product_breakup_serializer import ProductBreakupSerializer
from cafintech_api.serializers.product_breakup_tech_details_serializer import ProductBreakupTechDetailSerializer
from cafintech_api.serializers.product_final_standaard_serializer import ProductFinalStandardSerializer
from cafintech_api.serializers.rm_in_process_standard_serializer import RmInProcessStandardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getProductBreakupByMatno(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetProductBreakupByMatno] %s", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getProductBreakupDetailsByMatno(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetProductBreakupDetailsBymatno] %s", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getProductBreakupProcessingByMatno(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspGetProductBreakupProcessingBymatno] %s", (matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductBreakup(request):
    try:
        serializer = ProductBreakupSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddProductBreakup] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductBreakupDetails(request):
    try:
        serializer = ProductBreakupDetailSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddProductBreakupDetails] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductBreakupProcessing(request):
    try:
        serializer = ProductBreakupProcessingSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddProductBreakupProcessing] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteProductBreakup(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspDeleteProductBreakup] %s", (matno, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteProductBreakupDetails(request, padId):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspDeleteProductBreakupDetails] %s", (padId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteProductBreakupProcessing(request, papId):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[uspDeleteProductBreakupProcessing] %s", (papId, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductBreakup_TechDetails(request):
    try:
        serializer = ProductBreakupTechDetailSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddProductBreakup_TechDetails] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addRmInprocessStandard(request):
    try:
        serializer = RmInProcessStandardSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC  %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addProductFinalStandard(request):
    try:
        serializer = ProductFinalStandardSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddProductFinalStandard] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getProductBreakupReport(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [cost].[ProductBreakupReport] %s", (request.data['matno'],))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json_data)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)