
CLASS zbg_tax_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .
    INTERFACES if_serializable_object .

    METHODS constructor
      IMPORTING
        iv_bill  TYPE zsd_char
*        iv_bukrs TYPE bukrs
*        iv_gjahr TYPE gjahr
        iv_m_ind TYPE abap_boolean.


  PROTECTED SECTION.
    DATA : im_bill TYPE zsd_char,
           im_ind  TYPE abap_boolean.
*           im_bukrs TYPE bukrs,
*           im_gjahr TYPE gjahr.

    METHODS modify
      RAISING
        cx_bgmc_operation.
  PRIVATE SECTION.
ENDCLASS.



CLASS zbg_tax_invoice IMPLEMENTATION.


  METHOD constructor.
    im_bill = iv_bill.
    im_ind  = iv_m_ind.
*    im_bukrs = iv_bukrs.
*    im_gjahr = iv_gjahr.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    modify( ).
  ENDMETHOD.


  METHOD modify.
    DATA : wa_data TYPE ztb_tax_new.  "<-write your table name
    DATA :lv_pdftest TYPE string.
    DATA lo_pfd TYPE REF TO zcl_tax_invoice.  "<-write your logic class
    DATA : wa_sign TYPE ztd_sign_b64.
    DATA : N(1) TYPE N.

    CREATE OBJECT lo_pfd.
    CLEAR N.
    DO 4 TIMES.

    N = N + 1.
    lo_pfd->get_pdf_64( EXPORTING io_billingdocument = im_bill RECEIVING pdf_64 = DATA(pdf_64) ).


    wa_data-billingdocument    = im_bill.
    IF N = 1.
    wa_data-base64_3 = pdf_64.
    ELSEIF N = 2.
     wa_data-base64_4 = pdf_64.
    ENDIF.
    wa_data-m_ind    = im_ind.

    MODIFY ztb_tax_new FROM @wa_data.  "<-write your table name

    IF N = 1.
    SELECT SINGLE
    companycode,
    fiscalyear,
    billingdocument,
    BillingDocumentType
    FROM i_billingdocument
    WHERE billingdocument = @im_bill
    INTO @DATA(wa_sign1).

    wa_sign-billingdocument = im_bill.
    wa_sign-base64_3        = pdf_64.
    wa_sign-m_ind           = im_ind.

    wa_sign-companycode = wa_sign1-companycode.
    wa_sign-fiscalyear  = wa_sign1-fiscalyear.
    wa_sign1-BillingDocumentType = wa_sign1-BillingDocumentType.
    MODIFY ztd_sign_b64 FROM @wa_sign.
    ENDIF.
    ENDDO.

  ENDMETHOD.
ENDCLASS.
