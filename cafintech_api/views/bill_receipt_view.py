import json
from django.db import connections

from django.http import JsonResponse
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
from cafintech_api.serializers.bill_receipt_serializer import BillReceiptSerializer
from fintech_reports.serializers.report_serializer import ReportSerializer

def ConvertToJson(cur):
    jsn = []
    row_headers=[x[0] for x in cur.description]
    rv = cur.fetchall()
    for result in rv:
        jsn.append(dict(zip(row_headers,result)))
    return jsn

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def createBillReceipt(request):
    try:
        serializer = BillReceiptSerializer(data=request.data, many = True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [docen].[uspAddBr] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBillType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from mastcode.BillType")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBusinessPartner(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetBusinessPartnerDropDown]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCarrierType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[CarrierType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getTransMode(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[TransportMode]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllBillReceipt(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [docen].[uspGetAllBr]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteBillReceipt(request, brid):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [docen].[uspDeleteBr] %s", (brid, ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
        
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBrById(request, brid):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [docen].[uspGetByIdBr] %s", (brid, ))
        json_data = ConvertToJson(cursor)
        cursor.close()
        if len(json_data) == 1:
            json_data = json_data[0]
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBybtBr(request, bt):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        if bt == 'null':
            bt=None
        cursor.execute(f"exec [docen].[uspGetBybtBr] %s", (bt, ))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getBrReport(request):
    try:
        serializer = ReportSerializer(data=request.data)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [docen].[uspGetBrReport] %s",(json.dumps(serializer.data),))
            json_data = ConvertToJson(cursor)
            cursor.close()
            return JsonResponse(json_data, safe=False)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)