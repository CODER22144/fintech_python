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
from .views import payment_inward_outward_report_view as piorv
from .views import req_issue_slip as risv
from .views import order_balance_report_view as obrv
from .views import transporter_slip_view as transv
from .views import cr_note_report as crnrv
from .views import tds_report_view as tdsrv
from .views import dbnote_rep as dbsnrv
from .views import gst_return_view as gstv
from .views import ledger_view as lrv
from .views import production_plan_report_view as pprv

urlpatterns = [

    re_path(r"^search-business-partner/$", bps.searchBusinessPartner),
    re_path(r"^get-material-rep/$", mr.getMaterialRep),

    # Attendance Report
    re_path(r"^attendance-report/$", arv.attendacneReport),
    re_path(r"^claim-report/$", arv.claimReport),
    re_path(r"^visit-info-report/$", arv.visitInfoReport),

    # Purchase Order Details
    re_path(r"^purchase-order-report/$", porv.getPurchaseOrderDetails),
    re_path(r"^po-item-report/$", porv.getPurchaseOrderItemReport),
    re_path(r"^purchase-order-invoice/(?P<orderId>\d+)/(?P<cid>\w+)/$", porv.purchaseOrderInvoice),
    re_path(r"^purchase-order-invoice-pdf/(?P<orderId>\d+)/(?P<cid>\w+)/$", porv.convertToPdf),

    # Sales Order
    re_path(r"^sales-order-report/$", sorv.getSalesOrderReport),
    re_path(r"^payment-pending/$", sorv.getPaymentPending),
    re_path(r"^get-sales-report/$", sorv.getSalesReport),
    re_path(r"^order-status/$", sorv.getOrderStatus),
    re_path(r"^order-clear-value/$", sorv.getOrderClearValue),
    re_path(r"^order-slip/(?P<orderId>\d+)/(?P<cid>\w+)/$", sorv.getOrderSlip),
    re_path(r"^get-sales-order/(?P<orderId>\d+)/(?P<cid>\w+)/$", sorv.getSaleOrderByOrderId),
    re_path(r"^get-sales-order-pdf/(?P<orderId>\d+)/(?P<cid>\w+)/$", sorv.convertSaleOrderToPdf),

    # GR REP
    re_path(r"^gr-report/$", grrv.getGrRep),
    re_path(r"^gr-detail-byId/$", grrv.getGrDetailsById),
    re_path(r"^update-gr/$", grrv.updateGrDetails),
    re_path(r"^gr-item-report/$", grrv.getGrItemReport),
    re_path(r"^sale-item-report/$", grrv.getSaleItemReport),
    re_path(r"^srv/(?P<grno>\d+)/(?P<cid>\w+)/$", grrv.srvFormat),
    re_path(r"^srv-pdf/(?P<grno>\d+)/(?P<cid>\w+)/$", grrv.srvFormatPdf),

    # Material Source
    re_path(r"^get-material-source-report/$", msrv.getMaterialSourceReport),
    re_path(r"^get-mat-source-export/$", msrv.getMaterialSourceExport),

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
    re_path(r"^part-search/$", manu.getPartSearchReport),
    re_path(r"^not-in-bill-of-mat/$", manu.notInBillOfMaterial),

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
    re_path(r"^get-ship/(?P<bpCode>\w+)/$", shrv.getShippingByBpCode),

    # BANK STATEMENT
    re_path(r"^bank-statements/$", bksv.generateBankStatements),
    
    # 
    re_path(r"^db-note-report/$", dbnrv.getDbNoteReport),
    re_path(r"^cr-note-report/$", dbnrv.getCrNoteReport),
    re_path(r"^sale-db-note-report/$", dbnrv.getSaleDbNoteReport),
    re_path(r"^pr-tax-invoice-report/$", dbnrv.getPrTaxInvoiceReport),

    # Material Stock Report
    re_path(r"^mat-stock-report/$", matsv.getMaterialStockReport),

    re_path(r"^payment-inward-report/$", piorv.getPaymentInwardReport),
    re_path(r"^payment-outward-report/$", piorv.getPaymentOutwardReport),

    re_path(r"^req-slip/(?P<reqId>\d+)/(?P<cid>\w+)/$", risv.getReqSlip),

    # ORDER BALANCE
    re_path(r"^order-balance/$", obrv.getOrderBalanceReport),

    # TRANSPORTER AND ACKNOWLEDGEMENT SLIP
    re_path(r"^transporter-slip/(?P<inv>\d+)/(?P<cid>\w+)/$", transv.getTransporterSlip),
    re_path(r"^ack-slip/(?P<inv>\d+)/(?P<cid>\w+)/$", transv.getAckSlip),

    # CRNOTE REPORT
    re_path(r"^cr-note/(?P<docno>\d+)/(?P<cid>\w+)/$", crnrv.getCrNoteFormat),
    re_path(r"^get-ecr-note/$", crnrv.getECrNote),
    re_path(r"^add-einvoice-to-crnote/$", crnrv.addEinvoiceToCrNote),

    # TDS REPORT
    re_path(r"^get-tds-report/$", tdsrv.getTdsReport),

    # DEBIT NOTE SALE REPORT
    re_path(r"^sale-db-note/(?P<docno>\d+)/(?P<cid>\w+)/$", dbsnrv.getDbSalesnoteSaleFormat),
    re_path(r"^debit-note/(?P<docno>\d+)/(?P<cid>\w+)/$", dbsnrv.getDebitNoteFormat),
    re_path(r"^prtax-invoice/(?P<docno>\d+)/(?P<cid>\w+)/$", dbsnrv.getPRTaxInvoiceFormat),

    re_path(r"^get-edb-note/$", dbsnrv.getEDbNote),
    re_path(r"^get-edb-sale-note/$", dbsnrv.getEDbSaleNote),
    re_path(r"^get-epr-tax-invoice/$", dbsnrv.getEPRTaxInvoice),

    # GST RETURN
    re_path(r"^get-b2b/$", gstv.getB2b),
    re_path(r"^get-b2c/$", gstv.getB2c),
    re_path(r"^get-b2Cl/$", gstv.getB2Cl),
    re_path(r"^get-gst-hsn/$", gstv.getGstHsnSummary),
    re_path(r"^get-crdr-note/$", gstv.getCrDrNote),
    re_path(r"^get-doc-type/$", gstv.getDocType),
    re_path(r"^upload-gst-r2b/$", gstv.uploadGstR2b),
    re_path(r"^get-2bb2b-no-match/$", gstv.get2bb2bnoMatchReport),
    re_path(r"^get-2bb2b-match/$", gstv.get2bb2bMatchReport),
    re_path(r"^get-2bb2b-not-in/$", gstv.get2bb2bNotInReport),
    re_path(r"^update-inw/$", gstv.updateInwId),
    re_path(r"^convert-gst-rate/$", gstv.convertGstRate),

    # Ledger
    re_path(r"^ledger/$", lrv.getLedgerReport),
    re_path(r"^trial/$", lrv.getTrail),

    # PRODUCTION PLAN REPORT
    re_path(r"^production-plan-report/$", pprv.productionPlanReport),
    re_path(r"^pp-rep-type/$", pprv.getProductionPlanRepType),


] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)

# url(r'^edit-item/(?P<pk>[\w\-]+)/$', views.EditItem),



