from django.urls import re_path, include
from . import views
from django.contrib.auth import views as auth_views
from django.conf import settings

urlpatterns = [
    # API
    re_path(r"^user-list/$", views.userList),
    re_path(r"^current/$", views.getCurrentUser),
    re_path(r"^create/$", views.createUser),
    re_path(r"^jwt-login/$", views.login),
    re_path(r"^two-factor-login/$", views.login_two_factor),
    re_path(r"^register-2fa/$", views.register_2fa_device),

    re_path(r'^verification/$', views.send_verification_email),
    re_path(r'^update-password/$', views.updatePassword),

    # COMPANY AND COMPANY GROUP
    re_path(r'^all/$', views.getAllUsersByAdmin),
    re_path(r'^get-all-org-company/$', views.getAllCompanies),
    re_path(r'^get-all-org-company-by-group/$', views.getAllCompaniesByGroupId),
    re_path(r'^get-all-org-company-group/$', views.getAllCompanyGroup),
    re_path(r'^update-cid/$', views.updateUserCid),
    re_path(r'^update-company-group/$', views.updateUserCompanyGroup),
    re_path(r'^add-company/$', views.addCompany),
    re_path(r'^add-company-group/$', views.addCompanyGroup),
    re_path(r'^roles/$', views.getAllRoles),

    # LOGIN VIEW
    re_path(r'^login/$', auth_views.LoginView.as_view(template_name="user/login.html"), name='login'),
    re_path(r'^logout/$', auth_views.LogoutView.as_view(template_name="user/logout.html"), name='logout'),

    # ERROR LOGS
    re_path(r'^error-logs/$', views.log_error),

    # FLUTTER FORMS
    re_path(r'^update-flutter-forms/(?P<form_id>[\w-]+)/$', views.updateFlutterForm),
    # re_path(r'^get-flutter-form/$', views.getFlutterForm),

]
