from django.db import connections

from django.http import JsonResponse
from django.shortcuts import render
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.bp_breakup_details_serializer import BpBreakupDetailsSerializer
from cafintech_api.serializers.bp_breakup_processing_serializer import BpBreakupProcessingSerializer
from cafintech_api.serializers.bp_breakup_serializer import BpBreakupSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBpBreakup(request):
    try:
        serializer = BpBreakupSerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddBpBreakup] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateBpBreakup(request):
    try:
        serializer = BpBreakupSerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspUpdateBpBreakup] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBpBreakupDetails(request):
    try:
        serializer = BpBreakupDetailsSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddBpBreakupDetails] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBpBreakupProcessing(request):
    try:
        serializer = BpBreakupProcessingSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [cost].[uspAddBpBreakupProcessing] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBybpbIdBPBreakup(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBPBreakupById] ?,?",(request.data['bpCode'],request.data['matno']))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBybpbIdBPBreakupDetails(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBpBreakupDetailsById] ?,?",(request.data['bpCode'],request.data['pId']))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBybpbIdBPBreakupProcessing(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBPBreakupProcessingById] ?,?",(request.data['bpCode'],request.data['matno']))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteBpBreakup(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspDeleteBpBreakup] ?",(request.data['bpbId'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteBpBreakupDetails(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspDeleteBpBreakupDetails] ?",(request.data['bpbdId'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteBpBreakupProcessing(request):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspDeleteBpBreakupProcessing] ?",(request.data['bpbpId'],))
        cursor.close()
        return Response({'message': 'Material deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getObMaterialbyObBpCode(request, bpCode):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerObMaterialDropdown] ?", (bpCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getObMaterialDropdown(request, bpCode):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerObMaterialMatnoDropdown] ?", (bpCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getPid(request, bpCode):
    try:        
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerProcessingDropdown] ?", (bpCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    


def getBpBreakupReport(request):
    try:        
        bpCode = request.GET.get("bpCode")
        matno = request.GET.get("matno")
        cursor = connections[request.GET.get("cid")].cursor()
        cursor.execute(f"EXEC [cost].[getBPBreakup] ?,?", (bpCode,matno))
        json_data = [data[0] for data in cursor.fetchall()]
        json_data = "".join(json_data)
        json_data = json.loads(json_data)[0]
        

        context = {
            "data" : json_data,
        }
        cursor.close()
        return render(request, "breakup.html", context)
    
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
