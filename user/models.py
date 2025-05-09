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
    roles = models.ForeignKey('Roles', on_delete=models.CASCADE, verbose_name="roles", default='US')
    # cid = models.CharField(default=None, null=True, blank=True, max_length=2)
    cid = models.ForeignKey('Company', on_delete=models.CASCADE, verbose_name="cid", default='OW')
    date_joined = models.DateTimeField(verbose_name='date joined', auto_now_add=True)
    last_login = models.DateTimeField(verbose_name='last login', auto_now_add=True)
    is_admin = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)

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
            "roles" : self.roles.role_id,
            "roles_description" : self.roles.role_description,
            "cid" : self.cid.cid,
            "company_name" : self.cid.companyName,
            "company_phone" : self.cid.phoneNumber,
            "logo" : self.cid.logo,
            "date_joined" : self.date_joined,
            "last_login" : self.last_login,
            "is_admin" : self.is_admin,
            "is_active" : self.is_active,
            "is_staff" : self.is_staff,
            "is_superuser" : self.is_superuser
        }


class Company(models.Model):
    cid = models.CharField(primary_key=True, max_length=2)
    companyName = models.CharField(max_length=100)
    phoneNumber = models.CharField(max_length=10, unique=True)
    logo = models.CharField(max_length=500, default='')

class Roles(models.Model):
    role_id = models.CharField(primary_key=True, max_length=2)
    role_description = models.CharField(max_length=30)

