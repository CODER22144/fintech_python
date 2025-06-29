from django.db import connections

from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json

from cafintech_api.serializers.payment_inward_clear_serializer import PaymentInwardClearSerializer
from cafintech_api.serializers.unadjusted_payment_inward_clear_serializer import UnadjustedPaymentInwardClearSerializer


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPaymentInwardClear(request):
    try:
        serializer = PaymentInwardClearSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspUnadjustedPaymentInwardClear] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addUnadjustedPaymentInwardClear(request):
    try:
        serializer = UnadjustedPaymentInwardClearSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddUnAdjustedPaymentInwardClear] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addUnAdjustedPaymentClear(request):
    try:
        serializer = UnadjustedPaymentInwardClearSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddUnAdjustedPaymentClear] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)