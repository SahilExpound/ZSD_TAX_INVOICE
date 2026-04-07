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
//  key a.CompanyCode,
//  key a.FiscalYear,
      b.base64_3 as base64,
      b.base64_4,
      b.base64_5,
      b.base64_6,
//      b.base64_main,
      b.m_ind
}
where a.BillingDocumentType = 'F2'
   or a.BillingDocumentType = 'JSTO'

  
