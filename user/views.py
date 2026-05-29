from django.db.models.functions import Concat
from django.db.models import Value
from django.http import JsonResponse
from CaFinTech.errors import AUTHORIZATION_ERROR, UNSUCCESSFUL_REQUEST
from CaFinTech.utility import generate_error_message, getDbCursor, migrateSqlScript
from user.forms import FlutterFormUpdateForm
from user.serializers import error_log_serializer, user_serializer
from .models import Company, CompanyGroup, FlutterForm, Roles, User
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password
import pyotp
from django_otp.plugins.otp_totp.models import TOTPDevice
from rest_framework import status
from django.contrib.auth.tokens import default_token_generator
from django.core.mail import send_mail
from cryptography.fernet import Fernet
from CaFinTech.settings import FERNET_KEY

# API
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def userList(request):
    users = User.objects.annotate(
    full_name=Concat('first_name', Value(' '), 'last_name')).filter(cid=request.user.cid).values("userId","full_name")
    return Response(users)

@api_view(["GET"])
@permission_classes([IsAuthenticated])
def getCurrentUser(request):
    company_name = Company.objects.filter(cid=request.user.cid).first().company_name if request.user.cid else None
    usr = User.objects.filter(userId=request.user.userId).first()
    response = usr.toJson()
    response["company_name"] = company_name
    return Response(response)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createUser(request):
    request.data['password'] = make_password(request.data['password'])
    request.data['admin'] = request.user
    user = user_serializer(data=request.data)
    if user.is_valid():
        user.save()
    return Response(user.data)

@api_view(['POST'])
def login(request):
    try:
        data = request.data
        user = authenticate(username=data['userId'], password=data['password'])
        
        if user is None:
            return Response(data=AUTHORIZATION_ERROR, status=AUTHORIZATION_ERROR['status_code'])
        
        # device = TOTPDevice.objects.filter(user=user, confirmed=True).first()

        # if not device:
        #     return Response({"message": "No OTP device found for user"}, status=204)

        refresh = RefreshToken.for_user(user)
        response = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'exp' : refresh.payload['exp']
        }
        response.update(user.toJson())
        return Response(data=response, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=400, exception=e)
    
@api_view(['POST'])
def login_two_factor(request):
    try:
        data = request.data
        otp_token = data['otp_token']
        user = authenticate(username=data['userId'], password=data['password'])
        
        if user is None:
            return Response(data=AUTHORIZATION_ERROR, status=AUTHORIZATION_ERROR['status_code'])
        
        device = TOTPDevice.objects.get(user=user, confirmed=True)

        if not device:
            return Response({"error": "No OTP device found for user"}, status=400)

        # Verify OTP token
        if not device.verify_token(otp_token):
            return Response({"error": "Invalid OTP token"}, status=401)
        
        # Generate token based on retrieved user data
        refresh = RefreshToken.for_user(user)
        response = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'exp' : refresh.payload['exp']
        }
        response.update(user.toJson())
        return Response(data=response, status=200)
    except Exception as e:
        return Response(data=generate_error_message(e), status=400, exception=e)


@api_view(['POST'])
def register_2fa_device(request):
    data = request.data
    user = authenticate(username=data['userId'], password=data['password'])

    # Delete any existing device for the user
    TOTPDevice.objects.filter(user=user).delete()

    # Generate a new TOTP device
    totp_device = TOTPDevice.objects.create(user=user, confirmed=True)

    # Generate a new secret key
    totp_device.secret = pyotp.random_base32()
    totp_device.save()

    # Generate the QR code URL (for Google Authenticator or similar)
    otp_auth_url = totp_device.config_url

    return Response({
        "message": "Scan this QR code with your authenticator app",
        "otp_auth_url": otp_auth_url,
        "secret_key": totp_device.secret  # Optional, for manual entry
    }, status=status.HTTP_201_CREATED)

@api_view(['POST'])
def send_verification_email(request):
    try:
        usr = User.objects.filter(email=request.data['email']).first()

        if usr is None:
            UNSUCCESSFUL_REQUEST['message'] = 'No User found by email: ' + request.data['email']
            return Response(data=UNSUCCESSFUL_REQUEST, status=UNSUCCESSFUL_REQUEST['status_code'])
        
        token = default_token_generator.make_token(usr)

        send_mail(
        subject='Email Verification',
        message=f'Please note the verification Token : {token}',
        from_email='info.sst@sapswiss.in',
        recipient_list=[usr.email],
        fail_silently=False,
        )

        return Response(data= {"status_code" : 200, "message" : "User verification token is generated please check your mail."}, status=201)

    except Exception as e:
        return Response(data=generate_error_message(e), status=400, exception=e)
    
@api_view(['POST'])
def updatePassword(request):
    user = User.objects.get(email=request.data['email'])

    if not default_token_generator.check_token(user, request.data['token']):
        UNSUCCESSFUL_REQUEST['message'] = 'Invalid Token'
        return Response(data=UNSUCCESSFUL_REQUEST, status=UNSUCCESSFUL_REQUEST['status_code'])
    
    if user is None:
        UNSUCCESSFUL_REQUEST['message'] = 'No User found by email: ' + request.data['email']
        return Response(data=UNSUCCESSFUL_REQUEST, status=UNSUCCESSFUL_REQUEST['status_code'])
    
    new_pass = make_password(request.data['new_password'])
    user.password = new_pass
    user.save()

    return Response(data={"message" : "Password reset completed"}, status=200)


# ******************************ERROR LOGS******************************

@api_view(['POST'])
def log_error(request):
    fernet = Fernet(FERNET_KEY.encode())
    request.data['api_payload'] = fernet.encrypt(str(request.data['api_payload']).encode()).decode()
    serializer = error_log_serializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(status=status.HTTP_204_NO_CONTENT)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# note: To decode the token, you can use the following code:
# fernet.decrypt(token.encode()).decode()

def updateFlutterForm(request, form_id):
    try:
        flutter_form = FlutterForm.objects.get(form_id=form_id)
        serializer = FlutterFormUpdateForm(flutter_form, data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except FlutterForm.DoesNotExist:
        return Response({"error": "Flutter form not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['POST'])
def getFlutterForm(request):
    try:
        flutter_form = FlutterForm.objects.get(form_id=request.data['form_id'])
        return Response(flutter_form.toJson(), status=status.HTTP_200_OK)
    except FlutterForm.DoesNotExist:
        return Response({"error": "Flutter form not found"}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getAllCompaniesByGroupId(request):
    companies = Company.objects.filter(cid__in=request.user.cgId.associated_companies.split(',')).values('cid', 'company_name') if request.user.cgId else Company.objects.none()
    return JsonResponse(list(companies), safe=False)

# Used to show all company in the multiselect for the company group creation
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getAllCompanies(request):
    user = request.user
    companies = Company.objects.filter(user = User.objects.filter(userId=user.admin).first()).values('cid', 'company_name')
    return Response(companies, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateUserCid(request):
    user = request.user
    usr_obj = User.objects.filter(userId=user.userId).first()
    usr_obj.cid = request.data['cid']
    usr_obj.save()
    return Response({"message": "Company ID updated successfully"}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def updateUserCompanyGroup(request):
    usr_obj = User.objects.filter(userId=request.data['userId']).first()
    usr_obj.cgId = CompanyGroup.objects.filter(group_id=request.data['cgId']).first()
    usr_obj.save()
    return Response({"message": "Company Group updated successfully"}, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCompany(request):
    connection_json = migrateSqlScript(request.data['cid'])

    Company.objects.create(
        cid = request.data['cid'],
        company_name = request.data['company_name'],
        connection_string = connection_json,
        user = User.objects.filter(userId=request.user.userId).first()
    ).save()
    return Response({"message": "Company added successfully"}, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getAllRoles(request):
    roles = Roles.objects.all().values('role_id', 'role_description')
    return Response(roles, status=status.HTTP_200_OK)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def addCompanyGroup(request):
    CompanyGroup.objects.create(
        group_id = request.data['group_id'],
        group_description = request.data['group_description'],
        associated_companies = request.data['associated_companies'],
        associated_user = User.objects.filter(userId=request.user.userId).first()
    ).save()
    return Response({"message": "Company Group added successfully"}, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getAllCompanyGroup(request):
    company_groups = CompanyGroup.objects.filter(associated_user=User.objects.filter(userId=request.user.userId).first()).values('group_id', 'group_description')
    return Response(company_groups, status=status.HTTP_200_OK)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def getAllUsersByAdmin(request):
    users = User.objects.filter(admin=User.objects.filter(userId = request.user.userId).first()).values('userId', 'first_name', 'last_name', 'email', 'roles', "cgId", 'cid')
    return Response(users, status=status.HTTP_200_OK)