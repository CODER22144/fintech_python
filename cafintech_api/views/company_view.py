from django.db import connections

from django.http import HttpResponse, JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor
from cafintech_api.serializers.company_serializer import company_serializer
import json

from cafintech_api.views.bill_receipt_view import ConvertToJson

# Create your views here.

@api_view(['GET'])
def apiOverview(request):
	api_urls = {
		'Hello':'World'
		}
	return Response(api_urls)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def createCompany(request):
	try:	
		serializer = company_serializer(data=request.data, many=True)
		if(serializer.is_valid()):
			cursor = getDbCursor(request.user)
			cursor.execute(f"EXEC [mastcode].[uspAddCompany] ?",(json.dumps(serializer.data),))
			cursor.close()
			return Response(serializer.data)
		UNSUCCESSFUL_REQUEST['message'] = serializer.errors
		return Response(UNSUCCESSFUL_REQUEST, status=400)
	except Exception as e:
			return Response(data=generate_error_message(e), status=500, exception=e)
       
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def updateCompany(request):
	try:	
		serializer = company_serializer(data=request.data)
		if(serializer.is_valid()):
			cursor = getDbCursor(request.user)
			cursor.execute(f"EXEC [mastcode].[uspUpdateCompany] ?",(json.dumps(serializer.data),))
			cursor.close()
			return Response(serializer.data)
		UNSUCCESSFUL_REQUEST['message'] = serializer.errors
		return Response(UNSUCCESSFUL_REQUEST, status=400)
	except Exception as e:
			return Response(data=generate_error_message(e), status=500, exception=e)
	
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getAllCompanies(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetCompany]")
        json_data = ConvertToJson(cursor)
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)
	
@api_view(["POST"])
@permission_classes([IsAuthenticated])
def getByIdCompanies(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspGetCompany] ?", (json.dumps(request.data),))
        json_data = ConvertToJson(cursor)
        cursor.close()
        return JsonResponse(json_data, safe=False)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def deleteCompany(request):
    try:
        cursor = getDbCursor(request.user)
        cursor.execute(f"exec [mastcode].[uspDeleteCompany] ?", (request.data['cid'], ))
        cursor.close()
        return Response(data={"status" : "OK"}, status=204)
    except Exception as e:
        return Response(data=generate_error_message(e), status=500, exception=e)