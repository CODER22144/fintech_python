# myapp/views.py

from django.db import connections
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
import json
from CaFinTech.utility import generate_error_message
from cafintech_api.models.upload import FileUpload
from rest_framework.permissions import IsAuthenticated

from cafintech_api.serializers.file_upload_serializer import UploadedFileSerializer
from rest_framework.decorators import api_view

class fileUploadView(APIView):
    parser_classes = (MultiPartParser, FormParser)
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        try:
            bpCode = request.POST.get("bpCode")

            bpRegform = request.FILES.get("bpRegform")
            bpRegformFile = None
            if bpRegform:
                bpRegformFile = FileUpload(file=bpRegform)
                bpRegformFile.save()


            gstreg06 = request.FILES.get("gstreg06")
            gstreg06File = None
            if gstreg06:
                gstreg06File = FileUpload(file=gstreg06)
                gstreg06File.save()


            mcaMasterData = request.FILES.get("mcaMasterData")
            mcaMasterDataFile = None
            if mcaMasterData:
                mcaMasterDataFile = FileUpload(file=mcaMasterData)
                mcaMasterDataFile.save()


            paymentProof = request.FILES.get("paymentProof")
            paymentProofFile = None
            if paymentProof:
                paymentProofFile = FileUpload(file=paymentProof)
                paymentProofFile.save()


            panCard = request.FILES.get("panCard")
            panCardFile = None
            if panCard:
                panCardFile = FileUpload(file=panCard)
                panCardFile.save()


            aadharCard = request.FILES.get("aadharCard")
            aadharCardFile = None
            if aadharCard:
                aadharCardFile = FileUpload(file=aadharCard)
                aadharCardFile.save()


            msmeNo = request.FILES.get("msmeNo")
            msmeNoFile = None
            if msmeNo:
                msmeNoFile = FileUpload(file=msmeNo)
                msmeNoFile.save()


            msmeCertificate = request.FILES.get("msmeCertificate")
            msmeCertificateFile = None
            if msmeCertificate:
                msmeCertificateFile = FileUpload(file=msmeCertificate)
                msmeCertificateFile.save()


            balanceSheet = request.FILES.get("balanceSheet")
            balanceSheetFile = None
            if balanceSheet:
                balanceSheetFile = FileUpload(file=balanceSheet)
                balanceSheetFile.save()

            documentBody = {
                "bpCode" : bpCode,
                "bpRegform" : "/media/" + bpRegformFile.file.name if bpRegformFile != None else None,
                "gstreg06" : "/media/" + gstreg06File.file.name if gstreg06File != None else None,
                "mcaMasterData" : "/media/" + mcaMasterDataFile.file.name if mcaMasterDataFile != None else None,
                "paymentProof" : "/media/" + paymentProofFile.file.name if paymentProofFile != None else None,
                "panCard" : "/media/" + panCardFile.file.name if panCardFile != None else None,
                "aadharCard" : "/media/" + aadharCardFile.file.name if aadharCardFile != None else None,
                "msmeNo" : "/media/" + msmeNoFile.file.name if msmeNoFile != None else None,
                "msmeCertificate" : "/media/" + msmeCertificateFile.file.name if msmeCertificateFile != None else None,
                "balanceSheet" : "/media/" + balanceSheetFile.file.name if balanceSheetFile != None else None,
            }

            cursor = connections[request.user.cid.cid].cursor()
            cursor.execute(f"EXEC [mastcode].[uspAddbpDocument] %s",(json.dumps(documentBody).replace("'", "\""),))
            cursor.close()

            return Response(documentBody, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response(data=generate_error_message(e), status=400, exception=e)
        
@api_view(['POST'])
def uploadFiles(request):
    file_serializer = UploadedFileSerializer(data=request.data)
    if file_serializer.is_valid():
        file_serializer.save()
        return Response(file_serializer.data, status=status.HTTP_201_CREATED)
    else:
        return Response(file_serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
