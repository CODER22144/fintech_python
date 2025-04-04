"""
URL configuration for CaFinTech project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/4.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import include, re_path
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from two_factor.urls import urlpatterns as tf_urls

schema_view = get_schema_view(
    openapi.Info(
        title="Cafintech APIs",
        default_version="v1",
        description="Backend services for Fintech APIs"
    ),
    public=True,
    permission_classes=(permissions.AllowAny,)
)

urlpatterns = [
    re_path(r'^admin/', admin.site.urls),
    re_path(r"^user/", include('user.urls')), 
    re_path(r"^", include('cafintech_api.urls')),
    re_path(r"^", include('fintech_reports.urls')),
    # re_path(r"^two-factor-auth/", include(tf_urls)),
    re_path(r'^swagger/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    re_path(r'^redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]
