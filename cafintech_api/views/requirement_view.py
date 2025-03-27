from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.requirement_serializer import RequirementSerializer
from cafintech_api.serializers.requirement_details_serializer import RequirementDetailSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addReq(request):
    try:
        serializer = RequirementSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [inven].[uspAddReq] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addReqDetails(request):
    try:
        serializer = RequirementSerializer(data=request.data)
        serializerDetails = RequirementDetailSerializer(data=request.data['ReqDetails'], many=True)
        if(serializerDetails.is_valid() and serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [inven].[uspAddReqManual] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializerDetails.data)
        errors = {}
        if not serializer.is_valid():
            errors["Req"] = serializer.errors
        if not serializerDetails.is_valid():
            errors["Req_Details"] = serializerDetails.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getReqMode(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspGetReqMode]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getReqType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspGetReqType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getDepartment(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [inven].[uspGetDepartment]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
