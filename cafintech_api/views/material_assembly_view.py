from django.db import connections

from django.http import JsonResponse
from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.material_assembly_details_serializer import MaterialAssemblyDetailsSerializer
from cafintech_api.serializers.material_assembly_processing_serializer import MaterialAssemblyProcessingSerializer
from cafintech_api.serializers.material_assembly_serializer import MaterialAssemblySerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialAssembly(request):
    try:
        serializer = MaterialAssemblySerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddMaterialAssembly] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateMaterialAssembly(request):
    try:
        serializer = MaterialAssemblySerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspUpdateMaterialAssembly] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialAssemblyDetails(request):
    try:
        serializer = MaterialAssemblyDetailsSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddMaterialAssemblyDetails] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterialAssemblyProcessing(request):
    try:
        serializer = MaterialAssemblyProcessingSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddMaterialAssemblyProcessing] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialAssemblyByMatno(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspGetMaterialAssemblyById] %s",(request.data['matno'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialAssemblyDetailsByMatno(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspGetMaterialAssemblyDetailsBymatno] %s",(request.data['matno'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getMaterialAssemblyProcessingByMatno(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspGetMaterialAssemblyProcessingBymatno] %s",(request.data['matno'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteMaterialAssembly(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspDeleteMaterialAssembly] %s",(request.data['matno'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteMaterialAssemblyDetails(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspDeleteMaterialAssemblyDetails] %s",(request.data['madId'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteMaterialAssemblyProcessing(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspDeleteMaterialAssemblyProcessing] %s",(request.data['mapId'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

def getMaterialAssemblyBreakup(request, matno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [cost].[getMaterialAssembly] %s",(matno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)

        context = {
            "mat" : json_data[0],
        }

        cursor.close()
        return render(request, "material_assembly.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getProductBreakup(request, matno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [cost].[getProductBreakup] %s",(matno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)

        context = {
            "mat" : json_data[0],
        }

        cursor.close()
        return render(request, "product_breakup.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getPartAssembly(request, matno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [cost].[getPartAssembly] %s",(matno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)

        context = {
            "mat" : json_data[0],
        }

        cursor.close()
        return render(request, "part_assembly.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
def getPartSubAssembly(request, matno, cid):
    try:
        cursor = connections[cid].cursor()
        cursor.execute(f"EXEC [cost].[getPartSubAssembly] %s",(matno,))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)

        context = {
            "mat" : json_data[0],
        }

        cursor.close()
        return render(request, "part_sub_assembly.html", context)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
