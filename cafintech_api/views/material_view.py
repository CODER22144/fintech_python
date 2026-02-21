from django.db import connections

from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
import json
import pandas as pd

from cafintech_api.serializers.edit_material_serializer import EditMaterialSerializer
from cafintech_api.serializers.material_serializer import MaterialSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addMaterial(request):
    try:
        serializer = MaterialSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getHSNCode(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetHsn]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialUnit(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetMaterialUnit]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetMaterialType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialGroup(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetMaterialGroup]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialSubGroup(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [mastcode].[MaterialSubGroup]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterial(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select matno, matDescription from [purchase].[Material]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialStatus(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetMaterialStatus]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getItemType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [mastcode].[ItemType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialDetails(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetMaterialDetails] ?",(matno,))
        json_data = ConvertToJson(cursor)
        if(len(json_data) == 0 and matno != ""):
              return Response(data={"error_message" : "Invalid Material No : "+matno}, status=500, exception=e)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getMaterialDiscountType(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"select * from [mastcode].[DiscountMaterialType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateMaterial(request):
    try:
        serializer = MaterialSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspUpdateMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByIdMaterial(request, matno):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspGetMaterialById] ?",(matno,))
        json_data = ConvertToJson(cursor)
        if(len(json_data) > 0):
            return JsonResponse(json_data, safe=False)
        return Response(data={"message": "No data found for the given material number."}, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getMaterialAmount(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"SELECT matno,igstOnIntra,saleDescription,qty,unit,hsnCode,gstTaxRate,mrp,rate,amount,gstAmount,tAmount FROM [sales].[ufGetMaterialAmount] (?,?,?)",(request.data['lcode'],request.data['matno'],request.data['qty']))
        json_data = ConvertToJson(cursor)
        if(len(json_data) > 0):
            return JsonResponse(json_data, safe=False)
        return Response(data={"message": "No data found for the given material number."}, status=400)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAcGroups(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetAcGroups]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def editMaterialBulk(request):
    try:
        serializer = EditMaterialSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddMaterialBulkUpdate] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteMaterial(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [purchase].[uspDeleteMaterial] ?", (request.data['matno'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def importMaterial(request):
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

        serializer = MaterialSerializer(data=json_data, many=True)
        if(serializer.is_valid()):
            cursor = getDbCursor(request.user)
            cursor.execute(f"EXEC [purchase].[uspAddMaterial] ?",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
        
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)