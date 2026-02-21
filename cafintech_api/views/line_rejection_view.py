from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json

from cafintech_api.serializers.line_rejection_serializer import LineRejectionSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addLineRejection(request):
    try:
        serializer = LineRejectionSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [inven].[uspAddLineRejection] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getLineRejectionPending(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [inven].[uspLineRejectionPending] ?",(request.data['bpCode'],))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def deleteLineRejection(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"EXEC [inven].[uspDeleteLineRejection] ?",(request.data['id'],))
        cursor.close()
        return Response({"message": "Line rejection deleted successfully."}, status=200)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)