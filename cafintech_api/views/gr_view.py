from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.gr_details_serailizer import GrDetailSerializer
from cafintech_api.serializers.gr_serializer import GRSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addGrDetails(request):
    try:
        grSerializer = GRSerializer(data=request.data)
        grDetailsSerializer = GrDetailSerializer(data=request.data['GrDetails'], many=True)
        if(grSerializer.is_valid() and grDetailsSerializer.is_valid()):
            param = grSerializer.data
            param['GrDetails'] = grDetailsSerializer.data
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddGr] ?",(json.dumps(param),))
            cursor.close()
            return Response(grSerializer.data)
        errors = {}
        if not grSerializer.is_valid():
            errors["Master"] = grSerializer.errors
        if not grDetailsSerializer.is_valid():
            errors["Details"] = grDetailsSerializer.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def validPurchaseOrder(request, bpCode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetValidPurchaseOrderBybpCode] ?",(bpCode,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getPendingGr(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetPendingGr]")
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json.loads(json_data))
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGrByGrno(request, grno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetGrByGrNo] ?", (grno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        cursor.close()
        return Response(json.loads(json_data))
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteGr(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [docen].[uspDeleteGr] ?,?", (request.data['grno'], request.user.roles.role_id))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGrShortage(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGrShortagePending]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGrRejection(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGrRejectionPending]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGrRateApprovalPending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetGrRateApprovalPending]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def debitNoteRateDifference(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[DbNoteRateDifference] ?", (request.data['grno'], ))
        return JsonResponse({"status" : "OK"}, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def debitNoteShortage(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[DbNoteShortage] ?", (request.data['grno'], ))
        return JsonResponse({"status" : "OK"}, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def debitNoteRejection(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [fiac].[DbNoteRejection] ?", (request.data['grno'], ))
        return JsonResponse({"status" : "OK"}, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getExportDataForGr(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [sales].[uspGetSaleDetailsGrData] ?", (request.data['docno'], ))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)