from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.material_tech_details_serializer import MaterialTechDetailsSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialTechDetails(request):
    try:
        serializer = MaterialTechDetailsSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddMaterialTechDetails] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateMaterialTechDetails(request):
    try:
        serializer = MaterialTechDetailsSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspUpdateMaterialTechDetails] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteMaterialTechDetails(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [purchase].[uspDeleteMaterialTechDetails] ?", (request.data['matno'],))
        cursor.close()
        return Response({"message": "Material Tech Details deleted successfully"}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialTechDetails(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [purchase].[uspGetMaterialTechDetailsById] ?", (request.data['matno'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialTechDetailsReport(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[MaterialTechDetailsReport] ?", (json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)