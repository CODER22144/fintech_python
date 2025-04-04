from rest_framework import serializers

class MaterialSerializer(serializers.Serializer):
   matno = serializers.CharField(max_length=15)
   skuno = serializers.CharField(max_length=15, allow_null=True, required=False)
   matDescription = serializers.CharField(max_length=100)
   inentoryitem = serializers.BooleanField(default=False, allow_null=True, required=False)
   purchaseitem = serializers.BooleanField(default=False, allow_null=True, required=False)
   saleitem = serializers.BooleanField(default=False, allow_null=True, required=False)
   hsnCode = serializers.CharField(max_length=10)
   prate = serializers.DecimalField(default=0, max_digits=12, decimal_places=3)
   puUnit = serializers.CharField(max_length=8)
   skUnit = serializers.CharField(max_length=8)
   conFactor = serializers.IntegerField()
   skrate = serializers.DecimalField(max_digits=12, decimal_places=3, allow_null=True, required=False)
   spq = serializers.IntegerField(allow_null=True, required=False)
   saleDescription = serializers.CharField(max_length=50,allow_null=True, required=False)
   mrp = serializers.DecimalField(default=0, max_digits=12, decimal_places=2, allow_null=True, required=False)
   listPrice = serializers.DecimalField(default=0, max_digits=12, decimal_places=2, allow_null=True, required=False)
   discType = serializers.CharField(max_length=1)
   discRate = serializers.DecimalField(default=0, max_digits=5, decimal_places=2, allow_null=True, required=False)
   fixedPrice = serializers.DecimalField(default=0, max_digits=5, decimal_places=2, allow_null=True, required=False)
   isQc = serializers.CharField(max_length=1)
   isStockKeeping = serializers.CharField(max_length=1)
   materialType = serializers.CharField(max_length=2)
   materialGroup = serializers.CharField(max_length=5)
   materialSubGroup = serializers.CharField(max_length=5, allow_null=True, required=False)
   weight = serializers.DecimalField(default=0, max_digits=12, decimal_places=3, allow_null=True, required=False)
   location = serializers.CharField(max_length=20, allow_null=True, required=False)
   minLevel = serializers.IntegerField(default=0)
   maxLevel = serializers.IntegerField(default=0)
   reqLevel = serializers.IntegerField(default=0)
   mst = serializers.CharField(max_length=1)
   doclosing = serializers.CharField(max_length=12, allow_null=True, required=False)