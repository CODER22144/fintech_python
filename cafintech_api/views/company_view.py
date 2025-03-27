from django.db import connections

from django.http import HttpResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from CaFinTech.errors import UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message
from cafintech_api.serializers.company_serializer import company_serializer
import json

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
			cursor = connections[request.user.cid.cid].cursor()
			cursor.execute(f"EXEC [mastcode].[uspAddCompany] %s",(json.dumps(serializer.data),))
			cursor.close()
			return Response(serializer.data)
		UNSUCCESSFUL_REQUEST['message'] = serializer.errors
		return Response(UNSUCCESSFUL_REQUEST, status=400)
	except Exception as e:
			return Response(data=generate_error_message(e), status=500, exception=e)

