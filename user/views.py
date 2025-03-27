from django.db.models.functions import Concat
from django.db.models import Value
from CaFinTech.errors import AUTHORIZATION_ERROR
from CaFinTech.utility import generate_error_message
from user.serializers import user_serializer
from .models import User
from rest_framework.response import Response
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from django.contrib.auth.hashers import make_password
import pyotp
from django_otp.plugins.otp_totp.models import TOTPDevice
from rest_framework import status

# API
@api_view(["GET"])
@permission_classes([IsAuthenticated])
def userList(request):
    users = User.objects.annotate(
    full_name=Concat('first_name', Value(' '), 'last_name')).filter(cid=request.user.cid).values("userId","full_name")
    return Response(users)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def createUser(request):
    request.data['password'] = make_password(request.data['password'])
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
