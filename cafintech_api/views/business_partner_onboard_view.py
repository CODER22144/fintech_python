from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.business_partner_onboard_serializer import BusinessPartnerOnboardSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBusinessPartnerOnBoard(request):
    try:
        serializer = BusinessPartnerOnboardSerializer(data=request.data)     # CAN HAVE IMPORT HERE
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspAddBusinessPartnerOnBoard] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def UpdateBusinessPartnerOnBoard(request):
    try:
        serializer = BusinessPartnerOnboardSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [cost].[uspUpdateBusinessPartnerOnBoard] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBusinessPartnerOnBoardByMatno(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspGetBusinessPartnerOnBoardById] %s",(request.data['bpCode'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteBusinessPartnerOnBoard(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [cost].[uspDeleteBusinessPartnerOnBoard] %s",(request.data['bpCode'],))
        cursor.close()
        return Response({'message': 'Deleted successfully'})
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getBpOnBoardReport(request):
    try:        
        cursor = connections[request.user.cid.cid].cursor()

        json_data = {"bpName" : request.data['bpName'], "bpState" : request.data['bpState']}

        cursor.execute(f"EXEC [cost].[BusinessPartnerOnBoardRep] %s",(json.dumps(json_data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)  
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)