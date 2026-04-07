CLASS zcl_tax_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS get_pdf_64
      IMPORTING
        VALUE(io_billingdocument) TYPE i_billingdocument-billingdocument
*        vaLUE(io_text)            tYPE string
        VALUE(iv_copy_text) TYPE string
      RETURNING
        VALUE(pdf_64)             TYPE string.


    METHODS get_billing_text
      IMPORTING
        iv_billingdocument     TYPE i_billingdocument-billingdocument
        iv_billingdocumentitem TYPE i_billingdocumentitem-billingdocumentitem OPTIONAL
        iv_longtextid          TYPE i_billingdocumenttexttp-longtextid
        iv_language            TYPE i_billingdocumenttexttp-language
      RETURNING
        VALUE(rv_text)         TYPE string.


    CLASS-METHODS sanitize_text
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.

    METHODS get_state_code
      IMPORTING
        iv_region           TYPE i_region-region
      RETURNING
        VALUE(rv_statecode) TYPE string.


    METHODS num2words
      IMPORTING
        iv_num          TYPE string
        iv_major        TYPE string
        iv_minor        TYPE string
        iv_top_call     TYPE abap_bool DEFAULT abap_true
      RETURNING
        VALUE(rv_words) TYPE string.


    METHODS escape_xml
      IMPORTING
        iv_in         TYPE any
      RETURNING
        VALUE(rv_out) TYPE string.

*        data im_text tYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS build_xml
      IMPORTING
        VALUE(io_billingdocument) TYPE i_billingdocument-billingdocument
        value(io_text) type string
        VALUE(iv_copy_text)       TYPE string OPTIONAL
      RETURNING
        VALUE(rv_xml)             TYPE string.



ENDCLASS.



CLASS zcl_tax_invoice IMPLEMENTATION.


  METHOD sanitize_text.

    rv_text = CONV string( iv_text ).

    " Remove NBSP (paste real NBSP between quotes)
    REPLACE ALL OCCURRENCES OF ' ' IN rv_text WITH space.


    " Escape XML special characters
    REPLACE ALL OCCURRENCES OF '&'  IN rv_text WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<'  IN rv_text WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>'  IN rv_text WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"'  IN rv_text WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF '''' IN rv_text WITH '&apos;'.

    " Remove CR / LF
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
      IN rv_text WITH space.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline
      IN rv_text WITH space.

    CONDENSE rv_text.

  ENDMETHOD.


  METHOD escape_xml.

    rv_out = CONV string( iv_in ).

    " Normalize NBSP copied from PDF (PASTE NBSP BETWEEN QUOTES)
*    REPLACE ALL OCCURRENCES OF ' ' IN rv_out WITH space.

    " Escape XML special characters ONLY
    REPLACE ALL OCCURRENCES OF '&'   IN rv_out WITH '&amp;'.
    REPLACE ALL OCCURRENCES OF '<'   IN rv_out WITH '&lt;'.
    REPLACE ALL OCCURRENCES OF '>'   IN rv_out WITH '&gt;'.
    REPLACE ALL OCCURRENCES OF '"'   IN rv_out WITH '&quot;'.
    REPLACE ALL OCCURRENCES OF ''''  IN rv_out WITH '&apos;'.

  ENDMETHOD.


  METHOD get_pdf_64.

    DATA: lt_cogm TYPE zcl_cogm=>tt_cogm.

    lt_cogm = NEW zcl_cogm( )->get_data(
                  iv_billingdocument = io_billingdocument ).

    IF lt_cogm IS NOT INITIAL.

      LOOP AT lt_cogm INTO DATA(ls_cogm).

        " Delete old entries (avoid duplicates)
        DELETE FROM ztb_cogm
          WHERE billingdocument     = @ls_cogm-billingdocument
            AND billingdocumentitem = @ls_cogm-billingdocumentitem.

        " Insert fresh data
        INSERT ztb_cogm FROM @ls_cogm.

      ENDLOOP.

      COMMIT WORK.

    ENDIF.


*    if im_text is iNITIAL.
*     im_text =  io_text.
*    endif.
*    DATA(lv_xml) = build_xml(
*                      io_billingdocument = io_billingdocument
*                      io_text    = im_text ).
*
*    SELECT SINGLE
*   salesorganization
*   FROM i_billingdocument
*   WHERE billingdocument = @io_billingdocument
*   INTO @DATA(mv_salesorg).
*
*    SELECT SINGLE
*    irn
*    FROM zi_billing_inv
*    WHERE billingdocument = @io_billingdocument
*    INTO @DATA(lv_irn).
*
*
*
*
*
*
*
*    DATA lv_template TYPE string.
**
**         if     mv_salesorg = '1000'.
**           lv_template = 'ZSD_TAX_INVOICE/ZSD_TAX_INVOICE'.
**         elseif mv_salesorg  = '2000'.
**         lv_template   =  'ZSD_MDR/ZSD_MDR'.
**         else.
**         lv_template = 'ZSD_TAX_INVOICE/ZSD_TAX_INVOICE'.
**         enDIF.
*
*
*    IF mv_salesorg = '1000' AND lv_irn IS NOT INITIAL.
*      lv_template = 'ZSD_TAX_INVOICE/ZSD_TAX_INVOICE'.
*    ELSEIF  mv_salesorg = '1000' AND lv_irn  IS INITIAL.
*      lv_template = 'ZSD_TAX_DRAFT/ZSD_TAX_DRAFT'.
*    ELSEIF mv_salesorg  = '2000'  AND lv_irn IS NOT INITIAL.
*      lv_template   =  'ZSD_MDR/ZSD_MDR'.
*    ELSEIF mv_salesorg  = '2000' AND lv_irn  IS INITIAL.
*      lv_template   =  'ZSD_MDR_WAT/ZSD_MDR_WAT'.
*    ENDIF.
*
*
**DATA:
**      lt_copy TYPE TABLE OF string,
**      lv_xml TYPE string,
**      lv_xml_all TYPE string.
***      lv_template TYPE string VALUE 'Z_TAX_INVOICE'.  "your template name
*
*
*
*
*
**    CALL METHOD zadobe_call=>getpdf
**      EXPORTING
**        template = 'ZSD_TAX_4/ZSD_TAX_4'
**        xmldata  = lv_xml
**      RECEIVING
**        result   = DATA(lv_result).
*
**    CALL METHOD zadobe_call=>getpdf
**      EXPORTING
**        template = lv_template
**        xmldata  = lv_xml
**      RECEIVING
**        result   = DATA(lv_result).
***
**    IF lv_result IS NOT INITIAL.
**      pdf_64 = lv_result.
**    ENDIF.
*
*DATA: lt_copy TYPE TABLE OF string,
*      lv_pdf  TYPE string.
*
**lt_copy = VALUE #(
**  ( CONV string( 'Original for Buyer' ) )
**  ( CONV string( 'Duplicate for Transporter' ) )
**  ( CONV string( 'Triplicate for Assessee' ) )
**  ( CONV string( 'Extra Copy' ) )
**).
*
**LOOP AT lt_copy INTO DATA(lv_copy_text).
*
*  lv_xml = build_xml(
*              io_billingdocument = io_billingdocument
*              io_text    = im_text
*               ).
*
**  CALL METHOD zadobe_call=>getpdf
**    EXPORTING
**      template = lv_template
**      xmldata  = lv_xml
**    RECEIVING
**      result   = lv_pdf.
*
*
*  CALL METHOD zadobe_call=>getpdf
*    EXPORTING
*      template = 'ZSD_TAX_4/ZSD_TAX_4'
*      xmldata  = lv_xml
*    RECEIVING
*      result   = lv_pdf.
*
*  " store or append PDFs
*  CONCATENATE pdf_64 lv_pdf INTO pdf_64.



  DATA(lv_xml) = build_xml(
                    io_billingdocument = io_billingdocument
                    io_text            = iv_copy_text ).

  DATA lv_pdf TYPE string.

  CALL METHOD zadobe_call=>getpdf
    EXPORTING
      template = 'ZSD_TAX_4/ZSD_TAX_4'
      xmldata  = lv_xml
    RECEIVING
      result   = lv_pdf.

  pdf_64 = lv_pdf.




*ENDLOOP.

  ENDMETHOD.


  METHOD build_xml.


    DATA : lv_invno             TYPE i_billingdocument-billingdocument,
           lv_comp              TYPE string,
           lv_date              TYPE string,
           lv_region            TYPE i_billingdocument-region,
           lv_addressship(1000) TYPE c,
           lv_addressbill(1000) TYPE c,
*       lv_totaltax type i_billingdocumentitemprcgelmnt-conditionamount,
           lv_invalue           TYPE i_billingdocumentitemprcgelmnt-conditionamount,
           lv_po                TYPE i_salesorder-purchaseorderbycustomer,
           lv_po_dt             TYPE string,
           lv_lrno              TYPE string,
           lv_vehno             TYPE string.

    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
      FROM i_billingdocument
      WHERE billingdocument = @io_billingdocument
      INTO @DATA(wa_billdoc).


    DATA : website TYPE string.

    IF wa_billdoc-companycode = '1000'.

      website = 'www.mpmindia.com'.

    ELSEIF wa_billdoc-companycode = '2000'.

      website = 'www.mpmdurrans.com'.

    ENDIF.

    DATA  : lv_taxabletotal TYPE i_billingdocument-totalnetamount.

    lv_taxabletotal = wa_billdoc-totalnetamount.

    IF sy-subrc = 0.
*  lv_totaltax = wa_billdoc-TotalTaxAmount.
      lv_invalue  = wa_billdoc-totalnetamount + wa_billdoc-totaltaxamount.
      lv_invno    = |{ wa_billdoc-billingdocument ALPHA = OUT }|.
      lv_date     = |{ wa_billdoc-billingdocumentdate+6(2) }.{ wa_billdoc-billingdocumentdate+4(2) }.{ wa_billdoc-billingdocumentdate+0(4) }|.
      lv_region   = wa_billdoc-region.
      lv_lrno     = wa_billdoc-yy1_lrno_bdh.
      lv_vehno    = wa_billdoc-yy1_vehicleno_bdh.
    ENDIF.

    DATA lv_inv_words TYPE string.

    lv_inv_words = num2words(
                     iv_num   = |{ lv_invalue }|
                     iv_major = 'RUPEES'
                     iv_minor = 'PAISE'
                   ).

    SELECT * FROM
    i_billingdocumentitem
    WHERE billingdocument = @io_billingdocument
    INTO TABLE @DATA(lt_billitem).


    DATA : lv_totaltax TYPE i_billingdocumentitem-taxamount.

    LOOP AT lt_billitem INTO DATA(ls_itemw).
      lv_totaltax = lv_totaltax + ls_itemw-taxamount.
    ENDLOOP.



    SELECT plant
    FROM i_plant
    WHERE plant = @ls_itemw-plant
    INTO @DATA(lv_plantno).
    ENDSELECT.

    DATA(lv_bp) = |{ 0 }{ 0 }{ 0 }{ 0 }{ 0 }{ 0 }{ lv_plantno ALPHA = IN }|.

    SELECT  *                                 "#EC CI_ALL_FIELDS_NEEDED
    FROM i_bupaidentification
    WHERE businesspartner = @lv_bp
    INTO TABLE @DATA(lv_cinudm).

    "total tax amount





    DATA: lv_udym  TYPE string,
          lv_udyms TYPE string,
          lv_cin   TYPE string.

    READ TABLE lv_cinudm INTO DATA(wa_cin) WITH KEY bpidentificationtype = 'CIN'.
    IF sy-subrc = 0.
      lv_cin = wa_cin-bpidentificationnumber.
    ENDIF.

    READ TABLE lv_cinudm INTO DATA(wa_udymmse) WITH KEY bpidentificationtype = 'ZUDYMM'.
    IF sy-subrc = 0.
      lv_udyms = wa_udymmse-bpidentificationnumber.
    ENDIF.


    READ TABLE lv_cinudm INTO DATA(wa_udymme) WITH KEY bpidentificationtype = 'ZUDYAM'.
    IF sy-subrc = 0.
      lv_udym = wa_udymme-bpidentificationnumber.
    ENDIF.


    SELECT
         a~billingdocument,
         a~billingdocumentitem,
         b~longtextid,
         b~language,
         b~longtext,
         a~salesdocument
     FROM i_billingdocumentitem AS a
     INNER JOIN i_billingdocumenttexttp AS b
       ON  a~billingdocument     = b~billingdocument
     WHERE a~billingdocument = @io_billingdocument
     INTO TABLE @DATA(it_billdoc_item).


*    READ TABLE it_billdoc_item INTO DATA(wa_addinfo) WITH KEY longtextid = 'ZS05'.
*    IF sy-subrc = 0.
*      DATA(lv_addinfo) = get_billing_text(
*                       iv_billingdocument     = io_billingdocument
*                       iv_longtextid          = wa_addinfo-longtextid
*                       iv_language            = wa_addinfo-language ).
*
*    ENDIF.
*
*    READ TABLE it_billdoc_item INTO DATA(wa_asn) WITH KEY longtextid = 'ZS00'.
*    IF sy-subrc = 0.
*      DATA(lv_asn) = get_billing_text(
*                       iv_billingdocument     = io_billingdocument
*                       iv_longtextid          = wa_asn-longtextid
*                       iv_language            = wa_asn-language ).
*
*    ENDIF.
*
*    READ TABLE it_billdoc_item INTO DATA(wa_pkdg) WITH KEY longtextid = 'ZS06'.
*    IF sy-subrc = 0.
*      DATA(lv_pk) = get_billing_text(
*                       iv_billingdocument     = io_billingdocument
*                       iv_longtextid          = wa_pkdg-longtextid
*                       iv_language            = wa_pkdg-language ).
*
*    ENDIF.
*
    READ TABLE it_billdoc_item INTO DATA(wa_lrno) WITH KEY longtextid = 'ZS01'.
    IF sy-subrc = 0.
      lv_lrno = get_billing_text(
                       iv_billingdocument     = io_billingdocument
                       iv_longtextid          = wa_lrno-longtextid
                       iv_language            = wa_lrno-language ).

    ENDIF.
*
*    READ TABLE it_billdoc_item INTO DATA(wa_vehno) WITH KEY longtextid = 'ZS04'.
*    IF sy-subrc = 0.
*      lv_vehno = get_billing_text(
*                       iv_billingdocument     = io_billingdocument
*                       iv_longtextid          = wa_vehno-longtextid
*                       iv_language            = wa_vehno-language ).
*
*    ENDIF.
*
*    READ TABLE it_billdoc_item INTO DATA(wa_distr) WITH KEY longtextid = 'ZS03'.
*    IF sy-subrc = 0.
*      DATA(lv_distr) = get_billing_text(
*                       iv_billingdocument     = io_billingdocument
*                       iv_longtextid          = wa_distr-longtextid
*                       iv_language            = wa_distr-language ).
*
*    ENDIF.


    DATA : lv_addinfo TYPE string,
           lv_asn     TYPE string,
           lv_pk      TYPE string,
           lv_distr   TYPE string,
           lv_placeof TYPE string.







    SELECT SINGLE * FROM
    i_billingdocument
    WHERE billingdocument = @io_billingdocument
    INTO  @DATA(all_data).

    lv_addinfo = all_data-yy1_additionalinformat_bdh.
    lv_asn = all_data-yy1_asnnumber_bdh.
    lv_pk = all_data-yy1_packagingdetails_bdh.
    lv_distr = all_data-yy1_dispatchthrough_bdh.


    SELECT SINGLE * FROM
    i_customer
    WHERE customer = @all_data-soldtoparty
    INTO @DATA(placeofsupply).




    "plant gstin
    DATA : lv_gstino   TYPE string,
           lv_terofpay TYPE string.

    IF lt_billitem IS NOT INITIAL.

      SELECT
      businessplace,
      plant
      FROM i_plant
      FOR ALL ENTRIES IN @lt_billitem
      WHERE plant = @lt_billitem-plant
      INTO @DATA(lv_plant).
      ENDSELECT.

      SELECT SINGLE * FROM                    "#EC CI_ALL_FIELDS_NEEDED
      i_businessplace
      WHERE businessplace = @lv_plant-businessplace
      INTO @DATA(lv_gstin).


      lv_gstino = lv_gstin-in_gstidentificationnumber.

    ENDIF.





    IF lt_billitem IS NOT INITIAL.

      SELECT
      purchaseorderbycustomer,
      customerpurchaseorderdate,
      customerpaymentterms
      FROM i_salesorder
      FOR ALL ENTRIES IN @lt_billitem
      WHERE salesorder = @lt_billitem-salesdocument
      INTO @DATA(wa_so).
      ENDSELECT.

      SELECT SINGLE *
*    paymentTerms,
*    paymenttermsName
   FROM i_paymenttermstext
   WHERE paymentterms = @wa_so-customerpaymentterms
   INTO @DATA(ly_payte).


      lv_po = wa_so-purchaseorderbycustomer.
      lv_po_dt = |{ wa_so-customerpurchaseorderdate+6(2) }.{ wa_so-customerpurchaseorderdate+4(2) }.{ wa_so-customerpurchaseorderdate+0(4) }|..
      lv_terofpay  = ly_payte-paymenttermsname.
    ENDIF.



    SELECT
    bd~salesorganization,
    sd~addressid
    FROM i_billingdocument AS bd
    INNER JOIN i_salesorganization AS sd
    ON bd~salesorganization = sd~salesorganization
    WHERE bd~billingdocument = @io_billingdocument
    INTO TABLE @DATA(it_salesorg).







    "---------------Header Address------------

    DATA : lv_hdaddr TYPE string,
           lv_telph  TYPE i_addressphonenumber_2-phoneareacodesubscribernumber,
           lv_email  TYPE i_addressemailaddress_2-emailaddress,
           lv_url    TYPE string,
           lv_regoff TYPE string.



    SELECT
    sd~addressid,
    bd~salesorganization
    FROM i_salesorganization AS sd
    INNER JOIN i_billingdocument AS bd
    ON  bd~salesorganization = sd~salesorganization
    AND bd~billingdocument = @io_billingdocument
    INTO @DATA(wa_addrhead).
    ENDSELECT.


    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
    FROM i_billingdocumentitem
    WHERE billingdocument = @io_billingdocument
    INTO @DATA(wa_plant).

    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
    FROM i_plant
    WHERE plant = @wa_plant-plant
    INTO @DATA(wa_plantid).

    IF sy-subrc = 0.

      SELECT SINGLE *                         "#EC CI_ALL_FIELDS_NEEDED
      FROM i_address_2
      WITH PRIVILEGED ACCESS
      WHERE addressid = @wa_plantid-addressid
      INTO @DATA(wa_hddata).

      SELECT SINGLE *                         "#EC CI_ALL_FIELDS_NEEDED
 FROM i_address_2
 WITH PRIVILEGED ACCESS
 WHERE addressid = @wa_addrhead-addressid
 INTO @DATA(wa_regoffaddr).


      lv_comp = wa_regoffaddr-organizationname1.

      SELECT SINGLE *
          FROM
          i_regiontext
          WHERE region = @wa_hddata-region
          AND country = @wa_hddata-country
          INTO @DATA(wa_regoff).




      lv_hdaddr = |{ wa_hddata-streetprefixname1 }\n{ wa_hddata-streetprefixname2 } ,{ wa_hddata-cityname }-{ wa_hddata-postalcode } |.
      lv_regoff  = |{ wa_regoffaddr-streetname },{ wa_regoffaddr-cityname }-{ wa_regoffaddr-postalcode },{ wa_regoff-regionname } |.
      lv_url = wa_hddata-streetsuffixname2.
    ENDIF.




    SELECT SINGLE
    emailaddress
    FROM i_addressemailaddress_2
    WITH PRIVILEGED ACCESS
    WHERE addressid = @wa_hddata-addressid
    INTO @lv_email.



    SELECT SINGLE
    phoneareacodesubscribernumber
    FROM i_addressphonenumber_2
    WITH PRIVILEGED ACCESS
    WHERE addressid = @wa_hddata-addressid
    INTO @lv_telph.


    DATA: lv_country     TYPE i_billingdocument-country,
          lv_state_text  TYPE i_regiontext-regionname,
          lv_region_full TYPE string,
          lv_shippcond   TYPE i_deliverydocument-shippingcondition.

    SELECT SINGLE
           b~region,
           b~country,
           r~regionname
      FROM i_billingdocument AS b
      INNER JOIN i_regiontext AS r
        ON r~country = b~country
       AND r~region  = b~region
       AND r~language = @sy-langu
      WHERE b~billingdocument = @io_billingdocument
      INTO ( @lv_region,
             @lv_country,
             @lv_state_text ).

    SELECT SINGLE
     d~billoflading,
    d~meansoftransport,
    d~shippingcondition
    FROM i_deliverydocument AS d
    INNER JOIN i_billingdocumentitem AS b
    ON d~deliverydocument = b~referencesddocument
    WHERE b~billingdocument = @io_billingdocument
    INTO @DATA(wa_del).


    lv_shippcond = wa_del-shippingcondition.      "need to disucss



    lv_region_full = |{ lv_region } { lv_state_text }|.

    "Address

    DATA : it_billp          TYPE TABLE OF i_billingdocumentitempartnertp,
           lv_gstinb         TYPE i_customer-taxnumber3,
           lv_gstins         TYPE i_customer-taxnumber3,
           lv_statecode_bill TYPE string,
           lv_statecode_ship TYPE string.

    SELECT *                                  "#EC CI_ALL_FIELDS_NEEDED
    FROM i_billingdocumentitempartnertp
    WHERE billingdocument = @io_billingdocument
    INTO TABLE @it_billp.



    READ TABLE it_billp INTO DATA(wa_billp) WITH KEY partnerfunction = 'RE'.
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_billp-customer
        INTO @DATA(wa_kna1_b).

      SELECT SINGLE * FROM i_address_2        "#EC CI_ALL_FIELDS_NEEDED
   WITH PRIVILEGED ACCESS
   WHERE addressid = @wa_kna1_b-addressid
   INTO @DATA(wa_address_bill).

      SELECT SINGLE *
      FROM
      i_regiontext
      WHERE region = @wa_address_bill-region
      AND country = @wa_address_bill-country
      INTO @DATA(lv_regionbill).

      lv_gstinb = wa_kna1_b-taxnumber3.
*  lv_addressbill = |{ wa_address_bill-organizationname1 }\n{ wa_address_bill-StreetPrefixName1 },{ wa_address_bill-StreetPrefixName2 },{ wa_address_bill-CityName }-{ wa_address_bill-PostalCode }, { lv_regionbill-RegionName },{ wa_address_bill-AddressTim
      "eZone }|.

      lv_addressbill =
        wa_address_bill-organizationname1 &&
        cl_abap_char_utilities=>newline &&
         wa_address_bill-streetname && ' ' &&
           cl_abap_char_utilities=>newline &&
        wa_address_bill-streetprefixname1 && ',' &&
        wa_address_bill-streetprefixname2 && ',' &&
        wa_address_bill-cityname && '-' &&
        wa_address_bill-postalcode && ', ' &&
        lv_regionbill-regionname && ', ' &&
        wa_address_bill-addresstimezone.

      lv_statecode_bill = get_state_code( iv_region = wa_kna1_b-region ).


    ENDIF.


    READ TABLE it_billp INTO DATA(wa_ship) WITH KEY partnerfunction = 'WE'.
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_ship-customer
        INTO @DATA(wa_kna1_s).

      SELECT SINGLE * FROM i_address_2        "#EC CI_ALL_FIELDS_NEEDED
   WITH PRIVILEGED ACCESS
   WHERE addressid = @wa_kna1_s-addressid
   INTO @DATA(wa_address_ship).

      SELECT SINGLE
      *
      FROM
      i_regiontext
      WHERE region = @wa_address_ship-region
       AND country = @wa_address_bill-country
      INTO @DATA(lv_regionname).


      lv_gstins = wa_kna1_s-taxnumber3.

*  lv_addressship = |{ wa_address_ship-organizationname1 }\n{ wa_address_ship-StreetPrefixName1 },{ wa_address_ship-StreetPrefixName2 }{ wa_address_ship-CityName }-{ wa_address_ship-PostalCode }
*                          , { lv_regionName-RegionName  },{ wa_address_ship-AddressTimeZone } |.

      lv_addressship =
        wa_address_ship-organizationname1 &&
        cl_abap_char_utilities=>newline &&
           wa_address_ship-streetname && ' ' &&
             cl_abap_char_utilities=>newline &&
        wa_address_ship-streetprefixname1 && ',' &&
        wa_address_ship-streetprefixname2 && ',' &&
        wa_address_ship-cityname && '-' &&
        wa_address_ship-postalcode && ', ' &&
        lv_regionname-regionname && ', ' &&
        wa_address_ship-addresstimezone.


      lv_statecode_ship = get_state_code( iv_region = wa_kna1_s-region ).

    ENDIF.


    TYPES: BEGIN OF ty_final,
             billingdocumentitem TYPE i_billingdocumentitem-billingdocumentitem,
             hsn                 TYPE  i_productplantbasic-consumptiontaxctrlcode,
             description         TYPE i_billingdocumentitem-billingdocumentitemtext,
             quantity            TYPE i_billingdocumentitem-billingquantity,
             uom                 TYPE i_billingdocumentitem-billingquantityunit,
             rate                TYPE i_billingdocumentitem-netamount,
             taxable_amt         TYPE i_billingdocumentitem-netamount,
             total               TYPE i_billingdocumentitem-netamount,
             cgst_rate           TYPE decfloat34,
             cgst_amt            TYPE i_billingdocumentitemprcgelmnt-conditionamount,
             cgst_total          TYPE i_billingdocumentitemprcgelmnt-conditionamount,
             sgst_rate           TYPE decfloat34,
             sgst_amt            TYPE i_billingdocumentitemprcgelmnt-conditionamount,
             sgst_total          TYPE i_billingdocumentitemprcgelmnt-conditionamount,
             igst_rate           TYPE decfloat34,
             igst_amt            TYPE i_billingdocumentitemprcgelmnt-conditionamount,
             freight             TYPE i_billingdocumentitem-netamount,
             tcsamnt             TYPE i_billingdocumentitem-netamount,
             tcsrate             TYPE i_billingdocumentitem-netamount,
             pers                TYPE  string,
             perc                TYPE string,
             peri                TYPE string,
           END OF ty_final.

    DATA: gt_final TYPE STANDARD TABLE OF ty_final,
          gs_final TYPE ty_final.



    SELECT *
  FROM i_billingdocumentitem
  WHERE billingdocument = @io_billingdocument
  AND country = 'IN'
  INTO TABLE @DATA(lt_items).




    SELECT *                                  "#EC CI_ALL_FIELDS_NEEDED
FROM i_billingdocumentitemprcgelmnt
WHERE billingdocument = @io_billingdocument
INTO TABLE @DATA(lt_prcg).

*SELECT disTINCT
*    a~billingdocument,
*    a~billingdocumentitem,
*    a~product,
*    a~netamount,
*    a~plant,
*    a~billingquantityunit,
*    a~billingquantity,
*    a~billingdocumentitemtext
*FROM i_billingdocumentitem AS a
**INNER JOIN i_billingdocumentitemprcgelmnt AS b
**  ON  a~billingdocument     = b~billingdocument
*  inNER join I_DeliveryDocumentItem as c
*  on c~DeliveryDocument = a~ReferenceSDDocument
*  and c~HigherLvlItmOfBatSpltItm = a~BillingDocumentItem
*WHERE a~billingdocument = @io_billingdocument
*  AND a~country = 'IN'
*INTO TABLE @DATA(lt_final).

    SELECT DISTINCT
        a~billingdocument,
        a~billingdocumentitem,
        a~product,
        a~netamount,
        a~plant,
        a~billingquantityunit,
        a~billingquantity,
        a~billingdocumentitemtext
    FROM i_billingdocumentitem AS a

    INNER JOIN i_deliverydocumentitem AS c
      ON c~deliverydocument = a~referencesddocument
     AND (
            c~higherlvlitmofbatspltitm = a~billingdocumentitem
         OR ( c~higherlvlitmofbatspltitm IS INITIAL
              AND c~deliverydocumentitem = a~billingdocumentitem )
         )

    WHERE a~billingdocument = @io_billingdocument
      AND a~country = 'IN'

    INTO TABLE @DATA(lt_final).

    IF lt_items IS NOT INITIAL.

      SELECT                                       "#EC CI_NO_TRANSFORM
      product,
      plant,
      consumptiontaxctrlcode
      FROM i_productplantbasic
      FOR ALL ENTRIES IN @lt_items
      WHERE product = @lt_items-product
      AND plant = @lt_items-plant
      INTO TABLE @DATA(lt_hsn).

    ENDIF.

    DATA:
      gv_cgst_total    TYPE i_billingdocumentitemprcgelmnt-conditionamount VALUE 0,
      gv_sgst_total    TYPE i_billingdocumentitemprcgelmnt-conditionamount VALUE 0,
      gv_igst_total    TYPE i_billingdocumentitemprcgelmnt-conditionamount VALUE 0,
      gv_taxable_total TYPE i_billingdocumentitem-netamount VALUE 0.

    DATA: lv_cgst_rate TYPE decfloat34 VALUE 0,
          lv_sgst_rate TYPE decfloat34 VALUE 0,
          lv_igst_rate TYPE decfloat34 VALUE 0,
          lv_tcsamnt   TYPE i_billingdocumentitem-netamount,
          lv_tcsrate   TYPE i_billingdocumentitem-netamount.


    LOOP AT lt_final INTO DATA(ls_item).

      DATA : lv_rateeee TYPE string,
             lv_grgname TYPE string.

      CLEAR gs_final.

      lv_grgname = |{ 'Freight &' }\n{ 'Forwarding' }|.

      "Item data
      gs_final-billingdocumentitem = ls_item-billingdocumentitem.
      gs_final-description         = ls_item-billingdocumentitemtext.
      gs_final-quantity            = ls_item-billingquantity.
      gs_final-uom                 = ls_item-billingquantityunit.
      gs_final-rate                = ls_item-netamount.




      "GST data (document-level)

      READ TABLE lt_prcg INTO DATA(ls_cgst) WITH KEY conditiontype = 'JOCG'
                                                       billingdocumentitem = ls_item-billingdocumentitem.
      IF sy-subrc = 0.
*  lv_cgst_rate = ls_cgst-conditionratevalue.
        gs_final-cgst_rate  = ls_cgst-conditionratevalue.
        gs_final-perc = |{ gs_final-cgst_rate   }{ ls_cgst-conditionrateratiounit }|.
        gs_final-cgst_amt = ls_cgst-conditionamount.


      ENDIF.

      READ TABLE lt_prcg INTO DATA(ls_sgst) WITH KEY conditiontype = 'JOSG'
       billingdocumentitem = ls_item-billingdocumentitem..
      IF sy-subrc = 0.
*  lv_sgst_rate = ls_sgst-conditionratevalue.
        gs_final-sgst_rate  = ls_sgst-conditionratevalue.
        gs_final-sgst_amt = ls_cgst-conditionamount.
        gs_final-pers = |{ gs_final-sgst_rate   }{ ls_cgst-conditionrateratiounit }|.
      ENDIF.

      READ TABLE lt_prcg INTO DATA(ls_igst) WITH KEY conditiontype = 'JOIG'
       billingdocumentitem = ls_item-billingdocumentitem..
      IF sy-subrc = 0.
*  lv_igst_rate = ls_igst-conditionratevalue.

        gs_final-igst_rate =  ls_igst-conditionratevalue .
        gs_final-igst_amt = ls_igst-conditionamount.
        gs_final-peri = |{ gs_final-igst_rate   }{ ls_igst-conditionrateratiounit }|.

      ENDIF.

      READ TABLE lt_prcg INTO DATA(ls_prcg4) WITH KEY conditiontype = 'ZKF0'
       billingdocumentitem = ls_item-billingdocumentitem..
      IF sy-subrc = 0.
        gs_final-freight = ls_prcg4-conditionrateamount.
        gs_final-rate       = ls_prcg4-conditionrateamount.
        lv_grgname = |{ 'Freight &' }\n{ 'Forwarding' }|.
*          lv_grgname = |{ 'Freight&Forwarding' }|.
      ENDIF.

*      READ TABLE lt_prcg INTO DATA(ls_prcg5) WITH KEY conditiontype = 'ZFRB'
*       billingdocumentitem = ls_item-billingdocumentitem..
*      IF sy-subrc = 0.
*        gs_final-freight = ls_prcg5-conditionrateamount.
*        gs_final-rate       = ls_prcg5-conditionrateamount.
*        lv_grgname = |{ 'Freight &' }\n{ 'Forwarding' }|.
*      ENDIF.

      READ TABLE lt_prcg INTO DATA(ls_prcg6) WITH KEY conditiontype = 'Z004'
       billingdocumentitem = ls_item-billingdocumentitem..
      IF sy-subrc = 0.
        gs_final-freight = ls_prcg6-conditionrateamount.
*        gs_final-rate       = ls_prcg5-conditionrateamount.
        lv_grgname = 'Discount'.
      ENDIF.

      READ TABLE lt_prcg INTO DATA(ls_prcg7) WITH KEY conditiontype = 'ZB00'
       billingdocumentitem = ls_item-billingdocumentitem. .
      IF sy-subrc = 0.
        gs_final-rate       = ls_prcg7-conditionrateamount.
        gs_final-total                = ls_prcg7-conditionamount.
      ENDIF.


      READ TABLE lt_prcg INTO DATA(ls_prcg8) WITH KEY conditiontype = 'ZPRO'
   billingdocumentitem = ls_item-billingdocumentitem. .
      IF sy-subrc = 0.
        gs_final-rate       = ls_prcg8-conditionrateamount.
        gs_final-total                = ls_prcg8-conditionamount.
      ENDIF.


      READ TABLE lt_prcg INTO DATA(ls_tcs) WITH KEY conditiontype = 'JTC2'
       billingdocumentitem = ls_item-billingdocumentitem..
      IF sy-subrc = 0.
        gs_final-tcsamnt = ls_tcs-conditionamount.
        gs_final-tcsrate = ls_tcs-conditionrateratio.
      ENDIF.

      READ TABLE lt_hsn INTO DATA(ls_hsn) WITH KEY
      product = ls_item-product
      plant = ls_item-plant.

      IF sy-subrc = 0.
        gs_final-hsn = ls_hsn-consumptiontaxctrlcode.

      ENDIF.

      "---------------- Taxable Amount ----------------
      gs_final-taxable_amt += gs_final-total + gs_final-freight.

*      gv_taxable_total += gs_final-taxable_amt.
      gv_cgst_total    += gs_final-cgst_amt.
      gv_sgst_total    += gs_final-sgst_amt.
      gv_igst_total    += gs_final-igst_amt.


      APPEND gs_final TO gt_final.

    ENDLOOP.





    DATA : lv_supplier TYPE i_supplier-supplier,
           lv_wa       TYPE i_businesspartnerbank-businesspartner.
    "BANK DETAILS

    SELECT SINGLE
    salesorganization
    FROM i_billingdocument
    WHERE billingdocument = @io_billingdocument
    INTO @lv_wa.


*    READ TABLE lt_billitem INTO DATA(ls_so_item)  INDEX 1.

    IF sy-subrc = 0.

      SELECT SINGLE plantsupplier
        FROM i_plant
        WITH PRIVILEGED ACCESS
        WHERE plant = @lv_wa
        INTO @lv_supplier.




      DATA(lv_salll) = |{ lv_wa ALPHA = IN }|.

    ENDIF.

    DATA:
      lv_bankaccount    TYPE i_businesspartnerbank-bankaccount,
      lv_bank           TYPE i_businesspartnerbank-banknumber,
      lv_bankcountrykey TYPE i_businesspartnerbank-bankcountrykey.

    SELECT SINGLE
           bankaccount,
           banknumber,
           bankcountrykey
      FROM i_businesspartnerbank
      WITH PRIVILEGED ACCESS
      WHERE businesspartner = @lv_salll
      INTO ( @lv_bankaccount,
             @lv_bank,
             @lv_bankcountrykey ).




    DATA:
      lv_bankname        TYPE i_bank_2-bankname,
      lv_bankacc         TYPE i_bank_2-bank,
      lv_swift           TYPE i_bank_2-swiftcode,
      lv_branch          TYPE i_bank_2-bankbranch,
      lv_city            TYPE string,
      lv_bankstreet      TYPE string,
      lv_bankregion      TYPE i_bank_2-region,
      lv_bankcountry     TYPE i_bank_2-bankcountry,
      lv_bank_address    TYPE string,
      lv_bnk_addr_id     TYPE i_bank_2-addressid,
      lv_ifsc            TYPE i_address_2-streetsuffixname1,
      iv_bankinternal_id TYPE i_bank_2-bankinternalid.

    IF lv_bank IS NOT INITIAL.

      SELECT SINGLE
             bankname,
             bank,
             swiftcode,
             bankbranch,
             shortstreetname,
             shortcityname,
             region,
             bankcountry,
             addressid,
             bankinternalid
        FROM i_bank_2
        WITH PRIVILEGED ACCESS
        WHERE bankinternalid   = @lv_bank
          AND bankcountry = @lv_bankcountrykey
          AND bank = @lv_bankaccount
        INTO ( @lv_bankname,
               @lv_bankacc,
               @lv_swift,
               @lv_branch,
               @lv_bankstreet,
               @lv_city,
               @lv_bankregion,
               @lv_bankcountry,
               @lv_bnk_addr_id,
               @iv_bankinternal_id ).
    ENDIF.

    SELECT SINGLE * FROM                      "#EC CI_ALL_FIELDS_NEEDED
    zi_billing_inv
    WHERE billingdocument = @io_billingdocument
    INTO @DATA(lv_einv).

    SELECT SINGLE * FROM                      "#EC CI_ALL_FIELDS_NEEDED
    zi_billing_ewb
    WHERE billingdocument = @io_billingdocument
    INTO @DATA(lv_ewayno).



    DATA lv_waybillno TYPE string.

    lv_waybillno = COND #(
      WHEN lv_ewayno-ebillno IS INITIAL OR lv_ewayno-ebillno = '0'
      THEN ''
      ELSE lv_ewayno-ebillno
    ).


    DATA(lv_ack) = |{ lv_einv-ackno } / { lv_einv-ackdate }|.
    DATA(lv_einvno) = lv_einv-irn.

    DATA: irn    TYPE zei_invrefnum-irn,
          qr     TYPE zei_invrefnum-signed_qrcode,
          ack_no TYPE zei_invrefnum-ack_no,
          ack_dt TYPE zei_invrefnum-ack_date.

    SELECT SINGLE bukrs,
               docno,
               doc_year,
               doc_type,
               odn,
               irn,
               ack_date,
               ack_no,
               version,
               signed_inv,
               signed_qrcode
        FROM zei_invrefnum
       WHERE docno = @wa_billdoc-billingdocument
       INTO @DATA(wa_irn).

    irn = wa_irn-irn.
    qr  = wa_irn-signed_qrcode.
    ack_no  = wa_irn-ack_no.
    ack_dt = wa_irn-ack_date.

    SELECT SINGLE
    plant,
    salesorganization
    FROM i_billingdocumentitem
    WHERE billingdocument = @io_billingdocument
    INTO @DATA(lv_example).

    SELECT SINGLE *                           "#EC CI_ALL_FIELDS_NEEDED
    FROM i_billingdocument
    WHERE billingdocument = @io_billingdocument
    INTO @DATA(lv_lrvhedet).

    lv_placeof = |{ placeofsupply-region } , { lv_gstinb+0(2)  }|.

    DATA(lv_header) =
    |<form1>| &&
    |  <table>| &&
    |    <Table2>| &&
    |      <HeaderRow>| &&
    | <frg>{ me->escape_xml( lv_grgname ) }</frg> | &&
    | </HeaderRow>| &&
    |      <Row1/>| .


    DATA: lv_table TYPE string,
          lv_row   TYPE string,
          lv_sr_no TYPE i VALUE 0.
*      lv_totaltax  type   i_billingdocumentitem-netamount.

    LOOP AT gt_final INTO gs_final.

      lv_sr_no += 1.

      CLEAR lv_table.

      lv_row &&=

      |      <Row2>| &&
      |        <sno>{ lv_sr_no }</sno>| &&
      |        <desc>{ gs_final-description }</desc>| &&
      |        <hsn>{ gs_final-hsn }</hsn>| &&
      |        <qty>{  gs_final-quantity  }</qty>| &&
      |        <uom>{  gs_final-uom  }</uom>| &&
      |        <ratre>{ gs_final-rate }</ratre>| &&
      |        <total>{ gs_final-total    }</total>| &&
      |         <fregt>{  gs_final-freight }</fregt>| &&
      |        <taxable>{  gs_final-taxable_amt  }</taxable>| &&
      |        <chstrate>{ gs_final-perc }</chstrate>| &&
      |        <cgstamt>{ gs_final-cgst_amt }</cgstamt>| &&
      |        <sgstrate>{  gs_final-pers  } </sgstrate>| &&
      |        <sgstamt>{ gs_final-sgst_amt }</sgstamt>| &&
      |        <igstrate>{ gs_final-peri } </igstrate>| &&
      |        <igstamt>{ gs_final-igst_amt }</igstamt>| &&
      |      </Row2>| .


      lv_table = lv_table && lv_row.

    ENDLOOP.




    lv_table  = lv_table &&
    |      <FooterRow>| &&
    |        <Cell8sssss>{ lv_taxabletotal }</Cell8sssss>| &&
    |        <cgsttotal>{ gv_cgst_total }</cgsttotal>| &&
    |        <sgstto>{ gv_sgst_total }</sgstto>| &&
    |        <igsttop>{ gv_igst_total }</igsttop>| &&
    |      </FooterRow>| &&
    |    </Table2>| &&
    |   <totatax>{ lv_totaltax }</totatax>|  &&
    | <tcsamnt>{ lv_tcsamnt }</tcsamnt> | &&
    |  <tcsrate>{ lv_tcsrate }</tcsrate> | .

    DATA(lv_footer) =
    |  </table>| &&
    |  <Subform2>| &&
    |    <totatax>{ lv_totaltax }</totatax>| &&
    |  </Subform2>| &&
    |  <packingdetails>{ lv_pk }</packingdetails>| &&
    |  <kgs></kgs>| &&
    |  <invinwords>{ lv_inv_words }</invinwords>| &&
    |  <invoicevalue>{ lv_invalue }</invoicevalue>| &&
    |  <Subform3/>| &&
    |  <addinfo>{ me->escape_xml( lv_addinfo ) }</addinfo>| &&
    |  <ASNNO>{ lv_asn }</ASNNO>| &&
    |  <Eway>{ lv_waybillno }</Eway>| &&
    |  <header>{ lv_comp }</header>| &&
    |  <addr>{ lv_hdaddr }</addr>| &&
    |  <amail>{ lv_email }</amail>| &&
    |  <web>{ website }</web>| &&
    |  <regoff>{ lv_regoff }</regoff>| &&
    |  <gstinno>{ lv_gstino }</gstinno>| &&
    |  <invdate>{ lv_date }</invdate>| &&
    |  <RNO>{ lv_lrvhedet-yy1_lrno_bdh }</RNO>| &&
    |  <VEHNO>{ lv_lrvhedet-yy1_vehicleno_bdh }</VEHNO>| &&
    |  <DESPThr>{ lv_distr }</DESPThr>| &&
    |  <BUPHNO>{ lv_po }</BUPHNO>| &&
    |  <BUYPODT>{ lv_po_dt }</BUYPODT>| &&
    |  <TFPAY>{ lv_terofpay }</TFPAY>| &&
    |  <addrbill>{ lv_addressbill }</addrbill>| &&
    |  <addrship>{ lv_addressship }</addrship>| &&
    |  <gstinbship>{ lv_gstins }</gstinbship>| &&
    |  <statecodeship>{ lv_statecode_ship  }</statecodeship>| &&
    |  <statecodebill>{ lv_statecode_bill  }</statecodebill>| &&
    |  <msme>{ lv_udyms }</msme>| &&
    |  <nameofbank>{ lv_bankname }</nameofbank>| &&
    |  <accno>{ lv_bankacc }</accno>| &&
    |  <bankbrcn>{ lv_branch }</bankbrcn>| &&
    |  <ifsc>{ iv_bankinternal_id }</ifsc>| &&
    |  <E-invoiceNo>{ lv_einvno }</E-invoiceNo>| &&
    |  <acknno>{ lv_ack }</acknno>| &&
    |  <placeofsupply>{ lv_region_full }</placeofsupply>| &&
    |  <invno>{ lv_invno }</invno>| &&
    |  <gstinbill>{ lv_gstinb  }</gstinbill>| &&
    |  <phno>{ lv_telph }</phno>| &&
    |  <cin>{ lv_cin }</cin>| &&
    |   <udyaad>{ lv_udym }</udyaad> | &&
    | <QRCodeBarcode1>{ qr  }</QRCodeBarcode1>| &&
    |<placeosupply>{ lv_placeof }</placeosupply>| &&
    |   <orgfor>{ io_text  }</orgfor> | &&
    |</form1>| .


*rv_xml = lv_header.
    rv_xml = |{ lv_header } { lv_table }{ lv_footer }|.


*    DATA(lv_header) =
*    |<form1>| &&
*    |<a>| &&
*    |<table>| &&
*    |<Table2>| &&
*    |<HeaderRow>| &&
*    |<frg>{ me->escape_xml( lv_grgname ) }</frg>| &&
*    |</HeaderRow>| &&
*    |<Row1/>| .
*
*    DATA: lv_table TYPE string,
*          lv_row   TYPE string,
*          lv_sr_no TYPE i VALUE 0.
*
*    LOOP AT gt_final INTO gs_final.
*      lv_sr_no += 1.
*      CLEAR lv_table.
*      lv_row &&=
*|<Row2>| &&
*|<sno>{ lv_sr_no }</sno>| &&
*|<desc>{ gs_final-description }</desc>| &&
*|<hsn>{ gs_final-hsn }</hsn>| &&
*|<qty>{ gs_final-quantity }</qty>| &&
*|<uom>{ gs_final-uom }</uom>| &&
*|<ratre>{ gs_final-rate }</ratre>| &&
*|<total>{ gs_final-total }</total>| &&
*|<fregt>{ gs_final-freight }</fregt>| &&
*|<taxable>{ gs_final-taxable_amt }</taxable>| &&
*|<chstrate>{ gs_final-perc }</chstrate>| &&
*|<cgstamt>{ gs_final-cgst_amt }</cgstamt>| &&
*|<sgstrate>{ gs_final-pers }</sgstrate>| &&
*|<sgstamt>{ gs_final-sgst_amt }</sgstamt>| &&
*|<igstrate>{ gs_final-peri }</igstrate>| &&
*|<igstamt>{ gs_final-igst_amt }</igstamt>| &&
*|</Row2>| .
*      lv_table = lv_table && lv_row.
*    ENDLOOP.
*
*    lv_table = lv_table &&
*|<FooterRow>| &&
*|<Cell8sssss>{ lv_taxabletotal }</Cell8sssss>| &&
*|<cgsttotal>{ gv_cgst_total }</cgsttotal>| &&
*|<sgstto>{ gv_sgst_total }</sgstto>| &&
*|<igsttop>{ gv_igst_total }</igsttop>| &&
*|</FooterRow>| &&
*|</Table2>| &&
*|<totatax>{ lv_totaltax }</totatax>| &&
*|<tcsamnt>{ lv_tcsamnt }</tcsamnt>| &&
*|<tcsrate>{ lv_tcsrate }</tcsrate>| .
*
*    DATA(lv_footer) =
*|</table>| &&
*|<packingdetails>{ me->escape_xml( lv_pk ) }</packingdetails>| &&
*|<kgs></kgs>| &&
*|<invinwords>{ lv_inv_words }</invinwords>| &&
*|<invoicevalue>{ lv_invalue }</invoicevalue>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<addinfo>{ me->escape_xml( lv_addinfo ) }</addinfo>| &&
*|<Eway>{ lv_waybillno }</Eway>| &&
*|<ASNNO>{ lv_asn }</ASNNO>| &&
*|<orgfor>{ io_text }</orgfor>| &&
*|</a>| .
*
*    " ============================================================
*    " COPY 2 - Duplicate for Transporter
*    " ============================================================
*
*    DATA(lv_header_b) =
*|<b>| &&
*|<table>| &&
*|<Table2>| &&
*|<HeaderRow>| &&
*|<frg>{ me->escape_xml( lv_grgname ) }</frg>| &&
*|</HeaderRow>| &&
*|<Row1/>| .
*
*    DATA: lv_table_b TYPE string,
*          lv_row_b   TYPE string,
*          lv_sr_no_b TYPE i VALUE 0.
*
*    LOOP AT gt_final INTO gs_final.
*      lv_sr_no_b += 1.
*      CLEAR lv_table_b.
*      lv_row_b &&=
*|<Row2>| &&
*|<sno>{ lv_sr_no_b }</sno>| &&
*|<desc>{ gs_final-description }</desc>| &&
*|<hsn>{ gs_final-hsn }</hsn>| &&
*|<qty>{ gs_final-quantity }</qty>| &&
*|<uom>{ gs_final-uom }</uom>| &&
*|<ratre>{ gs_final-rate }</ratre>| &&
*|<total>{ gs_final-total }</total>| &&
*|<fregt>{ gs_final-freight }</fregt>| &&
*|<taxable>{ gs_final-taxable_amt }</taxable>| &&
*|<chstrate>{ gs_final-perc }</chstrate>| &&
*|<cgstamt>{ gs_final-cgst_amt }</cgstamt>| &&
*|<sgstrate>{ gs_final-pers }</sgstrate>| &&
*|<sgstamt>{ gs_final-sgst_amt }</sgstamt>| &&
*|<igstrate>{ gs_final-peri }</igstrate>| &&
*|<igstamt>{ gs_final-igst_amt }</igstamt>| &&
*|</Row2>| .
*      lv_table_b = lv_table_b && lv_row_b.
*    ENDLOOP.
*
*    lv_table_b = lv_table_b &&
*|<FooterRow>| &&
*|<Cell8sssss>{ lv_taxabletotal }</Cell8sssss>| &&
*|<cgsttotal>{ gv_cgst_total }</cgsttotal>| &&
*|<sgstto>{ gv_sgst_total }</sgstto>| &&
*|<igsttop>{ gv_igst_total }</igsttop>| &&
*|</FooterRow>| &&
*|</Table2>| &&
*|<totatax>{ lv_totaltax }</totatax>| &&
*|<tcsamnt>{ lv_tcsamnt }</tcsamnt>| &&
*|<tcsrate>{ lv_tcsrate }</tcsrate>| .
*
*    DATA(lv_footer_b) =
*|</table>| &&
*|<packingdetails>{ me->escape_xml( lv_pk ) }</packingdetails>| &&
*|<kgs></kgs>| &&
*|<invinwords>{ lv_inv_words }</invinwords>| &&
*|<invoicevalue>{ lv_invalue }</invoicevalue>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<addinfo>{ me->escape_xml( lv_addinfo ) }</addinfo>| &&
*|<Eway>{ lv_waybillno }</Eway>| &&
*|<ASNNO>{ lv_asn }</ASNNO>| &&
*|<orgfor>{ io_text }</orgfor>| &&
*|</b>| .
*
*    " ============================================================
*    " COPY 3 - Triplicate for Assessee
*    " ============================================================
*
*    DATA(lv_header_x) =
*|<x>| &&
*|<table>| &&
*|<Table2>| &&
*|<HeaderRow>| &&
*|<frg>{ me->escape_xml( lv_grgname ) }</frg>| &&
*|</HeaderRow>| &&
*|<Row1/>| .
*
*    DATA: lv_table_x TYPE string,
*          lv_row_x   TYPE string,
*          lv_sr_no_x TYPE i VALUE 0.
*
*    LOOP AT gt_final INTO gs_final.
*      lv_sr_no_x += 1.
*      CLEAR lv_table_x.
*      lv_row_x &&=
*|<Row2>| &&
*|<sno>{ lv_sr_no_x }</sno>| &&
*|<desc>{ gs_final-description }</desc>| &&
*|<hsn>{ gs_final-hsn }</hsn>| &&
*|<qty>{ gs_final-quantity }</qty>| &&
*|<uom>{ gs_final-uom }</uom>| &&
*|<ratre>{ gs_final-rate }</ratre>| &&
*|<total>{ gs_final-total }</total>| &&
*|<fregt>{ gs_final-freight }</fregt>| &&
*|<taxable>{ gs_final-taxable_amt }</taxable>| &&
*|<chstrate>{ gs_final-perc }</chstrate>| &&
*|<cgstamt>{ gs_final-cgst_amt }</cgstamt>| &&
*|<sgstrate>{ gs_final-pers }</sgstrate>| &&
*|<sgstamt>{ gs_final-sgst_amt }</sgstamt>| &&
*|<igstrate>{ gs_final-peri }</igstrate>| &&
*|<igstamt>{ gs_final-igst_amt }</igstamt>| &&
*|</Row2>| .
*      lv_table_x = lv_table_x && lv_row_x.
*    ENDLOOP.
*
*    lv_table_x = lv_table_x &&
*|<FooterRow>| &&
*|<Cell8sssss>{ lv_taxabletotal }</Cell8sssss>| &&
*|<cgsttotal>{ gv_cgst_total }</cgsttotal>| &&
*|<sgstto>{ gv_sgst_total }</sgstto>| &&
*|<igsttop>{ gv_igst_total }</igsttop>| &&
*|</FooterRow>| &&
*|</Table2>| &&
*|<totatax>{ lv_totaltax }</totatax>| &&
*|<tcsamnt>{ lv_tcsamnt }</tcsamnt>| &&
*|<tcsrate>{ lv_tcsrate }</tcsrate>| .
*
*    DATA(lv_footer_x) =
*|</table>| &&
*|<packingdetails>{ me->escape_xml( lv_pk ) }</packingdetails>| &&
*|<kgs></kgs>| &&
*|<invinwords>{ lv_inv_words }</invinwords>| &&
*|<invoicevalue>{ lv_invalue }</invoicevalue>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<addinfo>{ me->escape_xml( lv_addinfo ) }</addinfo>| &&
*|<Eway>{ lv_waybillno }</Eway>| &&
*|<ASNNO>{ lv_asn }</ASNNO>| &&
*|<orgfor>{ io_text }</orgfor>| &&
*|</x>| .
*
*    " ============================================================
*    " COPY 4 - Extra Copy
*    " ============================================================
*
*    DATA(lv_header_d) =
*|<d>| &&
*|<table>| &&
*|<Table2>| &&
*|<HeaderRow>| &&
*|<frg>{ me->escape_xml( lv_grgname ) }</frg>| &&
*|</HeaderRow>| &&
*|<Row1/>| .
*
*    DATA: lv_table_d TYPE string,
*          lv_row_d   TYPE string,
*          lv_sr_no_d TYPE i VALUE 0.
*
*    LOOP AT gt_final INTO gs_final.
*      lv_sr_no_d += 1.
*      CLEAR lv_table_d.
*      lv_row_d &&=
*|<Row2>| &&
*|<sno>{ lv_sr_no_d }</sno>| &&
*|<desc>{ gs_final-description }</desc>| &&
*|<hsn>{ gs_final-hsn }</hsn>| &&
*|<qty>{ gs_final-quantity }</qty>| &&
*|<uom>{ gs_final-uom }</uom>| &&
*|<ratre>{ gs_final-rate }</ratre>| &&
*|<total>{ gs_final-total }</total>| &&
*|<fregt>{ gs_final-freight }</fregt>| &&
*|<taxable>{ gs_final-taxable_amt }</taxable>| &&
*|<chstrate>{ gs_final-perc }</chstrate>| &&
*|<cgstamt>{ gs_final-cgst_amt }</cgstamt>| &&
*|<sgstrate>{ gs_final-pers }</sgstrate>| &&
*|<sgstamt>{ gs_final-sgst_amt }</sgstamt>| &&
*|<igstrate>{ gs_final-peri }</igstrate>| &&
*|<igstamt>{ gs_final-igst_amt }</igstamt>| &&
*|</Row2>| .
*      lv_table_d = lv_table_d && lv_row_d.
*    ENDLOOP.
*
*    lv_table_d = lv_table_d &&
*|<FooterRow>| &&
*|<Cell8sssss>{ lv_taxabletotal }</Cell8sssss>| &&
*|<cgsttotal>{ gv_cgst_total }</cgsttotal>| &&
*|<sgstto>{ gv_sgst_total }</sgstto>| &&
*|<igsttop>{ gv_igst_total }</igsttop>| &&
*|</FooterRow>| &&
*|</Table2>| &&
*|<totatax>{ lv_totaltax }</totatax>| &&
*|<tcsamnt>{ lv_tcsamnt }</tcsamnt>| &&
*|<tcsrate>{ lv_tcsrate }</tcsrate>| .
*
*    DATA(lv_footer_d) =
*|</table>| &&
*|<packingdetails>{ me->escape_xml( lv_pk ) }</packingdetails>| &&
*|<kgs></kgs>| &&
*|<invinwords>{ lv_inv_words }</invinwords>| &&
*|<invoicevalue>{ lv_invalue }</invoicevalue>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<Subform3/>| &&
*|<addinfo>{ me->escape_xml( lv_addinfo ) }</addinfo>| &&
*|<Eway>{ lv_waybillno }</Eway>| &&
*|<ASNNO>{ lv_asn }</ASNNO>| &&
*|<orgfor>{ io_text }</orgfor>| &&
*|</d>| .
*
*    " ============================================================
*    " FINAL ASSEMBLE
*    " ============================================================
*
*    DATA(lv_common) =
*|<header>{ lv_comp }</header>| &&
*|<addr>{ lv_hdaddr }</addr>| &&
*|<amail>{ lv_email }</amail>| &&
*|<web>{ website }</web>| &&
*|<regoff>{ lv_regoff }</regoff>| &&
*|<gstinno>{ lv_gstino }</gstinno>| &&
*|<invdate>{ lv_date }</invdate>| &&
*|<RNO>{ lv_lrvhedet-yy1_lrno_bdh }</RNO>| &&
*|<VEHNO>{ lv_lrvhedet-yy1_vehicleno_bdh }</VEHNO>| &&
*|<DESPThr>{ lv_distr }</DESPThr>| &&
*|<BUPHNO>{ lv_po }</BUPHNO>| &&
*|<BUYPODT>{ lv_po_dt }</BUYPODT>| &&
*|<TFPAY>{ lv_terofpay }</TFPAY>| &&
*|<addrbill>{ lv_addressbill }</addrbill>| &&
*|<addrship>{ lv_addressship }</addrship>| &&
*|<gstinbship>{ lv_gstins }</gstinbship>| &&
*|<statecodeship>{ lv_statecode_ship }</statecodeship>| &&
*|<statecodebill>{ lv_statecode_bill }</statecodebill>| &&
*|<msme>{ lv_udyms }</msme>| &&
*|<nameofbank>{ lv_bankname }</nameofbank>| &&
*|<accno>{ lv_bankacc }</accno>| &&
*|<bankbrcn>{ lv_branch }</bankbrcn>| &&
*|<ifsc>{ iv_bankinternal_id }</ifsc>| &&
*|<E-invoiceNo>{ lv_einvno }</E-invoiceNo>| &&
*|<acknno>{ lv_ack }</acknno>| &&
*|<placeofsupply>{ lv_region_full }</placeofsupply>| &&
*|<invno>{ lv_invno }</invno>| &&
*|<gstinbill>{ lv_gstinb }</gstinbill>| &&
*|<phno>{ lv_telph }</phno>| &&
*|<cin>{ lv_cin }</cin>| &&
*|<udyaad>{ lv_udym }</udyaad>| &&
*|<QRCodeBarcode1>{ qr }</QRCodeBarcode1>| &&
*|<placeosupply>{ lv_placeof }</placeosupply>| &&
*|</form1>| .
*
*    rv_xml = lv_header  && lv_table  && lv_footer  &&
*             lv_header_b && lv_table_b && lv_footer_b &&
*             lv_header_x && lv_table_x && lv_footer_x &&
*             lv_header_d && lv_table_d && lv_footer_d &&
*             lv_common.





  ENDMETHOD.


  METHOD get_billing_text.

    DATA lt_text TYPE STANDARD TABLE OF i_billingdocumenttexttp.

    " ================= HEADER TEXT =================


    READ ENTITIES OF i_billingdocumenttp
        ENTITY billingdocument
        BY \_text
       ALL FIELDS
        WITH VALUE #( ( billingdocument = iv_billingdocument ) )
        RESULT DATA(lt_text_result)
        FAILED FINAL(ls_failed_read)
        REPORTED FINAL(ls_reported_read).

    CHECK ls_failed_read IS INITIAL.
    DATA lt_filtered_text LIKE lt_text_result.
    lt_filtered_text = VALUE #(
      FOR ls_text IN lt_text_result
      WHERE (  language   = iv_language
          AND longtextid = iv_longtextid )
      ( ls_text )
    ).

    CHECK lt_filtered_text IS NOT INITIAL.
    DATA(lv_longtext) = lt_filtered_text[ 1 ]-longtext.

    IF lt_filtered_text IS NOT INITIAL.
      rv_text = lt_filtered_text[ 1 ]-longtext.
    ENDIF.


  ENDMETHOD.


  METHOD get_state_code.

    CASE iv_region.
      WHEN 'JK'. rv_statecode = '01'.
      WHEN 'HP'. rv_statecode = '02'.
      WHEN 'PB'. rv_statecode = '03'.
      WHEN 'CH'. rv_statecode = '04'.
      WHEN 'UK'. rv_statecode = '05'.
      WHEN 'HR'. rv_statecode = '06'.
      WHEN 'DL'. rv_statecode = '07'.
      WHEN 'RJ'. rv_statecode = '08'.
      WHEN 'UP'. rv_statecode = '09'.
      WHEN 'BR'. rv_statecode = '10'.
      WHEN 'SK'. rv_statecode = '11'.
      WHEN 'AR'. rv_statecode = '12'.
      WHEN 'NL'. rv_statecode = '13'.
      WHEN 'MN'. rv_statecode = '14'.
      WHEN 'MZ'. rv_statecode = '15'.
      WHEN 'TR'. rv_statecode = '16'.
      WHEN 'ML'. rv_statecode = '17'.
      WHEN 'AS'. rv_statecode = '18'.
      WHEN 'WB'. rv_statecode = '19'.
      WHEN 'JH'. rv_statecode = '20'.
      WHEN 'OD'. rv_statecode = '21'.
      WHEN 'CG'. rv_statecode = '22'.
      WHEN 'MP'. rv_statecode = '23'.
      WHEN 'GJ'. rv_statecode = '24'.
      WHEN 'DD'. rv_statecode = '25'.
      WHEN 'DN'. rv_statecode = '26'.
      WHEN 'MH'. rv_statecode = '27'.
      WHEN 'AP'. rv_statecode = '28'.
      WHEN 'KA'. rv_statecode = '29'.
      WHEN 'GA'. rv_statecode = '30'.
      WHEN 'LD'. rv_statecode = '31'.
      WHEN 'KL'. rv_statecode = '32'.
      WHEN 'TN'. rv_statecode = '33'.
      WHEN 'PY'. rv_statecode = '34'.
      WHEN 'AN'. rv_statecode = '35'.
      WHEN 'TS'. rv_statecode = '36'.
      WHEN 'AD'. rv_statecode = '37'.
      WHEN 'LA'. rv_statecode = '38'.
      WHEN 'OT'. rv_statecode = '97'.
      WHEN OTHERS.
        rv_statecode = ''.
    ENDCASE.

  ENDMETHOD.


  METHOD num2words.

    TYPES: BEGIN OF ty_map,
             num  TYPE i,
             word TYPE string,
           END OF ty_map.

    DATA: lt_map TYPE STANDARD TABLE OF ty_map,
          ls_map TYPE ty_map.

    DATA: lv_int  TYPE i,
          lv_dec  TYPE i,
          lv_inp1 TYPE string,
          lv_inp2 TYPE string.

    DATA: lv_result TYPE string,
          lv_decres TYPE string.

    IF iv_num IS INITIAL.
      RETURN.
    ENDIF.

    lt_map = VALUE #(
      ( num = 0  word = 'Zero' )
      ( num = 1  word = 'One' )
      ( num = 2  word = 'Two' )
      ( num = 3  word = 'Three' )
      ( num = 4  word = 'Four' )
      ( num = 5  word = 'Five' )
      ( num = 6  word = 'Six' )
      ( num = 7  word = 'Seven' )
      ( num = 8  word = 'Eight' )
      ( num = 9  word = 'Nine' )
      ( num = 10 word = 'Ten' )
      ( num = 11 word = 'Eleven' )
      ( num = 12 word = 'Twelve' )
      ( num = 13 word = 'Thirteen' )
      ( num = 14 word = 'Fourteen' )
      ( num = 15 word = 'Fifteen' )
      ( num = 16 word = 'Sixteen' )
      ( num = 17 word = 'Seventeen' )
      ( num = 18 word = 'Eighteen' )
      ( num = 19 word = 'Nineteen' )
      ( num = 20 word = 'Twenty' )
      ( num = 30 word = 'Thirty' )
      ( num = 40 word = 'Forty' )
      ( num = 50 word = 'Fifty' )
      ( num = 60 word = 'Sixty' )
      ( num = 70 word = 'Seventy' )
      ( num = 80 word = 'Eighty' )
      ( num = 90 word = 'Ninety' )
    ).

    SPLIT iv_num AT '.' INTO lv_inp1 lv_inp2.
    lv_int = lv_inp1.
    IF lv_inp2 IS NOT INITIAL.
      lv_dec = lv_inp2.
    ENDIF.

    " ---- INTEGER PART ----
    IF lv_int < 20.
      READ TABLE lt_map INTO ls_map WITH KEY num = lv_int.
      lv_result = ls_map-word.

    ELSEIF lv_int < 100.
      READ TABLE lt_map INTO ls_map WITH KEY num = ( lv_int DIV 10 ) * 10.
      lv_result = ls_map-word.
      IF lv_int MOD 10 > 0.
        READ TABLE lt_map INTO ls_map WITH KEY num = lv_int MOD 10.
        lv_result = |{ lv_result } { ls_map-word }|.
      ENDIF.

    ELSEIF lv_int < 1000.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 100 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Hundred'.

      IF lv_int MOD 100 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 100 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSEIF lv_int < 100000.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 1000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Thousand'.

      IF lv_int MOD 1000 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 1000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.

    ELSE.
      lv_result =
        num2words( iv_num = |{ lv_int DIV 100000 }|
                   iv_major = iv_major
                   iv_minor = iv_minor
                   iv_top_call = abap_false )
        && ' Lakh'.

      IF lv_int MOD 100000 > 0.
        lv_result = |{ lv_result } |
          && num2words( iv_num = |{ lv_int MOD 100000 }|
                        iv_major = iv_major
                        iv_minor = iv_minor
                        iv_top_call = abap_false ).
      ENDIF.
    ENDIF.

    " ---- APPEND CURRENCY ONLY ONCE ----
    rv_words = lv_result.

    IF iv_top_call = abap_true.
      IF lv_dec > 0.
        lv_decres =
          num2words(
            iv_num      = |{ lv_dec }|
            iv_major    = iv_major
            iv_minor    = iv_minor
            iv_top_call = abap_false
          ).
        rv_words = |{ rv_words } { iv_major } and { lv_decres } { iv_minor } Only|.
      ELSE.
        rv_words = |{ rv_words } { iv_major } Only|.
      ENDIF.
    ENDIF.

    CONDENSE rv_words.
    TRANSLATE rv_words TO UPPER CASE.

  ENDMETHOD.
ENDCLASS.
