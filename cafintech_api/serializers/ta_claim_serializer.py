from rest_framework import serializers

class TaClaimSerializer(serializers.Serializer):
	userId = serializers.CharField()
	from_Place = serializers.CharField(max_length = 20)
	to_Place = serializers.CharField(max_length = 20)
	distCovered = serializers.IntegerField(default=0)
	mediumTransport = serializers.CharField(max_length = 1)   # Drop down [mastcode].[TransportMedium](transMedium)
	fare = serializers.DecimalField(max_digits=12, decimal_places=2, default = 0)
	da = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
	lConveyance = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
	oConveyance = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
	otherAmount = serializers.DecimalField(max_digits=10, decimal_places=2, default=0)
	otherDescription = serializers.CharField(max_length = 100, allow_null=True, required = False)  # if otherAmount > 0 Then it can not be null  
	facilityName = serializers.CharField(max_length = 50, allow_null=True, required=False)
	facilityPhone = serializers.CharField(max_length = 50, allow_null=True, required = False)
	DocProof = serializers.CharField(max_length = 200, allow_null=True, required = False)