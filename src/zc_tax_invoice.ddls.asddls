@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption for tax invoice'
@Metadata.ignorePropagatedAnnotations: true
@UI.headerInfo:{
    typeName: 'Tax Invoice',
    typeNamePlural: 'Tax Invoice',
    title:{ type: #STANDARD, value: 'billingdocument' } }
define root view entity ZC_TAX_INVOICE as projection on zi_tax_invoice
{
 @UI.facet: [{ id : 'billingdocument',
  purpose: #STANDARD,
  type: #IDENTIFICATION_REFERENCE,
  label: 'Tax Invoice',
   position: 10 }]
       @UI.lineItem:       [{ position: 10, label: 'billingdocument' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
  @UI.identification: [{ position: 10, label: 'billingdocument' }]
  @UI.selectionField: [{ position: 10 }]
    key billingdocument,

    base64,
    m_ind
}



