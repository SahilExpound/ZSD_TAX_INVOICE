
CLASS zbg_tax_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .
    INTERFACES if_serializable_object .
    data im_text type string.
    DATA : N(1) TYPE N.
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


    CREATE OBJECT lo_pfd.
    CLEAR N.
*    DO 4 TIMES.
*
*    N = N + 1.
*    if n = 1.
*        im_text = 'ORIGINAL FOR BUYER'.
*     elseif n = 2. im_text = 'DUPLICATE FOR TRANSPORTER'.
*     elseif n = 3. im_text = 'TRIPLICATE FOR SUPPLIER'.
*     elseif n = 4. im_text = 'TRIPLICATE FOR SUPPLIER'.
*    endif.
*    lo_pfd->get_pdf_64( EXPORTING io_billingdocument = im_bill
*                                  io_text    = im_text  RECEIVING pdf_64 = DATA(pdf_64) ).
*
*
*    wa_data-billingdocument    = im_bill.
*    IF N = 1.
*    wa_data-base64_3 = pdf_64.
*    ELSEIF N = 2.
*     wa_data-base64_4 = pdf_64.
*    ELSEIF N = 3.
*     wa_data-base64_5 = pdf_64.
*     ELSEIF N = 3.
*     wa_data-base64_6 = pdf_64.
*    ENDIF.
*    wa_data-m_ind    = im_ind.
*
*    MODIFY ztb_tax_new FROM @wa_data.  "<-write your table name
*
*    IF N = 1.
*    SELECT SINGLE
*    companycode,
*    fiscalyear,
*    billingdocument,
*    BillingDocumentType
*    FROM i_billingdocument
*    WHERE billingdocument = @im_bill
*    INTO @DATA(wa_sign1).
*
*    wa_sign-billingdocument = im_bill.
*    wa_sign-base64_3        = pdf_64.
*    wa_sign-m_ind           = im_ind.
*
*    wa_sign-companycode = wa_sign1-companycode.
*    wa_sign-fiscalyear  = wa_sign1-fiscalyear.
*    wa_sign1-BillingDocumentType = wa_sign1-BillingDocumentType.
*    MODIFY ztd_sign_b64 FROM @wa_sign.
*    ENDIF.
*    ENDDO.

*DO 4 TIMES.
*
*  n = n + 1.
*
*  " dynamic text
*  IF n = 1.
*     im_text = 'ORIGINAL FOR BUYER'.
*
*  ELSEIF n = 2.
*     im_text = 'DUPLICATE FOR TRANSPORTER'.
*
*  ELSEIF n = 3.
*     im_text = 'TRIPLICATE FOR SUPPLIER'.
*
*  ELSEIF n = 4.
*     im_text = 'EXTRA COPY'.
*
*  ENDIF.
*
*
*  " generate PDF
*  lo_pfd->get_pdf_64(
*      EXPORTING
*         io_billingdocument = im_bill
*         iv_copy_text       = im_text
*      RECEIVING
*         pdf_64 = DATA(pdf_64)
*  ).
*
*
*  wa_data-billingdocument = im_bill.
*  wa_data-m_ind = im_ind.
*
*
*  " store base64 in different column
*  IF n = 1.
*
*     wa_data-base64_3 = pdf_64.
*
*  ELSEIF n = 2.
*
*     wa_data-base64_4 = pdf_64.
*
*  ELSEIF n = 3.
*
*     wa_data-base64_5 = pdf_64.
*
*  ELSEIF n = 4.
*
*     wa_data-base64_6 = pdf_64.
*
*  ENDIF.
*
*
*  " save record each time (important)
*  MODIFY ztb_tax_new FROM @wa_data.
*
*
*  " store in sign table only once
*  IF n = 1.
*
*     SELECT SINGLE
*        companycode,
*        fiscalyear,
*        billingdocument,
*        BillingDocumentType
*     FROM i_billingdocument
*     WHERE billingdocument = @im_bill
*     INTO @DATA(wa_sign1).
*
*
*     wa_sign-billingdocument = im_bill.
*     wa_sign-base64_3 = pdf_64.
*     wa_sign-m_ind = im_ind.
*
*     wa_sign-companycode = wa_sign1-companycode.
*     wa_sign-fiscalyear = wa_sign1-fiscalyear.
*
*     MODIFY ztd_sign_b64 FROM @wa_sign.
*
*  ENDIF.
*
*ENDDO.


DATA lv_pdf1 TYPE string.
DATA lv_pdf2 TYPE string.
DATA lv_pdf3 TYPE string.
DATA lv_pdf4 TYPE string.

DATA lv_x1 TYPE xstring.
DATA lv_x2 TYPE xstring.
DATA lv_x3 TYPE xstring.
DATA lv_x4 TYPE xstring.

DATA lv_merged_x TYPE xstring.
DATA lv_merged_base64 TYPE string.


DO 4 TIMES.

  n = n + 1.

  IF n = 1.
     im_text = 'ORIGINAL FOR BUYER'.
  ELSEIF n = 2.
     im_text = 'DUPLICATE FOR TRANSPORTER'.
  ELSEIF n = 3.
     im_text = 'TRIPLICATE FOR SUPPLIER'.
  ELSEIF n = 4.
     im_text = 'EXTRA COPY'.
  ENDIF.

  lo_pfd->get_pdf_64(
      EXPORTING
         io_billingdocument = im_bill
         iv_copy_text       = im_text
      RECEIVING
         pdf_64 = DATA(pdf_64)
  ).


  wa_data-billingdocument = im_bill.
  wa_data-m_ind = im_ind.


  IF n = 1.

     wa_data-base64_3 = pdf_64.
     lv_pdf1 = pdf_64.

  ELSEIF n = 2.

     wa_data-base64_4 = pdf_64.
     lv_pdf2 = pdf_64.

  ELSEIF n = 3.

     wa_data-base64_5 = pdf_64.
     lv_pdf3 = pdf_64.

  ELSEIF n = 4.

     wa_data-base64_6 = pdf_64.
     lv_pdf4 = pdf_64.

  ENDIF.


  MODIFY ztb_tax_new FROM @wa_data.


ENDDO.

lv_x1 = cl_web_http_utility=>decode_x_base64( wa_data-base64_3 ).
lv_x2 = cl_web_http_utility=>decode_x_base64( wa_data-base64_4 ).
lv_x3 = cl_web_http_utility=>decode_x_base64( wa_data-base64_5 ).
lv_x4 = cl_web_http_utility=>decode_x_base64( wa_data-base64_6 ).

TYPES: BEGIN OF ty_pdf,
         pdf TYPE xstring,
       END OF ty_pdf.

DATA lt_pdf TYPE STANDARD TABLE OF ty_pdf.

APPEND VALUE #( pdf = lv_x1 ) TO lt_pdf.
APPEND VALUE #( pdf = lv_x2 ) TO lt_pdf.
APPEND VALUE #( pdf = lv_x3 ) TO lt_pdf.
APPEND VALUE #( pdf = lv_x4 ) TO lt_pdf.



LOOP AT lt_pdf INTO DATA(ls_pdf).

  IF lv_merged_x IS INITIAL.
     lv_merged_x = ls_pdf-pdf.
  ELSE.

     CONCATENATE lv_merged_x ls_pdf-pdf
     INTO lv_merged_x IN BYTE MODE.

  ENDIF.

ENDLOOP.

DATA lv_final_pdf TYPE string.

lv_final_pdf =
cl_web_http_utility=>encode_x_base64( lv_merged_x ).





" store merged pdf
wa_data-base64_main = lv_final_pdf.

MODIFY ztb_tax_new FROM @wa_data.









  ENDMETHOD.
ENDCLASS.
