from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.edit_material_source_serializer import EditMaterialSourceSerializer
from cafintech_api.serializers.material_source_serializer import MaterialSourceSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialSource(request):
    try:
        serializer = MaterialSourceSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspAddMaterialSource] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
      
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getMaterialSourceDetails(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetBybpCodematnoMaterialSource] ?,?",(request.data['bpCode'], request.data['matno']))
        json_data = ConvertToJson(cursor)
        if(len(json_data) == 0 and request.data['matno'] != ""):
              return Response(data={"error_message" : "Invalid Material No : "+request.data['matno']}, status=500, exception=e)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateMaterialSource(request):
    try:
        serializer = MaterialSourceSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspUpdateMaterialSource] ?",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def editMaterialSourceBulk(request):
    try:
        serializer = EditMaterialSourceSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddMaterialSourceBulkUpdate] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteMaterialSource(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspDeleteMaterialSource] ?", (request.data['msId'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)