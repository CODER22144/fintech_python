from django.urls import re_path
from django.conf import settings
from django.conf.urls.static import static

from cafintech_api.views import company_view
from .views import upload_view
from .views import business_partner_view as bp
from .views import bill_receipt_view as br
from.views import ledger_codes_view as lc
from .views import material_view as mt
from .views import material_source_view as mts
from .views import bp_tax_info_view as bpt
from .views import bp_address_view as bpad
from .views import bp_contact_view as bpc
from .views import warehouse_view as whv
from .views import purchase_order_view as pov
from .views import gr_view as grv
from .views import additional_order_view as aov
from .views import ev_order_view as evv
from .views import material_iqs_view as miq
from .views import obalance_view as obv
from .views import bill_payable_view as bpv
from .views import bill_receiveable_view as brv
from .views import inward_voucher_view as ivv
from .views import HSN_view as hsn
from .views import visit_info_view as viv
from .views import ta_claim_view as tcv
from .views import attendence_view as atv
from .views import inward_view as iv
from .views import financial_crnote_view as fcv
from .views import receipt_voucher_view as rvv
from .views import payment_voucher_view as pvv
from .views import db_note_view as dbv
from .views import sales_debit_note_view as sbnv
from .views import db_note_dispatch_view as dbnd
from .views import db_note_against_cr_note_view as dnac
from .views import pr_tax_invoice_dispatch_view as ptid
from .views import resource_view as resv
from .views import bp_shipping_view as bpsv
from .views import carrier_view as carv
from .views import sales_order_details_view as sodv
from .views import gr_other_charges_view as gocv
from .views import gr_iqs_rep_view as girv
from .views import gr_qty_clear_view as gqcv
from .views import order_processing_view as opv
from .views import order_packaging_view as opackv
from .views import wire_size_view as wsv
from .views import payment_view as payv
from .views import bank_upload_view as buv
from .views import part_assembly_view as papv
from .views import part_sub_assembly_view as psapv
from .views import product_breakup_view as pbuv
from .views import journal_voucher_view as jvv
from .views import sale_purchase_transfer_view as sptv
from .views import payment_inward_view as payiv
from .views import work_process_view as wpv
from .views import cost_resource_view as crv
from .views import material_incoming_standard_view as misv
from .views import manufacturing_view as manuv
from .views import job_work_out_details_view as jwov
from .views import requirement_view as reqv
from .views import req_production_view as reqpv
from .views import req_packing_packed_view as rppv
from .views import req_issue_view as rqeiv
from .views import dl_challan_view as dlcv
from .views import job_work_out_challan_clear_view as jwoccv
from .views import production_plan_view as ppv
from .views import production_plan_A_view as ppav
from .views import material_return_view as matrv
from .views import line_rejection_view as lrv
from .views import advance_sales_order_view as asov
from .views import payment_inward_clear_view as picv
from .views import advance_req_view as advreqv
from .views import re_order_bal_material_view as rovmv
from .views import reverse_charges_view as rcv
from .views import ob_material_view as obmv
from .views import material_assembly_view as mav
from .views import business_partner_onboard_view as bponv

from .views import bp_ob_material_view as bpobmv
from .views import material_assembly_tech_details_view as matatv
from .views import bp_breakup_view as bpbreakv
from .views import business_partner_processing_view as bppv

from .views import material_tech_details_view as mtv


urlpatterns = [
# Home
    re_path(r"^$", company_view.apiOverview),

    # Company
    re_path(r"^create-company/$", company_view.createCompany),

    # HSN
    re_path(r"^get-hsn/(?P<hsnCode>\d+)/$", hsn.getGstTaxRate),
    re_path(r"^get-gst-tax-rate/$", hsn.getGstTaxRateDrop),
    re_path(r"^add-hsn/$", hsn.addHsn),
    re_path(r"^update-hsn/$", hsn.updateHsn),
    re_path(r"^delete-hsn/(?P<hsnCode>\d+)/$", hsn.deleteHsn),
    re_path(r"^get-hsn-code/(?P<hsnCode>\d+)/$", hsn.getHsnById),
    

    # Bill Receipt
    re_path(r"^get-bill-type/$", br.getBillType),
    re_path(r"^get-business-partner/$", br.getBusinessPartner),
    re_path(r"^get-carrier-type/$", br.getCarrierType),
    re_path(r"^get-trans-mode/$", br.getTransMode),
    re_path(r"^create-br/$", br.createBillReceipt),
    re_path(r"^get-br/$", br.getAllBillReceipt),
    re_path(r"^delete-br/(?P<brid>\d+)/$", br.deleteBillReceipt),
    re_path(r"^get-br/(?P<brid>\d+)/$", br.getBrById),
    re_path(r"^get-bt-br/(?P<bt>\w+)/$", br.getBybtBr),
    re_path(r"^br-report/$", br.getBrReport),

    # Business Partner
    re_path(r"^add-business-partner/$", bp.addBusinessPartner),
    re_path(r"^update-business-partner/$", bp.updateBusinessPartner),
    re_path(r"^get-business-partner/(?P<bpCode>[\w\-]+)/$", bp.getByIdBusinessPartner),
    re_path(r"^get-business-relation-type/$", bp.getBusinessRelationType),
    re_path(r"^gst-type/$", bp.getGSTRegnType),
    re_path(r"^get-company-type/$", bp.getCompanyType),
    re_path(r"^get-countries/$", bp.getAllCountries),
    re_path(r"^get-states/$", bp.getAllStates),
    re_path(r"^get-yesno/$", bp.getYesNo),
    re_path(r"^get-mof/$", bp.getModeOfFreight),
    re_path(r"^get-mop/$", bp.getModeOfPayment),
    re_path(r"^get-rate-type/$", bp.getRateType),
    re_path(r"^get-tf/$", bp.trueFalseOptions),
    re_path(r"^get-discount-type/$", bp.getDiscountType),
    re_path(r"^get-business-partner-type/$", bp.getBusinessPartnerType),

    # LedgerCodes
    re_path(r"^get-ledger-title/$", lc.getLedgerTitle),
    re_path(r"^get-ledger-status/$", lc.getLedgerStatus),
    re_path(r"^get-supply-type/$", lc.getSupplyType),
    re_path(r"^get-ledger-type/$", lc.getLedgerType),
    re_path(r"^get-account-groups/$", lc.getAccountGroups),
    re_path(r"^add-ledger-codes/$", lc.addLedgerCodes),
    re_path(r"^update-ledger-codes/$", lc.updateLedgerCodes),
    re_path(r"^get-ledger-codes/$", lc.getLedgerCode),
    re_path(r"^get-ledger-code/(?P<lCode>[\w\-\.]+)/$", lc.getByIdLedgerCode),
    re_path(r"^get-ledger-code-supply/(?P<lCode>[\w\-\.]+)/$", lc.getLedgerCodeSupply),

    # Material
    re_path(r"^add-material/$", mt.addMaterial),
    re_path(r"^update-material/$", mt.updateMaterial),
    re_path(r"^get-material/(?P<matno>[\w\-.]+)/$", mt.getByIdMaterial),
    re_path(r"^get-hsn/$", mt.getHSNCode),
    re_path(r"^get-material-unit/$", mt.getMaterialUnit),
    re_path(r"^get-material-type/$", mt.getMaterialType),
    re_path(r"^get-material-group/$", mt.getMaterialGroup),
    re_path(r"^get-material-subgroup/$", mt.getMaterialSubGroup),
    re_path(r"^get-material/$", mt.getMaterial),
    re_path(r"^get-material-status/$", mt.getMaterialStatus),
    re_path(r"^get-item-type/$", mt.getItemType),
    re_path(r"^get-material-discount-type/$", mt.getMaterialDiscountType),
    re_path(r"^get-mat-details/(?P<matno>[\w\-.]+)/$", mt.getMaterialDetails),
    re_path(r"^get-ac-groups/$", mt.getAcGroups),
    re_path(r"^edit-material-bulk/$", mt.editMaterialBulk),
    
    # File Upload
    re_path(r"^upload/$", upload_view.fileUploadView.as_view()),
    re_path(r"^upload-file/$", upload_view.uploadFiles),

    # Material Source
    re_path(r"^add-material-source/$", mts.addMaterialSource),
    re_path(r"^update-material-source/$", mts.updateMaterialSource),
    re_path(r"^get-material-source-details/$", mts.getMaterialSourceDetails),
    re_path(r"^edit-material-source-bulk/$", mts.editMaterialSourceBulk),

    # Business Partner Pay and Tax Info
    re_path(r"^add-business-partner-tax-info/$", bpt.createBusinessPartnerTaxInfo),
    re_path(r"^add-business-partner-address/$", bpad.createBusinessPartnerAddress),
    re_path(r"^add-business-partner-contact/$", bpc.createBusinessPartnerContact),
    re_path(r"^add-warehouse/$", whv.addWarehouse),
    re_path(r"^get-warehouse/$", whv.getAllWareHouse),

    re_path(r"^update-bp-tax-info/$", bpt.updateBusinessPartnerTaxInfo),
    re_path(r"^get-bp-tax-info/$", bpt.getBpTaxInfoById),

    # Purchase Order
    re_path(r"^create-purchase-order/$", pov.createPurchaseOrder),
    re_path(r"^get-priority/$", pov.getAllPriority),
    re_path(r"^get-po-type/$", pov.getAllPoType),
    re_path(r"^short-qty/$", pov.getShortQty),

    # GR DETAILS
    re_path(r"^create-gr/$", grv.addGrDetails),
    re_path(r"^get-pending-gr/$", grv.getPendingGr),
    re_path(r"^delete-gr/$", grv.deleteGr),
    re_path(r"^get-gr/(?P<grno>\d+)/$", grv.getGrByGrno),
    re_path(r"^valid-purchase-order/(?P<bpCode>[\w\-]+)/$", grv.validPurchaseOrder),

    re_path(r"^get-gr-shortage-pending/$", grv.getGrShortage),
    re_path(r"^get-gr-rejection-pending/$", grv.getGrRejection),
    re_path(r"^get-gr-rate-approval-pending/$", grv.getGrRateApprovalPending),
    re_path(r"^debit-note-rate-diff/$", grv.debitNoteRateDifference),
    re_path(r"^debit-note-shortage/$", grv.debitNoteShortage),
    re_path(r"^tax-invoice-rejection/$", grv.debitNoteRejection),

    # ADDITIONAL ORDER
    re_path(r"^additional-purchase-order/$", aov.addAdditionalPurchaseOrder),
    re_path(r"^additional-purchase-order-report/$", aov.getAdditionalPurchaseOrderReport),

    re_path(r"^ev-purchase-order/$", evv.addEVPurchaseOrder),

    # Material IQS
    re_path(r"^add-material-iqs/$", miq.addMaterialIQS),
    re_path(r"^update-material-iqs/$", miq.updateMaterialIQS),
    re_path(r"^get-material-iqs/(?P<miqsId>[\w\-]+)/$", miq.getByIdMaterialIQS),
    re_path(r"^delete-material-iqs/(?P<miqsId>[\w\-]+)/$", miq.deleteMaterialIQS),

    # OBalance
    re_path(r"^add-obalance/$", obv.addOBalance),
    re_path(r"^update-obalance/$", obv.updateObalance),
    re_path(r"^get-obId/$", obv.getObId),
    re_path(r"^get-obalance-type/$", obv.getBalanceType),
    re_path(r"^get-obalance/(?P<obId>[\w\-]+)/$", obv.getByIdOBalance),
    re_path(r"^delete-obalance/(?P<obId>[\w\-]+)/$", obv.deleteOBlance),
    re_path(r"^obalance-report/$", obv.getOBalanceReport),

    # Bill Payable
    re_path(r"^add-bill-payable/$", bpv.addBillPayable),
    re_path(r"^get-bill-payable-type/$", bpv.getBillPayableType),
    re_path(r"^delete-bill-payable/(?P<obId>[\w\-]+)/$", bpv.deleteBillPayable),

    # Bill Receivable
    re_path(r"^add-bill-receivable/$", brv.addBillReceivable),
    re_path(r"^delete-bill-receivable/(?P<transId>[\w\-]+)/$", brv.deleteBillReceivable),

    # Inward Voucher
    re_path(r"^create-inward-voucher/$", ivv.createInwardVoucher),
    re_path(r"^get-discper-type/$", ivv.getDiscountPercentageType),

    # Visit Info
    re_path(r"^add-visit-info/$", viv.addVisitInfo),
    re_path(r"^get-resources/$", viv.getResources),
    re_path(r"^get-visit-info/(?P<transId>[\w\-]+)/$", viv.getByIdVisitInfo),
    re_path(r"^update-visit-info/$", viv.updateVisitInfo),

    # TA Claim
    re_path(r"^add-claim/$", tcv.addClaim),
    re_path(r"^get-transport-medium/$", tcv.getTransportMedium),

    # Attendence
    re_path(r"^checkin/$", atv.checkIn),
    re_path(r"^checkout/$", atv.checkOut),
    re_path(r"^last-attendance/$", atv.getLastAttendance),

    # Inward Details
    re_path(r"^add-inward-details/$", iv.addInwardDetails),
    re_path(r"^get-tds/$", iv.getTdsCode),
    re_path(r"^get-supplier-type/$", iv.getSupplierType),
    re_path(r"^get-tds-rate/(?P<tdsCode>[\w\-]+)/$", iv.getTdsRate),

    # Financial Credit Note
    re_path(r"^get-tod-rate/$", fcv.getTodRate),
    re_path(r"^get-crn-type/$", fcv.getCreditNoteType),
    re_path(r"^create-financial-crnote/$", fcv.createFinancialCreditNote),

    # Receipt VOucher
    re_path(r"^create-receipt-voucher/$", rvv.createReceiptVoucher),
    
    # Payment Voucher
    re_path(r"^create-payment-voucher/$", pvv.createPaymentVoucher),
    
    # DbNote Details
    re_path(r"^add-dbnote/$", dbv.addDbNoteDetails),
    re_path(r"^add-pr-tax/$", dbv.addPRTaxInvoice),
    re_path(r"^add-credit-note/$", dbv.addCrNote),
    re_path(r"^get-doc-against/$", dbv.getDocAgainst),
    re_path(r"^get-doc-reason/$", dbv.getDocReason),
    re_path(r"^get-cr-mat-details/$", dbv.getCrNoteMaterialDetails),
    re_path(r"^get-mat-wh/$", dbv.getMaterialWhByBpCodeMatno),

    # Sales debit note
    re_path(r"^add-sale-debit-note/$", sbnv.addSaleDebitNote),
    re_path(r"^get-invoice-type/$", sbnv.getInvoiceType),

    # Debit note Dispatch
    re_path(r"^add-debit-note-dispatch/$", dbnd.adddebitNoteDispatch),
    re_path(r"^add-debit-note-against-cr-note/$", dnac.addDbNoteAgainstCrNote),
    re_path(r"^add-pr-tax-invoice-dispatch/$", ptid.addPrTaxInvoiceDispatch),

    # Resources
    re_path(r"^add-resources/$", resv.addResources),
    re_path(r"^update-resources/$", resv.updateResources),
    re_path(r"^get-working-status/$", resv.getWorkingStatus),
    re_path(r"^get-all-resources/$", resv.getAllCostResource),
    re_path(r"^get-all-res/$", resv.getAllResourcesMastcode),
    re_path(r"^get-resources/(?P<resId>[\w\-]+)/$", resv.getByIdResource),
    re_path(r"^delete-resources/(?P<resId>[\w\-]+)/$", resv.deleteResources),

    # BP Shipping
    re_path(r"^add-bp-shipping/$", bpsv.addBPShipping),
    re_path(r"^update-bp-shipping/$", bpsv.updateShipping),
    re_path(r"^get-bp-shipping/(?P<shipCode>[\w\-]+)/$", bpsv.getByIdBPShipping),
    re_path(r"^delete-bp-shipping/(?P<shipCode>[\w\-]+)/$", bpsv.deleteBPShipping),

    # Carrier
    re_path(r"^add-carrier/$", carv.addCarrier),
    re_path(r"^update-carrier/$", carv.updateCarrier),
    re_path(r"^get-carrier/$", carv.getAllCarrier),
    re_path(r"^get-carrier/(?P<carId>[\w\-]+)/$", carv.getByIdCarrier),
    re_path(r"^delete-carrier/(?P<carId>[\w\-]+)/$", carv.deleteCarrier),

    # Sales Order
    re_path(r"^add-sales-order/$", sodv.addSaleOrderDetails),
    re_path(r"^append-sales-order/$", sodv.addOrderMaterial),
    re_path(r"^get-sales-order-material/(?P<orderId>\w+)/$", sodv.getOrderMaterialByOrderId),
    re_path(r"^delete-order-material/(?P<odId>\w+)/$", sodv.deleteOrderMaterial),
    re_path(r"^delete-order/(?P<orderId>\w+)/$", sodv.deleteWholeOrder),
    re_path(r"^get-shipping/$", sodv.getShipping),
    re_path(r"^get-orders/$", sodv.getAllOrder),
    re_path(r"^get-payment-term/$", sodv.getPaymentTerm),

    # GR OTHER CHARGES
    re_path(r"^add-gr-other-charges/$", gocv.addGrOtherCharges),
    re_path(r"^delete-gr-other-charges/(?P<grno>\w+)/$", gocv.deleteGrOtherCharges),
    re_path(r"^get-gr-iqs-pending/$", gocv.getGrIqsPending),
    re_path(r"^gr-other-charges-pending/$", gocv.grOtherChargesPending),
    re_path(r"^approve-gr-other-charges/$", gocv.approveCharges),
    re_path(r"^get-days/$", gocv.getDays),



    # GR IQS REP
    re_path(r"^add-gr-iqs-rep/$", girv.addGrIqsRep),
    re_path(r"^get-rate-difference/$", girv.getRateDifferencePending),
    re_path(r"^add-gr-rate-approval/$", girv.addGrRateApproval),

   # GR QTY CLEAR
    re_path(r"^add-gr-qty-clear/$", gqcv.addGrQtyClear),
    re_path(r"^get-gr-qty-clear-pending/$", gqcv.getGrQtyClearPending),

    # ORDER PROCESSING
    re_path(r"^add-order-approval/$", opv.addOrderApproval),
    re_path(r"^add-order-cancel/$", opv.addOrderCancel),
    re_path(r"^add-order-packed/$", opv.addOrderPacked),
    re_path(r"^add-order-billed/$", opv.addOrderBilled),
    re_path(r"^add-order-goods-dispatch/$", opv.addOrderGoodsDispatch),
    re_path(r"^add-order-delivery/$", opv.addOrderDelivery),
    re_path(r"^add-order-transport/$", opv.addOrderTransport),
    re_path(r"^add-order-ap-request/$", opv.addOrderApRequest),

    # ORDER PROCESSING PENDING
    re_path(r"^get-order-ap-request-pending/$", opv.GetOrderApRequestPending),
    re_path(r"^get-order-approval-pending/$", opv.GetOrderApprovalPending),
    re_path(r"^get-order-billed-pending/$", opv.GetOrderBilledPending),
    re_path(r"^get-order-goods-dispatch-pending/$", opv.GetOrderGoodsDispatchPending),
    re_path(r"^get-order-transport-pending/$", opv.GetOrderTransportPending),
    re_path(r"^get-order-delivery-pending/$", opv.GetOrderDeliveryPending),
    re_path(r"^get-approvals/$", opv.getOrderApprovalField),
    re_path(r"^post-order-bill/$", opv.postOrderBill),
    re_path(r"^get-vehicle-type/$", opv.getVehicleType),
    re_path(r"^get-order-hold-denied/$", opv.getOrderHoldDenied),
    re_path(r"^approve-hold-denied-order/$", opv.approveHoldDeniedOrders),
    re_path(r"^reject-hold-order/$", opv.rejectOrders),
    re_path(r"^export-eway-bill-sale/$", opv.exportEwaybill),
    re_path(r"^export-einvoice/$", opv.getEInvoice),
    re_path(r"^get-billed-order/$", opv.getOrderBilledById),
    re_path(r"^update-billed-order/$", opv.updateOrderBilled),
    re_path(r"^get-order-balance/(?P<orderId>\d+)/$", opv.getOrderBalanceByOrderId),
    re_path(r"^delete-order-packaging/(?P<id>\d+)/$", opv.deleteOrderPackaging),

    re_path(r"^append-order-billed/$", opv.appendOrderBilled),
    re_path(r"^get-gst-api/$", opv.getGstApiDetails),


    # Order Packaging
    re_path(r"^add-order-packaging/$", opackv.addOrderPackaging),
    re_path(r"^add-order-packed-info/(?P<orderId>\d+)/$", opackv.getPackedInfoByOrderId),
    re_path(r"^get-order-packing-pending/$", opackv.getOrderPackingPending),

    # Wire Size
    re_path(r"^add-wire-size-details/$", wsv.addWireSizeDetails),
    re_path(r"^add-wire-size-details-only/$", wsv.addWireSizeMasterDetailsOnly),
    re_path(r"^get-cost-status/$", wsv.getCostStatus),
    re_path(r"^get-color-code/$", wsv.getColorCodes),
    re_path(r"^wire-rep/$", wsv.getWireRepType),
    re_path(r"^wire-sort-type/$", wsv.getWireSortType),
    re_path(r"^get-wire-size/(?P<matno>[\w\-.]+)/$", wsv.getWireSizeByMatNo),
    re_path(r"^get-wire-size-details/(?P<matno>[\w\-.]+)/$", wsv.getWireSizeDetailsByMatNo),
    re_path(r"^delete-full-wire-size-details/$", wsv.deleteWholeWireSizeDetails),
    re_path(r"^delete-wire-size-details/$", wsv.deleteSpecificWireDetail),
    re_path(r"^update-wire-size-details/$", wsv.updateWireSizeDetails),
    re_path(r"^update-wire-size/$", wsv.updateWireSizeMaster),

    # Payment
    re_path(r"^get-pay-type/$", payv.getPayType),
    re_path(r"^add-payment/$", payv.addPayment),
    re_path(r"^add-payment-clear/$", payv.addPaymentClear),
    re_path(r"^add-dbnote-clear/$", payv.addDbNoteClear),
    re_path(r"^add-crnote-clear/$", payv.addCrNoteClear),
    re_path(r"^add-prtax-invoice-clear/$", payv.addPrTaxInvoiceClear),
    re_path(r"^delete-payment-clear/(?P<id>\d+)/$", payv.deletePaymentClear),
    re_path(r"^get-bill-pending-by-transId/(?P<transId>\w+)/$", payv.getByTransIdBillPending),
    re_path(r"^get-voucher-type/$", payv.getVoucherType),
    re_path(r"^get-payment-advance-pending/$", payv.getPaymentAdvancePending),
    re_path(r"^get-unadjusted-payment-pending/$", payv.getUnadjustedPayment),
    re_path(r"^get-bill-pending-by-transId/$", payv.getBillPendingByTransId),
    re_path(r"^get-inward-clear/$", payv.getInwardClear),
    re_path(r"^get-bill-pending-by-lcode/(?P<lCode>[\w\-\.]+)/$", payv.getBillPendingByLcode),

    # Bank Details
    re_path(r"^upload-bank-details/$", buv.uploadBankDetails),
    re_path(r"^update-bank-statement/$", buv.updateBankStatement),
    re_path(r"^upload-hdfc/$", buv.uploadHdfc),
    re_path(r"^upload-kotak/$", buv.uploadKotak),
    

    # Part Assembly
    re_path(r"^get-work-process/$", papv.getWorkProcess),
    re_path(r"^get-rm-type/$", papv.getRmType),
    re_path(r"^add-pa/$", papv.addPartAssembly),
    re_path(r"^update-pa/$", papv.updatePartAssembly),
    re_path(r"^add-pa-details/$", papv.addPartAssemblyDetails),
    re_path(r"^add-pa-processing/$", papv.addPartAssemblyProcessing),
    re_path(r"^get-pa-matno/(?P<matno>[\w\-.]+)/$", papv.getPartAssemblyByMatno),
    re_path(r"^get-pa-details-matno/(?P<matno>[\w\-.]+)/$", papv.getPartAssemblyDetailsByMatno),
    re_path(r"^get-pa-processing-matno/(?P<matno>[\w\-.]+)/$", papv.getPartAssemblyProcessingByMatno),
    re_path(r"^delete-pa/(?P<matno>[\w\-.]+)/$", papv.deletePartAssembly),
    re_path(r"^delete-pa-details/(?P<padId>\d+)/$", papv.deletePartAssemblyDetails),
    re_path(r"^delete-pa-processing/(?P<papId>\d+)/$", papv.deletePartAssemblyProcessing),
    re_path(r"^part-assembly-report/$", papv.getPartAssemblyReport),
    re_path(r"^get-wip/$", papv.getWorkInProgress),

    # Part Sub Assembly
    re_path(r"^add-psa/$", psapv.addPartSubAssembly),
    re_path(r"^update-psa/$", psapv.updatePartSubAssembly),
    re_path(r"^add-psa-details/$", psapv.addPartSubAssemblyDetails),
    re_path(r"^add-psa-processing/$", psapv.addPartSubAssemblyProcessing),
    re_path(r"^get-psa-matno/(?P<matno>[\w\-.]+)/$", psapv.getBymatnoPartSubAssembly),
    re_path(r"^get-psa-details-matno/(?P<matno>[\w\-.]+)/$", psapv.getBymatnoPartSubAssemblyDetails),
    re_path(r"^get-psa-processing-matno/(?P<matno>[\w\-.]+)/$", psapv.getBymatnoPartSubAssemblyProcessing),
    re_path(r"^delete-psa/(?P<matno>[\w\-.]+)/$", psapv.deletePartSubAssembly),
    re_path(r"^delete-psa-details/(?P<padId>\d+)/$", psapv.deletePartSubAssemblyDetails),
    re_path(r"^delete-psa-processing/(?P<papId>\d+)/$", psapv.deletePartSubAssemblyProcessing),
    re_path(r"^part-sub-assembly-report/$", psapv.getPartSubAssemblyReport),

    # Product Breakup
    re_path(r"^add-pbu/$", pbuv.addProductBreakup),
    re_path(r"^update-pbu/$", pbuv.updateProductBreakup),
    re_path(r"^add-pbu-details/$", pbuv.addProductBreakupDetails),
    re_path(r"^add-pbu-processing/$", pbuv.addProductBreakupProcessing),
    re_path(r"^get-pbu-matno/(?P<matno>[\w\-.]+)/$", pbuv.getProductBreakupByMatno),
    re_path(r"^get-pbu-details-matno/(?P<matno>[\w\-.]+)/$", pbuv.getProductBreakupDetailsByMatno),
    re_path(r"^get-pbu-processing-matno/(?P<matno>[\w\-.]+)/$", pbuv.getProductBreakupProcessingByMatno),
    re_path(r"^delete-pbu/(?P<matno>[\w\-.]+)/$", pbuv.deleteProductBreakup),
    re_path(r"^delete-pbu-details/(?P<padId>\d+)/$", pbuv.deleteProductBreakupDetails),
    re_path(r"^delete-pbu-processing/(?P<papId>\d+)/$", pbuv.deleteProductBreakupProcessing),

    # PRODUCT BREAKUP INDIVIDUAL TABLES
    re_path(r"^add-pbu-tech-details/$", pbuv.addProductBreakup_TechDetails),
    re_path(r"^add-pbu-rm-process/$", pbuv.addRmInprocessStandard),
    re_path(r"^add-pbu-final-standard/$", pbuv.addProductFinalStandard),
    re_path(r"^pbu-report/$", pbuv.getProductBreakupReport),

    # Journal Voucher
    re_path(r"^add-jvoucher/$", jvv.addJournalVoucher),
    re_path(r"^get-jvoucher/$", jvv.getAllJVoucher),
    re_path(r"^delete-jvoucher/$", jvv.deleteJVoucher),

    # Sale Purchase Transfer
    re_path(r"^add-sale-transfer/$", sptv.addSaleTransfer),
    re_path(r"^add-purchase-transfer/$", sptv.addPurchaseTransfer),
    re_path(r"^add-purchase-transfer-clear/$", sptv.addPurchaseTransferClear),
    re_path(r"^add-sale-transfer-clear/$", sptv.addSaleTransferClear),
    re_path(r"^get-pay-pending-type/$", sptv.getPaymentPendingType),

    # Payment Inward
    re_path(r"^add-payment-inward/$", payiv.addPaymentInward),
    re_path(r"^get-unadjusted-payment-inward/$", payiv.getUnadjustedPaymentInward),
    re_path(r"^get-payment-pending-lcode/(?P<lcode>[\w\-\.]+)/$", payiv.getPaymentPendingByLcode),
    re_path(r"^get-payment-pending-transId/$", payiv.getPaymentPendingByTransIdVtype),
    re_path(r"^post-payment-inward/$", payiv.postPaymentInward),
    re_path(r"^bank-statement-transDate/$", payiv.getBankStatementByTransDate),

    # Work Process
    re_path(r"^add-work-process/$", wpv.addWorkProcess),
    re_path(r"^update-work-process/$", wpv.updateWorkProcess),
    re_path(r"^get-work-process/$", wpv.getAllWorkProcess),
    re_path(r"^get-by-id-work-process/$", wpv.getAByIdWorkProcess),
    re_path(r"^delete-work-process/$", wpv.deleteWorkProcess),

    # Cost Resource
    re_path(r"^add-cost-resource/$", crv.addCostResource),
    re_path(r"^update-cost-resource/$", crv.updateCostResource),
    re_path(r"^get-cost-resource/$", crv.getAllResource),
    re_path(r"^get-by-id-cost-resource/$", crv.getByIdResource),
    re_path(r"^delete-cost-resource/$", crv.deleteResource),

    # Material Incoming Standard
    re_path(r"^add-mat-inc-std/$", misv.addMaterialIncomingStandard),
    re_path(r"^get-mat-inc-std/$", misv.getAllMaterialIncomingStandard),
    re_path(r"^delete-mat-inc-std/$", misv.deleteMaterialIncomingStandard),
    re_path(r"^get-test-type/$", misv.getTestType),

    # Manufacturing
    re_path(r"^add-manufacturing/$", manuv.addManufacturing),
    re_path(r"^delete-manufacturing/$", manuv.deleteManufacturing),
    
    # Job Work Out
    re_path(r"^add-job-work-out/$", jwov.createJobWorkOutDetails),
    re_path(r"^add-job-work-out-auto/$", jwov.addJobWOrkOutAuto),
    re_path(r"^get-job-process/$", jwov.getJobProcess),
    re_path(r"^get-jw-goods-type/$", jwov.getGoodsType),
    re_path(r"^get-req-job-work-pending/$", jwov.getReqJobWorkOutPending),
    re_path(r"^get-req-id/$", jwov.getByIdReq),

    # Requirement
    re_path(r"^add-req/$", reqv.addReq),
    re_path(r"^add-req-details/$", reqv.addReqDetails),
    re_path(r"^get-req-mode/$", reqv.getReqMode),
    re_path(r"^get-req-type/$", reqv.getReqType),
    re_path(r"^get-department/$", reqv.getDepartment),

    # Requirement Production
    re_path(r"^add-req-production/$", reqpv.addReqProduction),
    re_path(r"^get-req-production-pending/$", reqpv.getReqProductionPending),

    # Packing and Packed REQUIREMENT

    re_path(r"^add-req-packing/$", rppv.addReqPacking),
    re_path(r"^get-req-packing-pending/$", rppv.getReqPackingPending),
    re_path(r"^add-req-packed/$", rppv.addReqPacked),
    re_path(r"^get-req-packed-pending/$", rppv.getReqPackedPending),

    # REQUIREMENT ISSUE
    re_path(r"^add-req-issue/$", rqeiv.addReqIssue),
    re_path(r"^get-req-issue-pending/$", rqeiv.getReqIssuePending),
    re_path(r"^get-req-mat-by-reqId/$", rqeiv.getReqMaterialPendingByReqId),
    re_path(r"^get-department/$", rqeiv.getDepartment),
    re_path(r"^req-type/$", rqeiv.getRequirementType),
    re_path(r"^req-summary/$", rqeiv.getReqSummary),
    re_path(r"^req-detail-byId/$", rqeiv.getReqDetailsById),
    re_path(r"^update-req-details/$", rqeiv.updateReqDetails),

    # DL CHALLAN
    re_path(r"^add-dl-challan/$", dlcv.addDlChallan),
    re_path(r"^get-challan-type/$", dlcv.getChallanType),

    # JOB WORKOUT CHALLAN CLEAR
    re_path(r"^add-job-challan-clear/$", jwoccv.addJobWorkOutChallanClear),

    # PRODUCTION PLAN
    re_path(r"^add-production-plan/$", ppv.addProductionPlan),
    re_path(r"^get-production-plan/(?P<ppid>\d+)/$", ppv.getByIdProductionPlan),
    re_path(r"^delete-production-plan/$", ppv.deleteProductionPlan),
    re_path(r"^delete-all-production-plan/$", ppv.deleteAllProductionPlan),

    # PRODUCTION PLAN A
    re_path(r"^add-production-planA/$", ppav.addProductionPlanA),

    # Material Return
    re_path(r"^add-material-return/$", matrv.addMaterialReturn),

    # LINE REJECTION
    re_path(r'^add-line-rejection/$', lrv.addLineRejection),
    re_path(r'^line-rejection-pending/$', lrv.getLineRejectionPending),
    re_path(r'^delete-line-rejection/$', lrv.deleteLineRejection),

    # Advance Sales Order
    re_path(r'^add-sale-order-adv/$', asov.addAdvanceSaleOrderDetails),

    # Payment Inward Clear
    re_path(r'^add-payment-inward-clear/$', picv.addPaymentInwardClear),
    re_path(r'^add-unadj-payment-inward-clear/$', picv.addUnadjustedPaymentInwardClear),
    re_path(r'^add-unadj-payment-clear/$', picv.addUnAdjustedPaymentClear),

    # Advance Requirement
    re_path(r'^add-advance-req/$', advreqv.addAdvanceReq),

    # RE-Order Balance Material
    re_path(r'^reorder-balance-material/$', rovmv.reportReOrderBalanceMaterial),
    re_path(r'^create-balance-order/$', rovmv.createBalanceOrder),

    # REVERSE CHARGES
    re_path(r'^add-reverse-charge/$', rcv.addReverseCharges),

    # OB MATERIAL
    re_path(r'^add-ob-material/$', obmv.addObMaterial),
    re_path(r'^update-ob-material/$', obmv.UpdateObMaterial),
    re_path(r'^get-ob-material/$', obmv.getObMaterialByMatno),
    re_path(r'^delete-ob-material/$', obmv.deleteObMaterial),

    # MATERIAL ASSEMBLY
    re_path(r'^add-material-assembly/$', mav.addMaterialAssembly),
    re_path(r'^update-material-assembly/$', mav.updateMaterialAssembly),
    re_path(r'^add-material-assembly-details/$', mav.addMaterialAssemblyDetails),
    re_path(r'^add-material-assembly-processing/$', mav.addMaterialAssemblyProcessing),
    re_path(r'^get-material-assembly/$', mav.getMaterialAssemblyByMatno),
    re_path(r'^get-material-assembly-details/$', mav.getMaterialAssemblyDetailsByMatno),
    re_path(r'^get-material-assembly-processing/$', mav.getMaterialAssemblyProcessingByMatno),


    re_path(r'^delete-mat-assembly/$', mav.deleteMaterialAssembly),
    re_path(r'^delete-mat-assembly-details/$', mav.deleteMaterialAssemblyDetails),
    re_path(r'^delete-mat-assembly-processing/$', mav.deleteMaterialAssemblyProcessing),

    re_path(r"^mat-assembly-breakup/(?P<matno>[\w\-]+)/(?P<cid>\w+)/$", mav.getMaterialAssemblyBreakup),
    re_path(r"^product-breakup/(?P<matno>[\w\-]+)/(?P<cid>\w+)/$", mav.getProductBreakup),
    re_path(r"^part-assembly/(?P<matno>[\w\-]+)/(?P<cid>\w+)/$", mav.getPartAssembly),
    re_path(r"^part-sub-assembly/(?P<matno>[\w\-]+)/(?P<cid>\w+)/$", mav.getPartSubAssembly),


    # OB MATERIAL
    re_path(r'^add-bp-on-board/$', bponv.addBusinessPartnerOnBoard),
    re_path(r'^update-bp-on-board/$', bponv.UpdateBusinessPartnerOnBoard),
    re_path(r'^get-bp-on-board/$', bponv.getBusinessPartnerOnBoardByMatno),
    re_path(r'^delete-bp-on-board/$', bponv.deleteBusinessPartnerOnBoard),
    re_path(r'^bp-on-board-report/$', bponv.getBpOnBoardReport),

    # BUSINESS PARTNER OB MATERIAL
    re_path(r'^add-bp-ob-material/$', bpobmv.addBusinessPartnerObMaterial),
    re_path(r'^update-bp-ob-material/$', bpobmv.UpdateBusinessPartnerObMaterial),
    re_path(r'^get-bp-ob-material/$', bpobmv.getBusinessPartnerObMaterialById),
    re_path(r'^delete-bp-ob-material/$', bpobmv.deleteBusinessPartnerObMaterial),
    re_path(r'^get-bp-ob/$', bpobmv.getBpObDropdown),
    
    
    # BUSINESS PARTNER OB MATERIAL
    re_path(r'^add-material-assembly-tech-details/$', matatv.addMaterialAssemblyTechDetails),
    re_path(r'^update-material-assembly-tech-details/$', matatv.UpdateMaterialAssemblyTechDetails),
    re_path(r'^get-material-assembly-tech-details/$', matatv.getMaterialAssemblyTechDetailsById),
    re_path(r'^delete-material-assembly-tech-details/$', matatv.deleteMaterialAssemblyTechDetails),

    # BP BREAKUP
    re_path(r'^add-bp-breakup/$', bpbreakv.addBpBreakup),
    re_path(r'^update-bp-breakup/$', bpbreakv.updateBpBreakup),
    re_path(r'^add-bp-breakup-details/$', bpbreakv.addBpBreakupDetails),
    re_path(r'^add-bp-breakup-processing/$', bpbreakv.addBpBreakupProcessing),

    re_path(r'^get-bp-breakup/$', bpbreakv.getBybpbIdBPBreakup),
    re_path(r'^get-bp-breakup-details/$', bpbreakv.getBybpbIdBPBreakupDetails),
    re_path(r'^get-bp-breakup-processing/$', bpbreakv.getBybpbIdBPBreakupProcessing),

    re_path(r'^delete-bp-breakup/$', bpbreakv.deleteBpBreakup),
    re_path(r'^delete-bp-breakup-details/$', bpbreakv.deleteBpBreakupDetails),
    re_path(r'^delete-bp-breakup-processing/$', bpbreakv.deleteBpBreakupProcessing),
    re_path(r'^get-ob-mat/(?P<bpCode>[\w\-]+)/$', bpbreakv.getObMaterialbyObBpCode),
    re_path(r'^get-ob-mat-dropdown/(?P<bpCode>[\w\-]+)/$', bpbreakv.getObMaterialDropdown),
    re_path(r'^get-bp-processing/(?P<bpCode>[\w\-]+)/$', bpbreakv.getPid),
    re_path(r'^get-bp-breakup-report/$', bpbreakv.getBpBreakupReport),

    # BUSINESS PARTNER PROCESSING
    re_path(r'^add-bp-processing/$', bppv.addBusinessPartnerProcessing),
    re_path(r'^update-bp-processing/$', bppv.UpdateBusinessPartnerProcessing),
    re_path(r'^delete-bp-processing/$', bppv.deleteBusinessPartnerProcessing),
    re_path(r'^get-bp-processing/$', bppv.getBusinessPartnerProcessingById),

    # MATERIAL TECH DETAILS
    re_path(r'^add-material-tech-details/$', mtv.addMaterialTechDetails),
    re_path(r'^update-material-tech-details/$', mtv.updateMaterialTechDetails),
    re_path(r'^delete-material-tech-details/$', mtv.deleteMaterialTechDetails),
    re_path(r'^get-material-tech-details/$', mtv.getMaterialTechDetails),
    re_path(r'^material-tech-details-report/$', mtv.getMaterialTechDetailsReport),




] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)


# url(r'^edit-item/(?P<pk>[\w\-]+)/$', views.EditItem),