# Generated by Django 4.2.11 on 2025-07-03 11:07

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('user', '0009_roles_alter_user_userid_alter_user_roles'),
    ]

    operations = [
        migrations.CreateModel(
            name='ErrorLog',
            fields=[
                ('id', models.AutoField(auto_created=True, default=None, primary_key=True, serialize=False, verbose_name='ID')),
                ('error_code', models.IntegerField()),
                ('error_message', models.TextField()),
                ('error_time', models.DateTimeField(auto_now_add=True)),
                ('api_method_type', models.TextField(default='POST')),
                ('api_endpoint', models.TextField()),
                ('api_payload', models.TextField(blank=True, null=True)),
                ('ip_address', models.TextField()),
                ('user_id', models.TextField()),
            ],
        )
    ]
