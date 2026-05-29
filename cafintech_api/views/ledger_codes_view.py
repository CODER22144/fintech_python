from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor, getDbCursor
import json
import pandas as pd

from cafintech_api.serializers.ledger_codes_serializer import LedgerCodesSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addLedgerCodes(request):
    try:
        serializer = LedgerCodesSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspAddLedgerCodes] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getLedgerTitle(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select LTitle, LTitle as displayField from [mastcode].[LedgerTitle]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getLedgerStatus(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetLedgerStatus]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getSupplyType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetGstSupplyType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getLedgerType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetLedgerType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAccountGroups(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetAcGroups]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getLedgerCode(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetLedgerCodesDropDown]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByIdLedgerCode(request, lCode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetLedgerCodesById] ?",(lCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateLedgerCodes(request):
    try:
        serializer = LedgerCodesSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspUpdateLedgerCodes] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
        
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getLedgerCodeSupply(request, lCode):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetLedgerCodesSupply] ?",(lCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGstRegenType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetGSTRegnType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteLedgerCodes(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspDeleteLedgerCodes] ?", (request.data['lcode'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def importLedgerCodes(request):
    try:
        cursor = getDbCursor(request.user)

        if 'file' not in request.FILES:
            return Response(
                {"message": "No file uploaded. Please include a file with the field name 'file'."}, 
                status=400
            )
            
        # Get the uploaded file object
        excel_file = request.FILES['file']

        if not excel_file.name.endswith(('.xls', '.xlsx')):
             return Response(
                {"message": "Invalid file type. Please upload an Excel file (.xls or .xlsx)."}, 
                status=400
            )
        
            # pandas.read_excel takes the Django UploadedFile object directly
        df = pd.read_excel(excel_file, header=1, dtype=str)
            
            # Convert the DataFrame to a JSON string (list of dictionaries)
        json_data_string = df.to_json(orient='records')
            
            # Convert the JSON string to a Python list/dict structure
        json_data = json.loads(json_data_string)

        serializer = LedgerCodesSerializer(data=json_data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [mastcode].[uspAddLedgerCodes] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
        
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def getGstnDetails(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select [mastcode].[fnGetGstDetails] (?)",(json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return Response(json_data)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)