from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json


from cafintech_api.serializers.cr_note_serializer import CrNoteSerializer
from cafintech_api.serializers.dbnote_details_serializer import DbNoteDetailSerializer
from cafintech_api.serializers.dbnote_serializer import DbNoteSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addDbNoteDetails(request):
    try:
        serializer = DbNoteSerializer(data=request.data)
        serializerDetails = DbNoteDetailSerializer(data=request.data['DbNoteDetails'], many=True)
        if(serializer.is_valid() and serializerDetails.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddDbNote] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        errors = {}
        if not serializer.is_valid():
            errors["DBNote"] = serializer.errors
        if not serializerDetails.is_valid():
            errors["DBNoteDetails"] = serializerDetails.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getDocReason(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select drId,drDescription from [mastcode].[DocReason]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getDocAgainst(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[DocAgainst]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addPRTaxInvoice(request):
    try:
        serializer = DbNoteSerializer(data=request.data)
        serializerDetails = DbNoteDetailSerializer(data=request.data['PRTaxInvoiceDetails'], many=True)
        if(serializer.is_valid() and serializerDetails.is_valid()): 
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddPRTaxInvoice] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        errors = {}
        if not serializer.is_valid():
            errors["PrTaxInvoice"] = serializer.errors
        if not serializerDetails.is_valid():
            errors["PrTaxInvoiceDetails"] = serializerDetails.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCrNote(request):
    try:
        serializer = CrNoteSerializer(data=request.data)
        serializerDetails = DbNoteDetailSerializer(data=request.data['CrNoteDetails'], many=True)
        if(serializer.is_valid() and serializerDetails.is_valid()): 
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [fiac].[uspAddCrNote] %s",(json.dumps(request.data),))
            cursor.close()
            return Response(serializer.data)
        errors = {}
        if not serializer.is_valid():
            errors["CreditNote"] = serializer.errors
        if not serializerDetails.is_valid():
            errors["CreditNoteDetails"] = serializerDetails.errors

        UNSUCCESSFUL_REQUEST['message'] = errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)