from django.db import models

class JsonForm(models.Model):
    form_id = models.CharField(max_length=25, primary_key=True)
    form_description = models.TextField()
    form_data = models.JSONField()
    procedure_name = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.form_id} | {self.form_description}"
