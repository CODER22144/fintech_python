from django.http import HttpResponse
import qrcode
import io

def generate_qr(request):
    # Get data from query parameter (Example: ?data=HelloWorld)
    data = request.GET.get('data', 'Default QR Code Data')

    # Generate QR code
    qr = qrcode.QRCode(
        version=1,
        error_correction=qrcode.constants.ERROR_CORRECT_L,
        box_size=10,
        border=4
    )
    qr.add_data(data)
    qr.make(fit=True)

    # Create an image in memory
    img = qr.make_image(fill="black", back_color="white")
    img_io = io.BytesIO()
    img.save(img_io, format="PNG")
    img_io.seek(0)

    # Return the image as a response
    return HttpResponse(img_io.getvalue(), content_type="image/png")
