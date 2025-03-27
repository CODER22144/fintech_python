from django import forms
from django.contrib.auth.forms import UserCreationForm
from .models import User

ROLE = (
    ('','--Select--'),
    ('AM','Admin-Management'),
    ('AB','Admin-BackOffice'),
    ('PA','Packing'),
    ('DI','Dispatch'),
    ('MA','Marketing'),
)

class SignupForm(UserCreationForm):
    roles = forms.ChoiceField(choices=ROLE)
    cid = forms.CharField(widget=forms.TextInput(
        attrs={
            "readonly": True,
            "onclick" : " window.open('/find-company/', '', 'width=500,height=500');",
            "placeholder" : "Click once to search your company"
        }
    ))

    companyName = forms.CharField(widget=forms.TextInput(
        attrs={
            'readonly': True,
            "onclick" : " window.open('/find-company/', '', 'width=500,height=500');",
            "placeholder" : "Click once to search your company"
        }
    ))

    
    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email', 'roles', 'cid', 'companyName', 'password1', 'password2']
