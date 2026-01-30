@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'interface for tax invoice'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity zi_tax_invoice
  as select from   I_BillingDocument as a
    left outer join ztb_tax_new   as b on a.BillingDocument = b.billingdocument 
{
  key a.BillingDocument,
      b.base64_3 as base64,
      b.m_ind
}
where a.BillingDocumentType = 'F2'
