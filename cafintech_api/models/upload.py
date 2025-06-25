from django.db import models

# Create your models here.
class FileUpload(models.Model):
    file = models.FileField(upload_to='docs', blank=True, null=True)
    drawing = models.FileField(upload_to='drawings', blank=True, null=True)

    def __str__(self):
        return f"{self.file}"