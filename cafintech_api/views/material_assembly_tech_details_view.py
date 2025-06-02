from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.material_assembly_tech_details_serializer import MaterialAssemblyTechDetailsSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialAssemblyTechDetails(request):
    try:
        serializer = MaterialAssemblyTechDetailsSerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddMaterialAssemblyTechDetails] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def UpdateMaterialAssemblyTechDetails(request):
    try:
        serializer = MaterialAssemblyTechDetailsSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspUpdateMaterialAssemblyTechDetails] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialAssemblyTechDetailsById(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspGetMaterialAssemblyTechDetailsById] %s",(request.data['matno'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteMaterialAssemblyTechDetails(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspDeleteMaterialAssemblyTechDetails] %s",(request.data['matno'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
