from django.urls import re_path, include
from . import views
from django.contrib.auth import views as auth_views
from django.conf import settings

urlpatterns = [
    # API
    re_path(r"^user-list/$", views.userList),
    re_path(r"^create/$", views.createUser),
    re_path(r"^jwt-login/$", views.login),
    re_path(r"^two-factor-login/$", views.login_two_factor),
    re_path(r"^register-2fa/$", views.register_2fa_device),

    re_path(r'^verification/$', views.send_verification_email),
    re_path(r'^update-password/$', views.updatePassword),

    # LOGIN VIEW
    re_path(r'^login/$', auth_views.LoginView.as_view(template_name="user/login.html"), name='login'),
    re_path(r'^logout/$', auth_views.LogoutView.as_view(template_name="user/logout.html"), name='logout'),

    # ERROR LOGS
    re_path(r'^error-logs/$', views.log_error),

]
