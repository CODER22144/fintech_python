from django.urls import re_path
from django.conf import settings
from django.conf.urls.static import static

from .views import bp_search_view as bps
from .views import material_rep_view as mr
from .views import attendance_report_view as arv
from .views import purchase_order_report_view as porv
from .views import gr_report_view as grrv
from .views import sales_order_report_view as sorv
from .views import material_source_report_view as msrv
from .views import payment_report_view as prv
from .views import hsn_report_view as hsnv
from .views import material_report_view as mrrv
from .views import inward_report_view as iwrv
from .views import sale_eway_bill as sewbv
from .views import manufacturing_report_view as manu
from .views import generate_qr as qr
from .views import job_work_out_report_view as jworv
from .views import dl_challan_report_view as dlcrv
from .views import ledger_codes_report_view as lcrv
from .views import bp_sale_discount_view as bpsdv
from .views import shipping_report_view as shrv
from .views import bank_statement_view as bksv
from .views import debit_note_report_view as dbnrv
from .views import material_stock_view as matsv

urlpatterns = [

    re_path(r"^search-business-partner/$", bps.searchBusinessPartner),
    re_path(r"^get-material-rep/$", mr.getMaterialRep),

    # Attendance Report
    re_path(r"^attendance-report/$", arv.attendacneReport),
    re_path(r"^claim-report/$", arv.claimReport),
    re_path(r"^visit-info-report/$", arv.visitInfoReport),

    # Purchase Order Details
    re_path(r"^purchase-order-report/$", porv.getPurchaseOrderDetails),
    re_path(r"^purchase-order-invoice/(?P<orderId>\d+)/(?P<cid>\w+)/$", porv.purchaseOrderInvoice),
    re_path(r"^purchase-order-invoice-pdf/(?P<orderId>\d+)/(?P<cid>\w+)/$", porv.convertToPdf),

    # Sales Order
    re_path(r"^sales-order-report/$", sorv.getSalesOrderReport),
    re_path(r"^payment-pending/$", sorv.getPaymentPending),
    re_path(r"^get-sales-report/$", sorv.getSalesReport),
    re_path(r"^get-sales-order/(?P<orderId>\d+)/(?P<cid>\w+)/$", sorv.getSaleOrderByOrderId),
    re_path(r"^get-sales-order-pdf/(?P<orderId>\d+)/(?P<cid>\w+)/$", sorv.convertSaleOrderToPdf),

    # GR REP
    re_path(r"^gr-report/$", grrv.getGrRep),
    re_path(r"^srv/(?P<grno>\d+)/(?P<cid>\w+)/$", grrv.srvFormat),
    re_path(r"^srv-pdf/(?P<grno>\d+)/(?P<cid>\w+)/$", grrv.srvFormatPdf),

    # Material Source
    re_path(r"^get-material-source-report/$", msrv.getMaterialSourceReport),

    # PAYMENT
    re_path(r"^get-payment-bill-pending/$", prv.getBillPending),

    # HSN
    re_path(r"^get-all-hsn/$", hsnv.getAllHsn),

    re_path(r"^get-material-report/$", mrrv.getMaterialReport),
    re_path(r"^get-inward-bill-report/$", iwrv.getInwardReport),

    # SALE BY INV. NO
    re_path(r"^get-sale-invc/(?P<inv>\d+)/(?P<cid>\w+)/$", sewbv.getSaleByInvNo),
    re_path(r"^get-sale-invc-pdf/(?P<inv>\d+)/(?P<cid>\w+)/$", sewbv.convertSaleInvToPdf),

    # Manufacturing Report
    re_path(r"^get-manufacturing-report/$", manu.getManufacturingReport),

    # QR CODE GENERATION
    re_path(r"^get-qr/$", qr.generate_qr),

    # JOB WORKOUT REPORT
    re_path(r"^get-job-workout-report/$", jworv.getJobWorkoutReport),
    re_path(r"^get-jwo/(?P<docno>\d+)/(?P<cid>\w+)/$", jworv.getJobworkoutformat),
    re_path(r"^get-jwo-pdf/(?P<docno>\d+)/(?P<cid>\w+)/$", jworv.getJobworkoutformatpdf),

    # JOB WORKOUT REPORT
    re_path(r"^get-dl-challan-report/$", dlcrv.getDlChallanReport),
    re_path(r"^get-dl-challan/(?P<docno>\d+)/(?P<cid>\w+)/$", dlcrv.getDlChallanFormat),
    re_path(r"^get-dl-challan-pdf/(?P<docno>\d+)/(?P<cid>\w+)/$", dlcrv.getDlChallanFormatPdf),

    # LEDGER CODE REPORT
    re_path(r"^get-ledger-report/$", lcrv.getLedgerReport),

    # Business Partner Sale Discount
    re_path(r"^get-bp-sale-discount/$", bpsdv.getBpSaleDiscountReport),

    # Business Partner Sale Discount
    re_path(r"^get-shipping-report/$", shrv.getShippingReport),

    # BANK STATEMENT
    re_path(r"^bank-statements/$", bksv.generateBankStatements),
    
    # 
    re_path(r"^db-note-report/$", dbnrv.getDbNoteReport),
    re_path(r"^cr-note-report/$", dbnrv.getCrNoteReport),
    re_path(r"^sale-db-note-report/$", dbnrv.getSaleDbNoteReport),
    re_path(r"^pr-tax-invoice-report/$", dbnrv.getPrTaxInvoiceReport),

    # Material Stock Report
    re_path(r"^mat-stock-report/$", matsv.getMaterialStockReport),


] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# url(r'^edit-item/(?P<pk>[\w\-]+)/$', views.EditItem),




