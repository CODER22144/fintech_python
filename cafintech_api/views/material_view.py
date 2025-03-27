from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.material_serializer import MaterialSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterial(request):
    try:
        serializer = MaterialSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[uspAddMaterial] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getHSNCode(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select hsnCode, hsnShortDescription from [mastcode].[HSN]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialUnit(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetMaterialUnit]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetMaterialType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialGroup(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetMaterialGroup]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialSubGroup(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[MaterialSubGroup]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterial(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select matno, matDescription from [purchase].[Material]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialStatus(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[MaterialStatus]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getItemType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[ItemType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialDetails(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [purchase].[uspGetMaterialDetails] %s",(matno,))
        json_data = ConvertToJson(cursor)
        if(len(json_data) == 0 and matno != ""):
              return Response(data={"error_message" : "Invalid Material No : "+matno}, status=500, exception=e)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialDiscountType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[DiscountMaterialType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateMaterial(request):
    try:
        serializer = MaterialSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [purchase].[uspUpdateMaterial] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByIdMaterial(request, matno):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [purchase].[uspGetByIdMaterial] %s",(matno,))
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAcGroups(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetAcGroups]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)