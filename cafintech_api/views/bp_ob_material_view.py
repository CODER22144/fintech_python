from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.bp_ob_material_serializer import BusinessPartnerObMaterialSerializer
from cafintech_api.serializers.business_partner_onboard_serializer import BusinessPartnerOnboardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBusinessPartnerObMaterial(request):
    try:
        serializer = BusinessPartnerObMaterialSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddBusinessPartnerObMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def UpdateBusinessPartnerObMaterial(request):
    try:
        serializer = BusinessPartnerObMaterialSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspUpdateBusinessPartnerObMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBusinessPartnerObMaterialById(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerObMaterialByBpCodeMatno] ?,?",(request.data['bpCode'],request.data['matno']))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteBusinessPartnerObMaterial(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspDeleteBusinessPartnerObMaterial] ?",(request.data['bpmId'],))
        cursor.close()
        return Response({'message': 'Deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getBpObDropdown(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerOnBoardDropdown]")
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

# @api_view(['POST'])
# @permission_classes([IsAuthenticated])
# def getBpOnBoardReport(request):
#     try:        
#         cursor = getDbCursor(request.user)
#         cursor.execute(f"EXEC [cost].[BusinessPartnerObMaterialRep] ?,?",(request.data['bpName'],request.data['bpState']))
#         json_data = ConvertToJson(cursor)
#         cursor.close()
#         return JsonResponse(json_data, safe=False)  
#     except Exception as e:
#         return Response(generate_error_message(e), status=500, exception=e)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def UpdateBulkBusinessPartnerObMaterial(request):
    try:
        serializer = BusinessPartnerObMaterialSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspBulkUpdateBusinessPartnerObMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)