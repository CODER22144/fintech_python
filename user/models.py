from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.contrib.auth.hashers import make_password

# Create your models here.
class MyUserManager(BaseUserManager):
    def create_user(self, userId, password=None):
        if not userId:
            raise ValueError('User Must Have An User ID')

        user = self.model(
            userId = userId,
        )

        user.set_password(make_password(password))
        user.roles = 'AD'
        user.save(using = self._db)
        return user
    
    def create_superuser(self, userId, password):
        user = self.create_user(
            userId = userId,
            password=make_password(password)
        )
        user.roles = 'SAD'
        user.is_admin = True
        user.is_staff = True
        user.is_superuser = True
        user.save(using=self._db)
        return user

class User(AbstractBaseUser):
    userId = models.CharField(primary_key=True, max_length=50) 
    first_name = models.CharField(max_length=100)
    last_name = models.CharField(max_length=100)
    email = models.EmailField(verbose_name='email', max_length=60)
    roles = models.CharField(max_length=50) # comma separated list of role ids
    cgId = models.ForeignKey('CompanyGroup', on_delete=models.CASCADE, null=True, blank=True)
    cid = models.CharField(max_length=5, null=True, blank=True) # Foreign key to Company
    date_joined = models.DateTimeField(verbose_name='date joined', auto_now_add=True)
    last_login = models.DateTimeField(verbose_name='last login', auto_now_add=True)
    is_admin = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    admin = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, blank=True)  # Link to admin user who created this user

    USERNAME_FIELD = 'userId'

    objects = MyUserManager()

    def __str__(self):
        return self.userId

    def has_perm(self, perm, obj=None):
        return self.is_admin

    def has_module_perms(self, app_label):
        return True
    
    def set_role(self, role):
        self.roles = role
        return self
    
    def save(self, *args, **kwargs):
        if not self.pk and not self.password.startswith('pbkdf2_'):  # Check if already hashed
            self.set_password(make_password(self.password))
        super().save(*args, **kwargs)
    
    def toJson(self):
        return {
            "userId" : self.userId,
            "first_name" : self.first_name,
            "last_name" : self.last_name,
            "email" : self.email,
            "roles" : self.roles,
            "cgId" : self.cgId.associated_companies if self.cgId else None,
            "cid" : self.cid,
            "company_name" : Company.objects.filter(cid=self.cid).first().company_name if self.cid else None
        }


class Company(models.Model):
    cid = models.CharField(primary_key=True, max_length=5)
    company_name = models.CharField(max_length=100)
    connection_string = models.JSONField(null=True, blank=True)  # Store connection details as JSON
    user = models.ForeignKey(User, on_delete=models.CASCADE)  # Link to User who added the company

class CompanyGroup(models.Model):
    group_id = models.CharField(primary_key=True, max_length=2)
    group_description = models.CharField(max_length=30)
    associated_companies = models.CharField(max_length=250)  # Comma-separated list of company IDs
    associated_user = models.ForeignKey(User, on_delete=models.CASCADE)

class Roles(models.Model):
    role_id = models.CharField(primary_key=True, max_length=2)
    role_description = models.CharField(max_length=30)

class ErrorLog(models.Model):
    id = models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID', default=None)
    error_code = models.IntegerField()
    error_message = models.TextField()
    error_time = models.DateTimeField(auto_now_add=True)
    api_method_type = models.TextField(default='POST')  # GET, POST, PUT, DELETE
    api_endpoint = models.TextField()
    api_payload = models.TextField(blank=True, null=True)  # Encrypted payload
    ip_address = models.TextField()
    user_id = models.TextField()
    
    # error_platform = models.TextField()

    def __str__(self):
        return f"Error {self.error_code} by {self.user_id} at {self.error_time}"
    

class FlutterForm(models.Model):
    id = models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID', default=None)
    form_id = models.CharField(max_length=50, unique=True)
    form_description = models.CharField(max_length=200)
    form_fields = models.TextField()  # JSON AS STRING

    def __str__(self):
        return f"Form {self.form_id} - {self.form_description}"
    
    def toJson(self):
        return {
            "id": self.id,
            "form_id": self.form_id,
            "form_description": self.form_description,
            "form_fields": self.form_fields
        }
