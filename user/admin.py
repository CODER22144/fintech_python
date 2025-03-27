from django.contrib import admin
from .models import User, Company
# Register your models here.

class UserAdmin(admin.ModelAdmin):
    search_fields = ["email",]

admin.site.register(User)
admin.site.register(Company)