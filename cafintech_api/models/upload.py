from django.db import models
import os

def dynamic_upload_to(instance, filename):
    # Get the DB alias from the model instance (or fallback to 'default')
    db_alias = getattr(instance._state, 'db', 'default')
    
    # You define this method/property on the model to return "company", "customer", etc.
    file_type = instance.get_file_type()

    return os.path.join(db_alias, file_type, filename)

# Create your models here.
class FileUpload(models.Model):
    file = models.FileField(upload_to='docs', blank=True, null=True)
    drawing = models.FileField(upload_to='drawings', blank=True, null=True)

    def __str__(self):
        return f"{self.file}"


class BaseFileUpload(models.Model):
    file = models.FileField(upload_to=dynamic_upload_to)

    def __str__(self):
        return f"{self.file}"

    class Meta:
        abstract = True

    def save(self, *args, **kwargs):
        using = kwargs.get('using', None)
        if using:
            self._state.db = using
        super().save(*args, **kwargs)

    def get_file_type(self):
        raise NotImplementedError("Subclasses must implement get_file_type()")


class BillReceiptUpload(BaseFileUpload):
    def get_file_type(self):
        return 'br'

class JvoucherUpload(BaseFileUpload):
    def get_file_type(self):
        return 'jvoucher'
    
class CompanyUpload(BaseFileUpload):
    def get_file_type(self):
        return 'company'