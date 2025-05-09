from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
import json
from cafintech_api.serializers.business_partner_serializer import BusinessPartnerSerializer
from cafintech_api.views.bill_receipt_view import ConvertToJson

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addBusinessPartner(request):
    try:
        serializer = BusinessPartnerSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [mastcode].[uspAddBusinessPartner] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getGSTRegnType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[GSTRegnType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCompanyType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[CompanyType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllStates(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"EXEC [mastcode].[uspGetStates]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllCountries(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select cid,c_name from [mastcode].[Countries]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getYesNo(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[YesNo]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getModeOfFreight(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[ModeOfFreight]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBusinessPartnerType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[BusinessPartnerType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getBusinessRelationType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[BusinessRelationType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getDiscountType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[DiscountType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getModeOfPayment(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[ModeOfPayment]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getRateType(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[MaterialRateType]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def trueFalseOptions(request):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"select * from [mastcode].[TrueFalse]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateBusinessPartner(request):
    try:
        serializer = BusinessPartnerSerializer(data=request.data, many=True)
        if(serializer.is_valid()):
            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [mastcode].[uspUpdateBusinessPartner] %s",(json.dumps(serializer.data),))
            cursor.close()
            return Response(serializer.data)
        UNSUCCESSFUL_REQUEST['message'] = serializer.errors
        return Response(UNSUCCESSFUL_REQUEST, status=400)
    except Exception as e:
        return Response(generate_error_message(e), status=500, exception=e)
    
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getByIdBusinessPartner(request, bpCode):
    try:
        cursor = connections[request.user.cid.cid].cursor()
        cursor.execute(f"exec [mastcode].[uspGetByIdBusinessPartner] %s", (bpCode,))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)