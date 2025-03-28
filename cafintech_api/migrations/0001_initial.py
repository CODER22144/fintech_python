# Generated by Django 4.2.11 on 2024-04-27 14:48

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='Company',
            fields=[
                ('cid', models.CharField(max_length=2, primary_key=True, serialize=False)),
                ('compGstin', models.CharField(max_length=100)),
                ('legalName', models.CharField(max_length=100)),
                ('tradeName', models.CharField(max_length=15)),
                ('compAdd', models.CharField(max_length=100)),
                ('compAdd1', models.CharField(max_length=100, null=True)),
                ('compCity', models.CharField(max_length=50)),
                ('compZipCode', models.CharField(max_length=6)),
                ('compStateCode', models.SmallIntegerField()),
                ('compPhone', models.CharField(max_length=12)),
                ('compEmail', models.EmailField(max_length=254)),
                ('compCIN', models.CharField(max_length=21)),
                ('compPAN', models.CharField(max_length=10)),
            ],
            options={
                'db_table': '[sales].[company]',
                'managed': False,
            },
        ),
        migrations.CreateModel(
            name='HSN',
            fields=[
                ('cid', models.CharField(max_length=2)),
                ('hsnCode', models.CharField(max_length=2, primary_key=True, serialize=False)),
                ('hsnShortDescription', models.CharField(max_length=50)),
                ('hsnDescription', models.CharField(max_length=500)),
                ('isService', models.CharField(max_length=1)),
                ('gstTaxRate', models.DecimalField(decimal_places=2, max_digits=5)),
            ],
            options={
                'db_table': '[sales].[HSN]',
                'managed': False,
            },
        ),
    ]
