CLASS zcl_tax_invoice DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    METHODS get_pdf_64
      IMPORTING
        VALUE(io_billingdocument) TYPE i_billingdocument-billingdocument
      RETURNING
        VALUE(pdf_64) TYPE string.

  CLASS-METHODS sanitize_text
      IMPORTING iv_text        TYPE string
      RETURNING VALUE(rv_text) TYPE string.
*
**    METHODS num2words IMPORTING iv_num          TYPE string OPTIONAL
**                                lv_comp         TYPE string OPTIONAL
**                      CHANGING  iv_level        TYPE i OPTIONAL
**                      RETURNING VALUE(rv_words) TYPE string  .
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

  PRIVATE SECTION.

    METHODS build_xml_all
      IMPORTING
        VALUE(io_billingdocument) TYPE i_billingdocument-billingdocument
      RETURNING
        VALUE(rv_xml) TYPE string.

    METHODS build_xml_scrap
      IMPORTING
        VALUE(io_billingdocument) TYPE i_billingdocument-billingdocument
      RETURNING
        VALUE(rv_xml) TYPE string.

ENDCLASS.



CLASS zcl_tax_invoice IMPLEMENTATION.


METHOD get_pdf_64.

  DATA: lv_doctype  TYPE i_billingdocument-distributionchannel,
        lv_xml      TYPE string,
        lv_template TYPE string.

  "--------------------------------------------------
  " Billing document → Distribution Channel
  "--------------------------------------------------
  SELECT SINGLE distributionchannel
    FROM i_billingdocument
    WHERE billingdocument = @io_billingdocument
    INTO @lv_doctype.

  IF sy-subrc <> 0 OR lv_doctype IS INITIAL.
    RETURN.
  ENDIF.

  "--------------------------------------------------
  " Decide XML + Template
  "--------------------------------------------------
CASE lv_doctype.

  WHEN '30'.
    lv_xml      = build_xml_scrap( io_billingdocument ).
    lv_template = 'ZTAX_SCRAP/ZTAX_SCRAP'.

  WHEN OTHERS.
    lv_xml      = build_xml_all( io_billingdocument ).
    lv_template = 'ZNEW_TAX_INVOICE/ZNEW_TAX_INVOICE'.

ENDCASE.

  IF lv_xml IS INITIAL.
    RETURN.
  ENDIF.

  "--------------------------------------------------
  " Adobe PDF
  "--------------------------------------------------
  CALL METHOD zadobe_ads_class=>getpdf
    EXPORTING
      template = lv_template
      xmldata  = lv_xml
    RECEIVING
      result   = pdf_64.

ENDMETHOD.


METHOD build_xml_all.

  DATA: lv_sr_no        TYPE i VALUE 0,
          lv_des          TYPE i_salesorderitem-salesorderitemtext,
          lv_custpur      TYPE i_salesorder-customerpurchaseorderdate,
          lv_salesdate    TYPE i_salesorder-salesorderdate,
          lv_text(1000)   TYPE c,
          sperson(1000)   TYPE c,
          lv_hsn          TYPE i_productplantbasic-consumptiontaxctrlcode,
          saddress1(1000) TYPE c,
          bperson(1000)   TYPE c,
          batch           TYPE i_deliverydocumentitem-batch,
          expiry          TYPE i_deliverydocumentitem-shelflifeexpirationdate,
          baddress1(1000) TYPE c,
          lv_items        TYPE string.

    DATA: lv_sgst_item  TYPE decfloat34,
          lv_cgst_item  TYPE decfloat34,
          lv_igst_item  TYPE decfloat34,
          lv_disc_item  TYPE decfloat34,
          lv_charge_it  TYPE decfloat34,
          lv_total_char TYPE decfloat34,
          lv_total_amt  TYPE decfloat34,
          lv_gst_total  TYPE decfloat34,
          lv_amt_inword TYPE string,
          lv_taxable    TYPE decfloat34.

    DATA: lv_sgst_total   TYPE decfloat34,
          lv_cgst_total   TYPE decfloat34,
          lv_igst_total   TYPE decfloat34,
          lv_discount_tot TYPE decfloat34,
          lv_charges_tot  TYPE decfloat34.
    DATA: lv_fulldes TYPE string.
    DATA:lv_expiry TYPE string.

    "--------------------------------------------------------
    "query to fetch objects from i_billingdocumentitem
    "--------------------------------------------------------

    DATA: it_billdoc_item TYPE TABLE OF i_billingdocumentitem,
          wa_billdoc_item TYPE i_billingdocumentitem.
    SELECT *
    FROM i_billingdocumentitem
    WHERE billingdocument = @io_billingdocument
     INTO TABLE @it_billdoc_item.
    DELETE it_billdoc_item WHERE batch IS INITIAL AND distributionchannel <> '30'..

    "--------------------------------------------------------
    "query to fetch objects from i_billingdocumentitem
    "--------------------------------------------------------
    READ TABLE it_billdoc_item INTO wa_billdoc_item WITH KEY billingdocument = io_billingdocument.
    SELECT SINGLE *
      FROM i_billingdocument
      WHERE billingdocument = @io_billingdocument
       INTO  @DATA(wa_billdoc).

    SELECT SINGLE *
  FROM i_billingdocumenttp
  WHERE billingdocument = @io_billingdocument
   INTO  @DATA(wa_billdoctp).


    SELECT * FROM i_billingdocumentitemtexttp
    WHERE billingdocument = @io_billingdocument
    INTO TABLE @DATA(it_long_text).
    READ TABLE it_long_text INTO DATA(wa_long_text) WITH KEY billingdocument = io_billingdocument.
    "--------------------------------------------------------
    "query to fetch objectsi_deliveryitem
    "--------------------------------------------------------
    DATA: it_del_item TYPE TABLE OF i_deliverydocumentitem,
          wa_del_item TYPE i_deliverydocumentitem.
    SELECT * FROM i_deliverydocumentitem
    WHERE deliverydocument = @wa_billdoc_item-referencesddocument
    INTO TABLE @it_del_item.
    DELETE it_del_item WHERE batch IS INITIAL AND distributionchannel <> '30'..

    SELECT a~*,d~*
    FROM i_billingdocumentitem AS a
    LEFT OUTER JOIN i_deliverydocumentitem AS d
      ON d~deliverydocument = a~referencesddocument
    WHERE a~billingdocument = @io_billingdocument
    INTO TABLE @DATA(it_j_billdel).

*    SELECT *
*      FROM I_DeliveryDocumentItem
*      WHERE DeliveryDocument          = @wa_billdoc_item-ReferenceSDDocument
*      INTO TABLE @it_del_item.

    "--------------------------------------------------------
    "query to fetch objects from i_SalesOrder
    "--------------------------------------------------------

    SELECT SINGLE * FROM i_salesorder
      WHERE salesorder = @wa_billdoc_item-salesdocument
           INTO @DATA(wa_saleshead).

    SELECT SINGLE *
FROM i_paymenttermsconditionstext
WHERE paymentterms = @wa_saleshead-customerpaymentterms
INTO @DATA(wa_payment).
    "--------------------------------------------------------
    "query to fetch objects from i_SalesOrderitem
    "--------------------------------------------------------

    DATA: it_sales_item TYPE TABLE OF i_salesorderitem,
          wa_sales_item TYPE i_salesorderitem.
    SELECT *
    FROM i_salesorderitem
    WHERE salesorder = @wa_billdoc_item-salesdocument
     INTO TABLE @it_sales_item.
    READ TABLE it_sales_item INTO wa_sales_item WITH KEY salesorder = wa_billdoc_item-salesdocument.
    "--------------------------------------------------------
    "query to fetch objects from ship to address
    "--------------------------------------------------------

    DATA: it_vbpa TYPE TABLE OF i_salesorderpartner.
    SELECT *
             FROM i_salesorderpartner "i_salesorderitempartner "
       WHERE salesorder = @wa_billdoc_item-salesdocument
       INTO TABLE @it_vbpa.


    READ TABLE it_vbpa INTO DATA(wa_vbpa) WITH  KEY partnerfunction = 'WE'. "SHIP TO PARTY
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_vbpa-customer
        INTO @DATA(wa_kna1_s).

      SELECT SINGLE * FROM i_address_2
       WITH PRIVILEGED ACCESS
       WHERE addressid = @wa_kna1_s-addressid
       INTO @DATA(wa_address_ship).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_kna1_s-country
      AND region = @wa_kna1_s-region
      AND language = @sy-langu
     INTO @DATA(wa_region_ship).

      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_kna1_s-country
      AND language = @sy-langu
      INTO @DATA(wa_country_ship).

      IF wa_address_ship-careofname IS NOT INITIAL.
        sperson = wa_address_ship-careofname.
      ELSE.
        sperson = wa_address_ship-organizationname1.
      ENDIF.

      saddress1 = |{ wa_address_ship-streetprefixname1 } { wa_address_ship-streetname } { wa_address_ship-streetsuffixname1 } { wa_address_ship-streetsuffixname2 }  { wa_address_ship-cityname },{ wa_address_ship-postalcode }| .
      saddress1 = |{ saddress1 },{ wa_region_ship-regionname },{ wa_country_ship-countryname }| .

    ENDIF.

    "--------------------------------------------------------
    "query to fetch objects from Bill to address
    "--------------------------------------------------------

    READ TABLE it_vbpa INTO DATA(wa_vbpab) WITH  KEY partnerfunction = 'AG'. "SHIP TO PARTY
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_vbpab-customer
        INTO @DATA(wa_kna1_b).

      SELECT SINGLE * FROM i_address_2
       WITH PRIVILEGED ACCESS
       WHERE addressid = @wa_kna1_b-addressid
       INTO @DATA(wa_address_bill).

      SELECT SINGLE * FROM zc_lut_details
  WITH PRIVILEGED ACCESS
  WHERE lutno = @wa_billdoc-yy1_lutno2_bdh
  INTO @DATA(wa_lut_dlts).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_kna1_b-country
      AND region = @wa_kna1_b-region
      AND language = @sy-langu
     INTO @DATA(wa_region_bill).

      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_kna1_b-country
      AND language = @sy-langu
      INTO @DATA(wa_country_bill).

      IF wa_address_bill-careofname IS NOT INITIAL.
        bperson = wa_address_bill-careofname.
      ELSE.
        bperson = wa_address_bill-organizationname1.
      ENDIF.

      baddress1 = |{ wa_address_bill-streetprefixname1 } { wa_address_bill-streetname } { wa_address_bill-streetsuffixname1 } { wa_address_bill-streetsuffixname2 }  { wa_address_bill-cityname },{ wa_address_bill-postalcode }| .
      baddress1 = |{ baddress1 },{ wa_region_bill-regionname },{ wa_country_bill-countryname }| .

    ENDIF.
data : lv_ex_rate type decfloat34.

lv_ex_rate = wa_billdoc-accountingexchangerate.
    "--------------------------------------------------------
    "hardcoded sender address
    "--------------------------------------------------------
    DATA : sender_nm(1000)    TYPE c,
           sender_addr(1000)  TYPE c,
           sender_addr1(1000) TYPE c,
           sender_addr3(1000) TYPE c,
           email(1000)        TYPE c,
           cin(1000)          TYPE c,
           sender_gst(1000)   TYPE c,
           gstin(1000)        TYPE c,
           policyno(1000)     TYPE c,
           druglicno(1000)    TYPE c,
           iecno(1000)        TYPE c,
           sender_state(1000) TYPE c.

    sender_nm = ' KOPRAN RESEARCH LABORATORIES LIMITED - 25-26'.
    sender_addr = 'K 4 ADD. MDC VILLAGE BIRWADI'.
    sender_addr1 = 'TAL MAHAD, DIST RAIGAD PINCODE:402302'.
    sender_addr3 = 'HO. JARIHAUL HOUSE, MOSSES ROAD WORLI MUMBAI'.
    email = 'sepatmhhd@kopran.com'.
    cin = 'U24230MH1968PLC040601'.
    gstin = '27AAACK3189E1ZJ'.
    policyno = '2414 2088 5972 8701 000'.
    druglicno = 'KDD/230 KD/265'.
    iecno = '03990216035'.
    sender_state = 'Maharashtra'.



    "--------------------------------------------------------
    "query to fetch objects from zei_invrefnum
    "--------------------------------------------------------
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

    "--------------------------------------------------------
    "query to fetch objects from zew_ewaybill
    "--------------------------------------------------------
    DATA: ewaybill TYPE zew_ewaybill-ebillno.
    SELECT SINGLE *
           FROM zew_ewaybill
          WHERE bukrs EQ @wa_billdoc-companycode
           AND  docno EQ @wa_billdoc-billingdocument
           INTO @DATA(eway).

    ewaybill = eway-ebillno.

    "--------------------------------------------------------
    "query to fetch gst and rate
    "--------------------------------------------------------

*
*    DATA: pricingelemnt    TYPE TABLE OF I_SalesOrderItemPricingElement,
*          wa_pricingelemnt TYPE I_SalesOrderItemPricingElement.


*    READ TABLE pricingelemnt INTO wa_pricingelemnt with key SalesOrder = wa_billdoc_item-SalesDocument.
 DATA: it_sales_itemtp TYPE TABLE OF i_salesorderitemtp,
          wa_sales_itemtp TYPE i_salesorderitemtp.
    SELECT *
    FROM i_salesorderitemtp
    WHERE salesorder = @wa_billdoc_item-salesdocument
     INTO TABLE @it_sales_itemtp.
    READ TABLE it_sales_itemtp INTO wa_sales_itemtp WITH KEY salesorder = wa_billdoc_item-salesdocument.

    SELECT *
      FROM i_salesorderitempricingelement
      WHERE salesorder = @wa_billdoc_item-salesdocument
      INTO TABLE @DATA(it_prcd).

    DATA: lv_cgst   TYPE decfloat34,
          lv_sgst   TYPE decfloat34,
          lv_igst   TYPE decfloat34,
          lv_amount TYPE p DECIMALS 2,
          lv_rate   TYPE decfloat34.

    " Clear all totals before loop
    CLEAR: lv_cgst, lv_sgst,lv_igst, lv_rate.

    CLEAR: lv_sgst_item, lv_cgst_item, lv_igst_item,
         lv_disc_item, lv_charge_it.


    DATA: lv_z_sgst TYPE abap_bool,
          lv_z_cgst TYPE abap_bool,
          lv_z_igst TYPE abap_bool.

    CLEAR: lv_z_sgst, lv_z_cgst, lv_z_igst.

    "--------------------------------------------------
    " First pass: detect Z conditions for this item
    "--------------------------------------------------
    LOOP AT it_prcd INTO DATA(wa_prcd)
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_prcd-conditiontype.
        WHEN 'ZOSG'. lv_z_sgst = abap_true.
        WHEN 'ZOCG'. lv_z_cgst = abap_true.
        WHEN 'ZOIG'. lv_z_igst = abap_true.
      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------
    " Second pass: calculate with priority
    "--------------------------------------------------
    LOOP AT it_prcd INTO wa_prcd
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_prcd-conditiontype.

          "------------ SGST -------------
        WHEN 'ZOSG'.
          lv_sgst_item += wa_prcd-conditionamount.

        WHEN 'JOSG'.
          IF lv_z_sgst IS INITIAL.
            lv_sgst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ CGST -------------
        WHEN 'ZOCG'.
          lv_cgst_item += wa_prcd-conditionamount.

        WHEN 'JOCG'.
          IF lv_z_cgst IS INITIAL.
            lv_cgst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ IGST -------------
        WHEN 'ZOIG'.
          lv_igst_item += wa_prcd-conditionamount.

        WHEN 'JOIG'.
          IF lv_z_igst IS INITIAL.
            lv_igst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ Base Price -------
        WHEN 'ZCIF' OR 'ZPR0' OR 'ZSCP'.
          lv_rate      += wa_prcd-conditionrateamount.
          lv_charge_it += wa_prcd-conditionamount.

      ENDCASE.

    ENDLOOP.


    lv_sgst_total  += lv_sgst_item * lv_ex_rate.
    lv_cgst_total  += lv_cgst_item * lv_ex_rate.
    lv_igst_total  += lv_igst_item * lv_ex_rate.
    lv_discount_tot += lv_disc_item.
    lv_charges_tot += lv_charge_it.

*    IF lv_rate IS INITIAL.
*      lv_rate = wa_sales_item-netpriceamount.
*    ENDIF.


    DATA: lv_sgst_rate TYPE decfloat34,
          lv_cgst_rate TYPE decfloat34,
          lv_igst_rate TYPE decfloat34.

    CLEAR:  lv_sgst_rate,
       lv_cgst_rate,
       lv_igst_rate.

    DATA: lv_z_sgst_rate TYPE abap_bool,
          lv_z_cgst_rate TYPE abap_bool,
          lv_z_igst_rate TYPE abap_bool.

    CLEAR: lv_z_sgst_rate, lv_z_cgst_rate, lv_z_igst_rate.

    "--------------------------------------------------
    " First pass: detect Z-rate conditions
    "--------------------------------------------------
    LOOP AT it_prcd INTO DATA(wa_gst_rate)
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_gst_rate-conditiontype.
        WHEN 'ZOSG'. lv_z_sgst_rate = abap_true.
        WHEN 'ZOCG'. lv_z_cgst_rate = abap_true.
        WHEN 'ZOIG'. lv_z_igst_rate = abap_true.
      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------
    " Second pass: assign rate with priority
    "--------------------------------------------------

    LOOP AT it_prcd INTO wa_gst_rate
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_gst_rate-conditiontype.

          "------------ SGST RATE -------------
        WHEN 'ZOSG'.
          lv_sgst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOSG'.
          IF lv_z_sgst_rate IS INITIAL.
            lv_sgst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

          "------------ CGST RATE -------------
        WHEN 'ZOCG'.
          lv_cgst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOCG'.
          IF lv_z_cgst_rate IS INITIAL.
            lv_cgst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

          "------------ IGST RATE -------------
        WHEN 'ZOIG'.
          lv_igst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOIG'.
          IF lv_z_igst_rate IS INITIAL.
            lv_igst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------------
    " start of case for main table gst
    "--------------------------------------------------------
    DATA: lv_sgst_total1 TYPE decfloat34,
          lv_cgst_total1 TYPE decfloat34,
          lv_igst_total1 TYPE decfloat34.

    DATA: lv_sgst_item1 TYPE decfloat34,
          lv_cgst_item1 TYPE decfloat34,
          lv_igst_item1 TYPE decfloat34.


    DATA: lv_sgst_rate1 TYPE decfloat34,
          lv_cgst_rate1 TYPE decfloat34,
          lv_igst_rate1 TYPE decfloat34.
    CLEAR:  lv_sgst_rate1,
     lv_cgst_rate1,
     lv_igst_rate1.
    LOOP AT it_prcd INTO wa_gst_rate
     WHERE salesorder     = wa_sales_item-salesorder
       AND salesorderitem = wa_sales_item-salesorderitem.


      CASE wa_gst_rate-conditiontype.
          "------------ SGST RATE -------------
        WHEN 'JOSG'.
          lv_sgst_rate1 = wa_gst_rate-conditionratevalue.
          lv_sgst_item1 += wa_gst_rate-conditionamount.
          "------------ CGST RATE -------------
        WHEN 'JOCG'.
          lv_cgst_rate1 = wa_gst_rate-conditionratevalue.
          lv_cgst_item1 += wa_gst_rate-conditionamount.
          "------------ IGST RATE -------------
        WHEN 'JOIG'.
          lv_igst_rate1 = wa_gst_rate-conditionratevalue.
          lv_igst_item1 += wa_gst_rate-conditionamount.
      ENDCASE.

    ENDLOOP.
    lv_sgst_total1  += lv_sgst_item1 * lv_ex_rate.
    lv_cgst_total1  += lv_cgst_item1 * lv_ex_rate.
    lv_igst_total1  += lv_igst_item1 * lv_ex_rate.

    DATA : text_cgst(1000) TYPE c,
           text_igst(1000) TYPE c,
           text_sgst(1000) TYPE c.

    text_cgst = |CGST({ lv_sgst_rate1 }%)|.
    text_igst  = |IGST({ lv_igst_rate1 }%)|.
    text_sgst =  |SGST({ lv_sgst_rate1 }%)|.



    "--------------------------------------------------------
    " code to choose between gsts
    "--------------------------------------------------------

    DATA: lv_final_tax  TYPE decfloat34,
          lv_final_tax1 TYPE decfloat34,
          lv_text_gst   TYPE string,
          lv_text_gst1  TYPE string.

    " Final tax
    IF lv_igst_total1 IS INITIAL OR lv_igst_total1 = 0.
      IF lv_sgst_total1 IS INITIAL OR lv_sgst_total1 = 0.
        CLEAR lv_final_tax.
      ELSE.
        lv_final_tax = lv_sgst_total1.
      ENDIF.
    ELSE.
      lv_final_tax = lv_igst_total1.
    ENDIF.

    " Second tax
    IF lv_igst_total1 IS INITIAL OR lv_igst_total1 = 0.
      IF lv_cgst_total1 IS INITIAL OR lv_cgst_total1 = 0.
        CLEAR lv_final_tax1.
      ELSE.
        lv_final_tax1 = lv_cgst_total1.
      ENDIF.
    ELSE.
      CLEAR lv_final_tax1.
    ENDIF.

    " Text handling
    IF lv_igst_total IS INITIAL OR lv_igst_total = 0.
      lv_text_gst  = text_cgst.
      lv_text_gst1 = text_sgst.
    ELSE.
      CLEAR lv_text_gst.
      lv_text_gst1 = text_igst.
    ENDIF.



    "--------------------------------------------------------
    " star of  xml binding
    "--------------------------------------------------------
    DATA: lv_xml TYPE string VALUE ''.


    CLEAR lv_text.

    CASE wa_saleshead-distributionchannel.

      WHEN '10'.
        IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS UNDER BOND OR LETTER OF UNDERTAKING WITHOUT PAYMENT OF IGST'.
        ELSE.
          CLEAR lv_text.
        ENDIF.

      WHEN '20'.
        IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS UNDER BOND OR LETTER OF UNDERTAKING WITHOUT PAYMENT OF IGST'.
        ELSE.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS ON PAYMENT OF IGST'.
        ENDIF.

      WHEN '30'.
        CLEAR lv_text.

      WHEN OTHERS.
        CLEAR lv_text.

    ENDCASE.
    DATA: lv_destination TYPE string.

    CASE wa_saleshead-distributionchannel.

      WHEN '10'.

        lv_destination = wa_address_ship-cityname.
      WHEN '20'.
        lv_destination = wa_country_ship-countryname.

      WHEN '30'.
        lv_destination = wa_address_ship-cityname.

      WHEN OTHERS.
        lv_destination = wa_country_ship-countryname.

    ENDCASE.

    lv_custpur = |{ wa_saleshead-customerpurchaseorderdate+6(2) }/{ wa_saleshead-customerpurchaseorderdate+4(2) }/{ wa_saleshead-customerpurchaseorderdate+2(4) }|.
    lv_salesdate = |{ wa_saleshead-salesorderdate+6(2) }/{ wa_saleshead-salesorderdate+4(2) }/{ wa_saleshead-salesorderdate+2(4) }|.
    DATA: lnv_date TYPE string.
    lnv_date = |{ wa_billdoc-billingdocumentdate+6(2) }/{ wa_billdoc-billingdocumentdate+4(2) }/{ wa_billdoc-billingdocumentdate+2(4) }|.
*    lv_hsn = wa_productplantbasic-consumptiontaxctrlcode.


    DATA(lv_header) =
     |<form1>| &&
     |  <main_flowed_subform>| &&
     |    <irn_details>| &&
     |      <data>| &&
     |        <Main>| &&
     |          <conditional_text>{ lv_text }</conditional_text>| &&
     |          <irn>{ irn }</irn>| &&
     |          <ackno>{ ack_no }</ackno>| &&
     |          <ack_dt>{ ack_dt }</ack_dt>| &&
     |        </Main>| &&
     |      </data>| &&
     |    </irn_details>| &&
     |    <Subform5>| &&
     |      <headersubform>| &&
     |        <Subform6>| &&
     |          <sender_nm>{ sender_nm }</sender_nm>| &&
     |          <sender_addr>{ sender_addr }</sender_addr>| &&
     |          <sender_addr1>{ sender_addr1 }</sender_addr1>| &&
     |          <email>{ email }</email>| &&
     |          <CIN>{ cin }</CIN>| &&
     |          <sender_gst></sender_gst>| &&
     |          <GSTIN>{ gstin }</GSTIN>| &&
     |          <POLICYNO>{ policyno }</POLICYNO>| &&
     |          <DRUGLICNO>{ druglicno }</DRUGLICNO>| &&
     |          <IECNO>{ iecno }</IECNO>| &&
     |          <SENDER_STATE>{ sender_state }</SENDER_STATE>| &&
     |          <sender_addr3>{ sender_addr3 }</sender_addr3>| &&
     |        </Subform6>| &&
     |        <Subform8>| &&
     |          <buyer_nm>{ bperson }</buyer_nm>| &&
     |          <buyer_addr>{ baddress1 }</buyer_addr>| &&
     |          <buyer_addr1></buyer_addr1>| &&
     |        </Subform8>| &&
     |        <Subform10>| &&
     |          <termofdelivery>{ wa_saleshead-incotermsclassification } { wa_saleshead-incotermslocation1 }</termofdelivery>| &&
     |          <lut_no>{ wa_lut_dlts-lutdescripton }</lut_no>| &&
     |          <country>{ wa_country_ship-countryname }</country>| &&
     |          <l_r_no>{ wa_billdoctp-yy1_lrno_bdh }</l_r_no>| &&
     |          <buyer_ord_no>{ wa_saleshead-purchaseorderbycustomer }</buyer_ord_no>| &&
     |          <reference_no>{ wa_saleshead-salesorder }</reference_no>| &&
     |          <mode>{ wa_payment-paymenttermsconditiondesc }</mode>| &&
     |          <invoice_no>{ wa_billdoc-billingdocument }</invoice_no>| &&
     |          <e-way>{ ewaybill }</e-way>| &&
     |          <inv_date>{ lnv_date }</inv_date>| &&
     |          <so_date>{ lv_salesdate }</so_date>| &&
     |          <buyer_date>{ lv_custpur }</buyer_date>| &&
     |          <motor_no>{ wa_billdoc-yy1_vehicleno2_bdh }</motor_no>| &&
     |          <dispatch>{ wa_billdoctp-yy1_vehicletype_bdh }</dispatch>| &&
     |          <destination>{ lv_destination }</destination>| &&
     |        </Subform10>| &&
     |        <shipto_nm>{ sperson }</shipto_nm>| &&
     |        <shipto_addr>{ saddress1 }</shipto_addr>| &&
     |        <shipto_addr1></shipto_addr1>| &&
     |      </headersubform>| &&
     |    </Subform5>| &&
     |  </main_flowed_subform>| .

*
*   SELECT
*      a~billingdocument,
*      a~billingdocumentitemtext,
*      a~salesdocument,
*      a~salesdocumentitem,
*      a~referencesddocument,
*      a~distributionchannel,
*      a~product,
*      a~plant,
*    c~consumptiontaxctrlcode,
*      d~deliverydocument,
*      d~batch,
*      d~shelflifeexpirationdate,
*      d~actualdeliveryquantity,
*      d~deliveryquantityunit
*
*    FROM i_billingdocumentitem AS a
*    LEFT OUTER JOIN i_deliverydocumentitem AS d
*      ON d~deliverydocument = a~referencesddocument
*    LEFT OUTER JOIN i_productplantbasic AS c
*         ON c~product  = a~product
*             AND c~plant = a~plant
*    WHERE a~billingdocument = @io_billingdocument
*    INTO TABLE @DATA(it_bill_del).
*    DELETE it_bill_del WHERE batch IS INITIAL AND distributionchannel <> '30'..
*
*
*    READ TABLE it_billdoc_item INTO wa_billdoc_item
*    WITH KEY billingdocument = io_billingdocument.
*
*    DATA: lv_last_text   TYPE string,
*          lv_header_text TYPE string,
*          lv_detail_text TYPE string.
*
*    CLEAR: lv_last_text, lv_header_text.

    " Items - APPEND in loop using &&=
    "------------------------------------------------------------
    " 1. Fetch Billing + Delivery + Product data
    "------------------------------------------------------------
  "------------------------------------------------------------
" 1. Fetch billing + delivery data
"------------------------------------------------------------
    SELECT
        a~billingdocument,
        a~billingdocumentitem,
        a~billingdocumentitemtext,
        a~salesdocument,
        a~salesdocumentitem,
        a~referencesddocument,
        a~distributionchannel,
        a~product,
        a~plant,
        c~consumptiontaxctrlcode,
        d~deliverydocument,
        d~batch,
        d~shelflifeexpirationdate,
        d~actualdeliveryquantity,
        d~deliveryquantityunit
      FROM i_billingdocumentitem AS a
      LEFT OUTER JOIN i_deliverydocumentitem AS d
        ON d~deliverydocument = a~referencesddocument
         AND d~deliverydocumentitem = a~referencesddocumentitem
      LEFT OUTER JOIN i_productplantbasic AS c
        ON c~product = a~product
       AND c~plant   = a~plant
      WHERE a~billingdocument = @io_billingdocument
      INTO TABLE @DATA(it_bill_del).


    "------------------------------------------------------------
    " Business rule:
    " Distribution channel 30 allows non-batch items
    " Other channels require batch
    "------------------------------------------------------------
    DELETE it_bill_del
      WHERE batch IS INITIAL
        AND distributionchannel <> '30'.

    IF it_bill_del IS INITIAL.
      RETURN.
    ENDIF.

    "------------------------------------------------------------
    " 2. Fetch pricing data ONCE (Performance fix)
    "------------------------------------------------------------
    DATA: it_prcd1 TYPE STANDARD TABLE OF i_salesorderitempricingelement.

    SELECT *
      FROM i_salesorderitempricingelement
      FOR ALL ENTRIES IN @it_bill_del
      WHERE salesorder     = @it_bill_del-salesdocument
        AND salesorderitem = @it_bill_del-salesdocumentitem
      INTO TABLE @it_prcd1.

    "------------------------------------------------------------
    " 3. Variables
    "------------------------------------------------------------
    DATA: lv_last_item   TYPE i_billingdocumentitem-billingdocumentitem,
          lv_header_text TYPE string,
          lv_detail_text TYPE string,
          lv_rate1       TYPE decfloat34.



    "------------------------------------------------------------
    " 4. Item Processing
    "------------------------------------------------------------

    SORT it_bill_del BY billingdocumentitem.

CLEAR lv_last_item.
    LOOP AT it_bill_del INTO DATA(wa_item).

      CLEAR: lv_rate1, lv_header_text, lv_detail_text, lv_fulldes, lv_expiry.

      "--------------------------------------------------------
      " Pricing calculation
      "--------------------------------------------------------
      LOOP AT it_prcd1 INTO DATA(wa_prcd1)
     WHERE salesorder     = wa_item-salesdocument
       AND salesorderitem = wa_item-salesdocumentitem..

        CASE wa_prcd1-conditiontype.
          WHEN 'ZCIF' OR 'ZSCP' OR 'ZPR0'.
            lv_rate1 = wa_prcd1-conditionrateamount.
          WHEN 'ZPR0'.
            lv_rate1 = wa_prcd1-conditionrateamount.
        ENDCASE.

      ENDLOOP.

      " Apply exchange rate
*  lv_rate1 = lv_rate1 * wa_billdoc-accountingexchangerate.


lv_rate1 = lv_rate1 * lv_ex_rate.
      "--------------------------------------------------------
      " Serial number
      "--------------------------------------------------------
      lv_sr_no += 1.

      "--------------------------------------------------------
      " Expiry formatting (safe)
      "--------------------------------------------------------
      IF wa_item-shelflifeexpirationdate IS NOT INITIAL.
        lv_expiry =
          |{ wa_item-shelflifeexpirationdate+6(2) }/|
       && |{ wa_item-shelflifeexpirationdate+4(2) }/|
       && |{ wa_item-shelflifeexpirationdate+2(2) }|.
      ENDIF.

      "--------------------------------------------------------
      " Print item text only once per billing item
      "--------------------------------------------------------
      IF lv_last_item <> wa_item-billingdocumentitem.
        lv_header_text =
          |{ wa_item-billingdocumentitemtext } { wa_sales_itemtp-YY1_Pharmacopiea1_SDI }|
       && |{ cl_abap_char_utilities=>newline }|.
        lv_last_item = wa_item-billingdocumentitem.
      ENDIF.

      "--------------------------------------------------------
      " Batch + expiry always printed
      "--------------------------------------------------------
      lv_detail_text =
          |Batch: { wa_item-batch }|
       && |{ cl_abap_char_utilities=>newline }|
       && |Expiry: { lv_expiry }|.

      lv_fulldes = lv_header_text && lv_detail_text.

      "--------------------------------------------------------
      " Amount calculation
      "--------------------------------------------------------
      lv_amount = lv_rate1 * wa_item-actualdeliveryquantity .

      lv_gst_total = lv_sgst_total + lv_cgst_total + lv_igst_total.

      lv_total_amt += lv_amount.

      lv_total_char = lv_total_amt  + lv_sgst_total + lv_cgst_total + lv_igst_total .

      IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
        lv_taxable = lv_total_amt.
      ELSE.
        lv_taxable = lv_total_char.
      ENDIF.


      DATA: total TYPE string.
      total  += lv_taxable.
      lv_hsn = wa_item-consumptiontaxctrlcode.

      DATA lv_raw_text   TYPE string.
DATA lv_clean_text TYPE string.

lv_raw_text = wa_item-billingdocumentitemtext. " contains NBSP

lv_clean_text = sanitize_text( lv_raw_text ).
      "--------------------------------------------------------
      " XML Item Row
      "--------------------------------------------------------
      DATA(lv_item_row) =
          |  <sr_no>{ lv_sr_no }</sr_no>|
       && |  <descr>{ lv_raw_text }</descr>|
       && |  <hsn>{ wa_item-consumptiontaxctrlcode }</hsn>|
       && |  <qty>{ wa_item-actualdeliveryquantity }</qty>|
       && |  <rate>{ lv_rate1 }</rate>|
       && |  <per>{ wa_item-deliveryquantityunit }</per>|
       && |  <amt>{ lv_amount }</amt>|.

      lv_items = lv_items && lv_item_row .
      CLEAR : lv_item_row.

    ENDLOOP.



    DATA: lv_major TYPE string,
          lv_minor TYPE string.

    CLEAR: lv_major, lv_minor.
    CLEAR: lv_major, lv_minor.

    CASE wa_billdoc-transactioncurrency.

        " -------- RUPEE FAMILY --------
      WHEN 'INR'. lv_major = 'Rupee'.   lv_minor = 'Paise'.
      WHEN 'PKR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'NPR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'LKR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.
      WHEN 'SCR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.

        " -------- DOLLAR FAMILY --------
      WHEN 'USD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'AUD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'CAD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'NZD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'SGD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'HKD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.

        " -------- EURO --------
      WHEN 'EUR'. lv_major = 'Euro'.    lv_minor = 'Cent'.

        " -------- POUND --------
      WHEN 'GBP'. lv_major = 'Pound'.   lv_minor = 'Penny'.

        " -------- YEN / WON (NO MINOR) --------
      WHEN 'JPY'. lv_major = 'Yen'.     lv_minor = ''.
      WHEN 'KRW'. lv_major = 'Won'.     lv_minor = ''.

        " -------- MIDDLE EAST --------
      WHEN 'AED'. lv_major = 'Dirham'.  lv_minor = 'Fils'.
      WHEN 'SAR'. lv_major = 'Riyal'.   lv_minor = 'Halala'.
      WHEN 'QAR'. lv_major = 'Riyal'.   lv_minor = 'Dirham'.
      WHEN 'OMR'. lv_major = 'Rial'.    lv_minor = 'Baisa'.
      WHEN 'KWD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.
      WHEN 'BHD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.

        " -------- ASIA --------
      WHEN 'CNY'. lv_major = 'Yuan'.    lv_minor = 'Fen'.
      WHEN 'THB'. lv_major = 'Baht'.    lv_minor = 'Satang'.
      WHEN 'MYR'. lv_major = 'Ringgit'. lv_minor = 'Sen'.
      WHEN 'IDR'. lv_major = 'Rupiah'.  lv_minor = 'Sen'.
      WHEN 'PHP'. lv_major = 'Peso'.    lv_minor = 'Centavo'.

        " -------- AFRICA --------
      WHEN 'ZAR'. lv_major = 'Rand'.    lv_minor = 'Cent'.
      WHEN 'NGN'. lv_major = 'Naira'.   lv_minor = 'Kobo'.

        " -------- OTHERS / FALLBACK --------
      WHEN OTHERS.
        lv_major = wa_billdoc-transactioncurrency.
        lv_minor = ''.

    ENDCASE.



    DATA:lv_igst_rate_per TYPE string,
         lv_sgst_rate_per TYPE string.
    lv_igst_rate_per = |{ lv_igst_rate }%|.
    lv_sgst_rate_per = |{ lv_sgst_rate }%|.
    " Convert grand total amount to words
    DATA: lv_amount_string TYPE string.

    lv_amount_string = |{  lv_taxable }|.
    CONDENSE lv_amount_string.

    DATA: lv_level      TYPE i.

    CLEAR lv_level.


    lv_amt_inword = me->num2words(
      iv_num   = lv_amount_string
      iv_major = lv_major
      iv_minor = lv_minor
    ).



    DATA: lv_gst_string TYPE string.

    lv_gst_string = |{  lv_gst_total }|.
    CONDENSE lv_gst_string.
    DATA: lv_gst_inwords TYPE string.
    " lv_gst_inwords =  num2words( iv_num = lv_gst_string ).

    lv_gst_inwords = me->num2words(
      iv_num   = lv_gst_string
      iv_major = lv_major
      iv_minor = lv_minor
    ).

    IF lv_final_tax IS INITIAL OR lv_final_tax = 0.
      CLEAR lv_final_tax.
    ENDIF.


    DATA(lv_footer) =
     |  <amtword_subform>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <gst2>{ lv_text_gst1 }</gst2>| &&
     |        <cgst>{ lv_final_tax }</cgst>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |    <amt_in_words>{ lv_amt_inword }</amt_in_words>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <gst1>{ lv_text_gst }</gst1>| &&
     |        <sgst>{ lv_final_tax1 }</sgst>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <total>{ lv_taxable }</total>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |  </amtword_subform>| &&
     |  <gstsubform>| &&
     |    <g_sgst_table>| &&
     |      <Table2>| &&
     |        <HeaderRow>| &&
     |          <Cell2/>| &&
     |          <Cell4/>| &&
     |        </HeaderRow>| &&
     |        <Row1>| &&
     |          <gst_hsn>{ lv_hsn }</gst_hsn>| &&
     |          <gst_taxableval>{ lv_total_amt }</gst_taxableval>| &&
     |          <cgst_rate>{ lv_sgst_rate_per }</cgst_rate>| &&
     |          <cgst_amt>{ lv_cgst_total }</cgst_amt>| &&
     |          <sgst_rate>{ lv_sgst_rate_per }</sgst_rate>| &&
     |          <sgst_amt>{ lv_sgst_total }</sgst_amt>| &&
     |          <total_tax_amt>{ lv_gst_total }</total_tax_amt>| &&
     |        </Row1>| &&
     |        <FooterRow>| &&
     |          <cgst_amt>{ lv_cgst_total }</cgst_amt>| &&
     |          <sgst_amt>{ lv_sgst_total }</sgst_amt>| &&
     |          <grand_total>{ lv_gst_total }</grand_total>| &&
     |        </FooterRow>| &&
     |      </Table2>| &&
     |    </g_sgst_table>| &&
     |    <igst_table>| &&
     |      <Table2>| &&
     |        <HeaderRow>| &&
     |          <Cell2/>| &&
     |        </HeaderRow>| &&
     |        <Row1>| &&
     |          <gst_hsn>{ lv_hsn }</gst_hsn>| &&
     |          <gst_taxableval>{ lv_total_amt }</gst_taxableval>| &&
     |          <igst_rate>{ lv_igst_rate_per }</igst_rate>| &&
     |          <igst_amt>{ lv_igst_total }</igst_amt>| &&
     |          <total_tax_amt>{ lv_gst_total }</total_tax_amt>| &&
     |        </Row1>| &&
     |        <FooterRow>| &&
     |          <igst_amt>{ lv_igst_total }</igst_amt>| &&
     |          <grand_total>{ lv_gst_total }</grand_total>| &&
     |        </FooterRow>| &&
     |      </Table2>| &&
     |    </igst_table>| &&
     |  </gstsubform>| &&
     |  <tax_amt_word>{ lv_gst_inwords }</tax_amt_word>| &&
     |  <remark>{ wa_billdoc-yy1_remarks1_bdh }</remark>| &&
     |  <company_pan>AAACK3198E</company_pan>| &&
     |  <campany_qr>{ wa_irn-signed_qrcode }</campany_qr>| &&
     |</form1>| .


    lv_xml = lv_header && lv_items && lv_footer.

    rv_xml = lv_xml.

  ENDMETHOD.


METHOD build_xml_scrap.


  DATA: lv_sr_no        TYPE i VALUE 0,
          lv_des          TYPE i_salesorderitem-salesorderitemtext,
          lv_custpur      TYPE i_salesorder-customerpurchaseorderdate,
          lv_salesdate    TYPE i_salesorder-salesorderdate,
          lv_text(1000)   TYPE c,
          sperson(1000)   TYPE c,
          lv_hsn          TYPE i_productplantbasic-consumptiontaxctrlcode,
          saddress1(1000) TYPE c,
          bperson(1000)   TYPE c,
          batch           TYPE i_deliverydocumentitem-batch,
          expiry          TYPE i_deliverydocumentitem-shelflifeexpirationdate,
          baddress1(1000) TYPE c,
          lv_items        TYPE string.

    DATA: lv_sgst_item  TYPE decfloat34,
          lv_cgst_item  TYPE decfloat34,
          lv_igst_item  TYPE decfloat34,
          lv_disc_item  TYPE decfloat34,
          lv_charge_it  TYPE decfloat34,
          lv_total_char TYPE decfloat34,
          lv_total_amt  TYPE decfloat34,
          lv_gst_total  TYPE decfloat34,
          lv_amt_inword TYPE string,
          lv_taxable    TYPE decfloat34.

    DATA: lv_sgst_total   TYPE decfloat34,
          lv_cgst_total   TYPE decfloat34,
          lv_igst_total   TYPE decfloat34,
          lv_discount_tot TYPE decfloat34,
          lv_charges_tot  TYPE decfloat34.
    DATA: lv_fulldes TYPE string.
    DATA:lv_expiry TYPE string.

    "--------------------------------------------------------
    "query to fetch objects from i_billingdocumentitem
    "--------------------------------------------------------

    DATA: it_billdoc_item TYPE TABLE OF i_billingdocumentitem,
          wa_billdoc_item TYPE i_billingdocumentitem.
    SELECT *
    FROM i_billingdocumentitem
    WHERE billingdocument = @io_billingdocument
     INTO TABLE @it_billdoc_item.
    DELETE it_billdoc_item WHERE batch IS INITIAL AND distributionchannel <> '30'..

    "--------------------------------------------------------
    "query to fetch objects from i_billingdocumentitem
    "--------------------------------------------------------
    READ TABLE it_billdoc_item INTO wa_billdoc_item WITH KEY billingdocument = io_billingdocument.
    SELECT SINGLE *
      FROM i_billingdocument
      WHERE billingdocument = @io_billingdocument
       INTO  @DATA(wa_billdoc).

    SELECT SINGLE *
  FROM i_billingdocumenttp
  WHERE billingdocument = @io_billingdocument
   INTO  @DATA(wa_billdoctp).


    SELECT * FROM i_billingdocumentitemtexttp
    WHERE billingdocument = @io_billingdocument
    INTO TABLE @DATA(it_long_text).
    READ TABLE it_long_text INTO DATA(wa_long_text) WITH KEY billingdocument = io_billingdocument.
    "--------------------------------------------------------
    "query to fetch objectsi_deliveryitem
    "--------------------------------------------------------
    DATA: it_del_item TYPE TABLE OF i_deliverydocumentitem,
          wa_del_item TYPE i_deliverydocumentitem.
    SELECT * FROM i_deliverydocumentitem
    WHERE deliverydocument = @wa_billdoc_item-referencesddocument
    INTO TABLE @it_del_item.
    DELETE it_del_item WHERE batch IS INITIAL AND distributionchannel <> '30'..

    SELECT a~*,d~*
    FROM i_billingdocumentitem AS a
    LEFT OUTER JOIN i_deliverydocumentitem AS d
      ON d~deliverydocument = a~referencesddocument
    WHERE a~billingdocument = @io_billingdocument
    INTO TABLE @DATA(it_j_billdel).

*    SELECT *
*      FROM I_DeliveryDocumentItem
*      WHERE DeliveryDocument          = @wa_billdoc_item-ReferenceSDDocument
*      INTO TABLE @it_del_item.

    "--------------------------------------------------------
    "query to fetch objects from i_SalesOrder
    "--------------------------------------------------------

    SELECT SINGLE * FROM i_salesorder
      WHERE salesorder = @wa_billdoc_item-salesdocument
           INTO @DATA(wa_saleshead).

    SELECT SINGLE *
FROM i_paymenttermsconditionstext
WHERE paymentterms = @wa_saleshead-customerpaymentterms
INTO @DATA(wa_payment).
    "--------------------------------------------------------
    "query to fetch objects from i_SalesOrderitem
    "--------------------------------------------------------

    DATA: it_sales_item TYPE TABLE OF i_salesorderitem,
          wa_sales_item TYPE i_salesorderitem.
    SELECT *
    FROM i_salesorderitem
    WHERE salesorder = @wa_billdoc_item-salesdocument
     INTO TABLE @it_sales_item.
    READ TABLE it_sales_item INTO wa_sales_item WITH KEY salesorder = wa_billdoc_item-salesdocument.
    "--------------------------------------------------------
    "query to fetch objects from ship to address
    "--------------------------------------------------------

    DATA: it_vbpa TYPE TABLE OF i_salesorderpartner.
    SELECT *
             FROM i_salesorderpartner "i_salesorderitempartner "
       WHERE salesorder = @wa_billdoc_item-salesdocument
       INTO TABLE @it_vbpa.


    READ TABLE it_vbpa INTO DATA(wa_vbpa) WITH  KEY partnerfunction = 'WE'. "SHIP TO PARTY
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_vbpa-customer
        INTO @DATA(wa_kna1_s).

      SELECT SINGLE * FROM i_address_2
       WITH PRIVILEGED ACCESS
       WHERE addressid = @wa_kna1_s-addressid
       INTO @DATA(wa_address_ship).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_kna1_s-country
      AND region = @wa_kna1_s-region
      AND language = @sy-langu
     INTO @DATA(wa_region_ship).

      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_kna1_s-country
      AND language = @sy-langu
      INTO @DATA(wa_country_ship).

      IF wa_address_ship-careofname IS NOT INITIAL.
        sperson = wa_address_ship-careofname.
      ELSE.
        sperson = wa_address_ship-organizationname1.
      ENDIF.

      saddress1 = |{ wa_address_ship-streetprefixname1 } { wa_address_ship-streetname } { wa_address_ship-streetsuffixname1 } { wa_address_ship-streetsuffixname2 }  { wa_address_ship-cityname },{ wa_address_ship-postalcode }| .
      saddress1 = |{ saddress1 },{ wa_region_ship-regionname },{ wa_country_ship-countryname }| .

    ENDIF.

    "--------------------------------------------------------
    "query to fetch objects from Bill to address
    "--------------------------------------------------------

    READ TABLE it_vbpa INTO DATA(wa_vbpab) WITH  KEY partnerfunction = 'AG'. "SHIP TO PARTY
    IF sy-subrc = 0.

      SELECT SINGLE customer, addressid, customername, taxnumber3, country, region, bpcustomerfullname
       FROM i_customer
        WHERE customer = @wa_vbpab-customer
        INTO @DATA(wa_kna1_b).

      SELECT SINGLE * FROM i_address_2
       WITH PRIVILEGED ACCESS
       WHERE addressid = @wa_kna1_b-addressid
       INTO @DATA(wa_address_bill).

      SELECT SINGLE * FROM zc_lut_details
  WITH PRIVILEGED ACCESS
  WHERE lutno = @wa_billdoc-yy1_lutno2_bdh
  INTO @DATA(wa_lut_dlts).

      SELECT SINGLE * FROM i_regiontext WHERE country = @wa_kna1_b-country
      AND region = @wa_kna1_b-region
      AND language = @sy-langu
     INTO @DATA(wa_region_bill).

      SELECT SINGLE * FROM i_countrytext WHERE country = @wa_kna1_b-country
      AND language = @sy-langu
      INTO @DATA(wa_country_bill).

      IF wa_address_bill-careofname IS NOT INITIAL.
        bperson = wa_address_bill-careofname.
      ELSE.
        bperson = wa_address_bill-organizationname1.
      ENDIF.

      baddress1 = |{ wa_address_bill-streetprefixname1 } { wa_address_bill-streetname } { wa_address_bill-streetsuffixname1 } { wa_address_bill-streetsuffixname2 }  { wa_address_bill-cityname },{ wa_address_bill-postalcode }| .
      baddress1 = |{ baddress1 },{ wa_region_bill-regionname },{ wa_country_bill-countryname }| .

    ENDIF.

    "--------------------------------------------------------
    "hardcoded sender address
    "--------------------------------------------------------
    DATA : sender_nm(1000)    TYPE c,
           sender_addr(1000)  TYPE c,
           sender_addr1(1000) TYPE c,
           sender_addr3(1000) TYPE c,
           email(1000)        TYPE c,
           cin(1000)          TYPE c,
           sender_gst(1000)   TYPE c,
           gstin(1000)        TYPE c,
           policyno(1000)     TYPE c,
           druglicno(1000)    TYPE c,
           iecno(1000)        TYPE c,
           sender_state(1000) TYPE c.

    sender_nm = ' KOPRAN RESEARCH LABORATORIES LIMITED - 25-26'.
    sender_addr = 'K 4 ADD. MDC VILLAGE BIRWADI'.
    sender_addr1 = 'TAL MAHAD, DIST RAIGAD PINCODE:402302'.
    sender_addr3 = 'HO. JARIHAUL HOUSE, MOSSES ROAD WORLI MUMBAI'.
    email = 'sepatmhhd@kopran.com'.
    cin = 'U24230MH1968PLC040601'.
    gstin = '27AAACK3189E1ZJ'.
    policyno = '2414 2088 5972 8701 000'.
    druglicno = 'KDD/230 KD/265'.
    iecno = '03990216035'.
    sender_state = 'Maharashtra'.



    "--------------------------------------------------------
    "query to fetch objects from zei_invrefnum
    "--------------------------------------------------------
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

    "--------------------------------------------------------
    "query to fetch objects from zew_ewaybill
    "--------------------------------------------------------
    DATA: ewaybill TYPE zew_ewaybill-ebillno.
    SELECT SINGLE *
           FROM zew_ewaybill
          WHERE bukrs EQ @wa_billdoc-companycode
           AND  docno EQ @wa_billdoc-billingdocument
           INTO @DATA(eway).

    ewaybill = eway-ebillno.

    "--------------------------------------------------------
    "query to fetch gst and rate
    "--------------------------------------------------------

*
*    DATA: pricingelemnt    TYPE TABLE OF I_SalesOrderItemPricingElement,
*          wa_pricingelemnt TYPE I_SalesOrderItemPricingElement.


*    READ TABLE pricingelemnt INTO wa_pricingelemnt with key SalesOrder = wa_billdoc_item-SalesDocument.
 DATA: it_sales_itemtp TYPE TABLE OF i_salesorderitemtp,
          wa_sales_itemtp TYPE i_salesorderitemtp.
    SELECT *
    FROM i_salesorderitemtp
    WHERE salesorder = @wa_billdoc_item-salesdocument
     INTO TABLE @it_sales_itemtp.
    READ TABLE it_sales_itemtp INTO wa_sales_itemtp WITH KEY salesorder = wa_billdoc_item-salesdocument.

    SELECT *
      FROM i_salesorderitempricingelement
      WHERE salesorder = @wa_billdoc_item-salesdocument
      INTO TABLE @DATA(it_prcd).

    DATA: lv_cgst   TYPE decfloat34,
          lv_sgst   TYPE decfloat34,
          lv_igst   TYPE decfloat34,
          lv_amount TYPE p DECIMALS 2,
          lv_rate   TYPE decfloat34.

    " Clear all totals before loop
    CLEAR: lv_cgst, lv_sgst,lv_igst, lv_rate.

    CLEAR: lv_sgst_item, lv_cgst_item, lv_igst_item,
         lv_disc_item, lv_charge_it.


    DATA: lv_z_sgst TYPE abap_bool,
          lv_z_cgst TYPE abap_bool,
          lv_z_igst TYPE abap_bool.

    CLEAR: lv_z_sgst, lv_z_cgst, lv_z_igst.

    "--------------------------------------------------
    " First pass: detect Z conditions for this item
    "--------------------------------------------------
    LOOP AT it_prcd INTO DATA(wa_prcd)
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_prcd-conditiontype.
        WHEN 'ZOSG'. lv_z_sgst = abap_true.
        WHEN 'ZOCG'. lv_z_cgst = abap_true.
        WHEN 'ZOIG'. lv_z_igst = abap_true.
      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------
    " Second pass: calculate with priority
    "--------------------------------------------------
    LOOP AT it_prcd INTO wa_prcd
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_prcd-conditiontype.

          "------------ SGST -------------
        WHEN 'ZOSG'.
          lv_sgst_item += wa_prcd-conditionamount.

        WHEN 'JOSG'.
          IF lv_z_sgst IS INITIAL.
            lv_sgst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ CGST -------------
        WHEN 'ZOCG'.
          lv_cgst_item += wa_prcd-conditionamount.

        WHEN 'JOCG'.
          IF lv_z_cgst IS INITIAL.
            lv_cgst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ IGST -------------
        WHEN 'ZOIG'.
          lv_igst_item += wa_prcd-conditionamount.

        WHEN 'JOIG'.
          IF lv_z_igst IS INITIAL.
            lv_igst_item += wa_prcd-conditionamount.
          ENDIF.

          "------------ Base Price -------
        WHEN 'ZCIF' OR 'ZPR0' OR 'ZSCP'.
          lv_rate      += wa_prcd-conditionrateamount.
          lv_charge_it += wa_prcd-conditionamount.

      ENDCASE.

    ENDLOOP.


    lv_sgst_total  += lv_sgst_item.
    lv_cgst_total  += lv_cgst_item.
    lv_igst_total  += lv_igst_item.
    lv_discount_tot += lv_disc_item.
    lv_charges_tot += lv_charge_it.

*    IF lv_rate IS INITIAL.
*      lv_rate = wa_sales_item-netpriceamount.
*    ENDIF.


    DATA: lv_sgst_rate TYPE decfloat34,
          lv_cgst_rate TYPE decfloat34,
          lv_igst_rate TYPE decfloat34.

    CLEAR:  lv_sgst_rate,
       lv_cgst_rate,
       lv_igst_rate.

    DATA: lv_z_sgst_rate TYPE abap_bool,
          lv_z_cgst_rate TYPE abap_bool,
          lv_z_igst_rate TYPE abap_bool.

    CLEAR: lv_z_sgst_rate, lv_z_cgst_rate, lv_z_igst_rate.

    "--------------------------------------------------
    " First pass: detect Z-rate conditions
    "--------------------------------------------------
    LOOP AT it_prcd INTO DATA(wa_gst_rate)
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_gst_rate-conditiontype.
        WHEN 'ZOSG'. lv_z_sgst_rate = abap_true.
        WHEN 'ZOCG'. lv_z_cgst_rate = abap_true.
        WHEN 'ZOIG'. lv_z_igst_rate = abap_true.
      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------
    " Second pass: assign rate with priority
    "--------------------------------------------------

    LOOP AT it_prcd INTO wa_gst_rate
         WHERE salesorder     = wa_sales_item-salesorder
           AND salesorderitem = wa_sales_item-salesorderitem.

      CASE wa_gst_rate-conditiontype.

          "------------ SGST RATE -------------
        WHEN 'ZOSG'.
          lv_sgst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOSG'.
          IF lv_z_sgst_rate IS INITIAL.
            lv_sgst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

          "------------ CGST RATE -------------
        WHEN 'ZOCG'.
          lv_cgst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOCG'.
          IF lv_z_cgst_rate IS INITIAL.
            lv_cgst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

          "------------ IGST RATE -------------
        WHEN 'ZOIG'.
          lv_igst_rate = wa_gst_rate-conditionratevalue.

        WHEN 'JOIG'.
          IF lv_z_igst_rate IS INITIAL.
            lv_igst_rate = wa_gst_rate-conditionratevalue.
          ENDIF.

      ENDCASE.

    ENDLOOP.

    "--------------------------------------------------------
    " start of case for main table gst
    "--------------------------------------------------------
    DATA: lv_sgst_total1 TYPE decfloat34,
          lv_cgst_total1 TYPE decfloat34,
          lv_igst_total1 TYPE decfloat34.

    DATA: lv_sgst_item1 TYPE decfloat34,
          lv_cgst_item1 TYPE decfloat34,
          lv_igst_item1 TYPE decfloat34.


    DATA: lv_sgst_rate1 TYPE decfloat34,
          lv_cgst_rate1 TYPE decfloat34,
          lv_igst_rate1 TYPE decfloat34.
    CLEAR:  lv_sgst_rate1,
     lv_cgst_rate1,
     lv_igst_rate1.
    LOOP AT it_prcd INTO wa_gst_rate
     WHERE salesorder     = wa_sales_item-salesorder
       AND salesorderitem = wa_sales_item-salesorderitem.


      CASE wa_gst_rate-conditiontype.
          "------------ SGST RATE -------------
        WHEN 'JOSG'.
          lv_sgst_rate1 = wa_gst_rate-conditionratevalue.
          lv_sgst_item1 += wa_gst_rate-conditionamount.
          "------------ CGST RATE -------------
        WHEN 'JOCG'.
          lv_cgst_rate1 = wa_gst_rate-conditionratevalue.
          lv_cgst_item1 += wa_gst_rate-conditionamount.
          "------------ IGST RATE -------------
        WHEN 'JOIG'.
          lv_igst_rate1 = wa_gst_rate-conditionratevalue.
          lv_igst_item1 += wa_gst_rate-conditionamount.
      ENDCASE.

    ENDLOOP.
    lv_sgst_total1  += lv_sgst_item1.
    lv_cgst_total1  += lv_cgst_item1.
    lv_igst_total1  += lv_igst_item1.

    DATA : text_cgst(1000) TYPE c,
           text_igst(1000) TYPE c,
           text_sgst(1000) TYPE c.

    text_cgst = |CGST({ lv_sgst_rate1 }%)|.
    text_igst  = |IGST({ lv_igst_rate1 }%)|.
    text_sgst =  |SGST({ lv_sgst_rate1 }%)|.



    "--------------------------------------------------------
    " code to choose between gsts
    "--------------------------------------------------------

    DATA: lv_final_tax  TYPE decfloat34,
          lv_final_tax1 TYPE string,
          lv_text_gst   TYPE string,
          lv_text_gst1  TYPE string.

    " Final tax
    IF lv_igst_total1 IS INITIAL OR lv_igst_total1 = 0.
      IF lv_sgst_total1 IS INITIAL OR lv_sgst_total1 = 0.
        CLEAR lv_final_tax.
      ELSE.
        lv_final_tax = lv_sgst_total1.
      ENDIF.
    ELSE.
      lv_final_tax = lv_igst_total1.
    ENDIF.

    " Second tax
    IF lv_igst_total1 IS INITIAL OR lv_igst_total1 = 0.
      IF lv_cgst_total1 IS INITIAL OR lv_cgst_total1 = 0.
        CLEAR lv_final_tax1.
      ELSE.
        lv_final_tax1 = lv_cgst_total1.
      ENDIF.
    ELSE.
      CLEAR lv_final_tax1.
    ENDIF.

    " Text handling
    IF lv_igst_total IS INITIAL OR lv_igst_total = 0.
      lv_text_gst  = text_cgst.
      lv_text_gst1 = text_sgst.
    ELSE.
      CLEAR lv_text_gst.
      lv_text_gst1 = text_igst.
    ENDIF.



    "--------------------------------------------------------
    " star of  xml binding
    "--------------------------------------------------------
    DATA: lv_xml TYPE string VALUE ''.


    CLEAR lv_text.

    CASE wa_saleshead-distributionchannel.

      WHEN '10'.
        IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS UNDER BOND OR LETTER OF UNDERTAKING WITHOUT PAYMENT OF IGST'.
        ELSE.
          CLEAR lv_text.
        ENDIF.

      WHEN '20'.
        IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS UNDER BOND OR LETTER OF UNDERTAKING WITHOUT PAYMENT OF IGST'.
        ELSE.
          lv_text = 'SUPPLY MEANT FOR EXPORT/SUPPLY TO SEZ UNIT OR SEZ DEVELOPER FOR AUTHORISED OPERATIONS ON PAYMENT OF IGST'.
        ENDIF.

      WHEN '30'.
        CLEAR lv_text.

      WHEN OTHERS.
        CLEAR lv_text.

    ENDCASE.
    DATA: lv_destination TYPE string.

    CASE wa_saleshead-distributionchannel.

      WHEN '10'.

        lv_destination = wa_address_ship-cityname.
      WHEN '20'.
        lv_destination = wa_country_ship-countryname.

      WHEN '30'.
        lv_destination = wa_address_ship-cityname.

      WHEN OTHERS.
        lv_destination = wa_country_ship-countryname.

    ENDCASE.

    lv_custpur = |{ wa_saleshead-customerpurchaseorderdate+6(2) }/{ wa_saleshead-customerpurchaseorderdate+4(2) }/{ wa_saleshead-customerpurchaseorderdate+2(4) }|.
    lv_salesdate = |{ wa_saleshead-salesorderdate+6(2) }/{ wa_saleshead-salesorderdate+4(2) }/{ wa_saleshead-salesorderdate+2(4) }|.
    DATA: lnv_date type i_billingdocument-BillingDocumentDate.
    lnv_date = |{ wa_billdoc-billingdocumentdate+6(2) }/{ wa_billdoc-billingdocumentdate+4(2) }/{ wa_billdoc-billingdocumentdate+2(4) }|.
*    lv_hsn = wa_productplantbasic-consumptiontaxctrlcode.


    DATA(lv_header) =
     |<form1>| &&
     |  <main_flowed_subform>| &&
     |    <irn_details>| &&
     |      <data>| &&
     |        <Main>| &&
     |          <conditional_text>{ lv_text }</conditional_text>| &&
     |          <irn>{ irn }</irn>| &&
     |          <ackno>{ ack_no }</ackno>| &&
     |          <ack_dt>{ ack_dt }</ack_dt>| &&
     |        </Main>| &&
     |      </data>| &&
     |    </irn_details>| &&
     |    <Subform5>| &&
     |      <headersubform>| &&
     |        <Subform6>| &&
     |          <sender_nm>{ sender_nm }</sender_nm>| &&
     |          <sender_addr>{ sender_addr }</sender_addr>| &&
     |          <sender_addr1>{ sender_addr1 }</sender_addr1>| &&
     |          <email>{ email }</email>| &&
     |          <CIN>{ cin }</CIN>| &&
     |          <sender_gst></sender_gst>| &&
     |          <GSTIN>{ gstin }</GSTIN>| &&
     |          <POLICYNO>{ policyno }</POLICYNO>| &&
     |          <DRUGLICNO>{ druglicno }</DRUGLICNO>| &&
     |          <IECNO>{ iecno }</IECNO>| &&
     |          <SENDER_STATE>{ sender_state }</SENDER_STATE>| &&
     |          <sender_addr3>{ sender_addr3 }</sender_addr3>| &&
     |        </Subform6>| &&
     |        <Subform8>| &&
     |          <buyer_nm>{ bperson }</buyer_nm>| &&
     |          <buyer_addr>{ baddress1 }</buyer_addr>| &&
     |          <buyer_addr1></buyer_addr1>| &&
     |        </Subform8>| &&
     |        <Subform10>| &&
     |          <termofdelivery>{ wa_saleshead-incotermsclassification } { wa_saleshead-incotermslocation1 }</termofdelivery>| &&
     |          <lut_no>{ wa_lut_dlts-lutdescripton }</lut_no>| &&
     |          <country>{ wa_country_ship-countryname }</country>| &&
     |          <l_r_no>{ wa_billdoctp-yy1_lrno_bdh }</l_r_no>| &&
     |          <buyer_ord_no>{ wa_saleshead-purchaseorderbycustomer }</buyer_ord_no>| &&
     |          <reference_no>{ wa_saleshead-salesorder }</reference_no>| &&
     |          <mode>{ wa_payment-paymenttermsconditiondesc }</mode>| &&
     |          <invoice_no>{ wa_billdoc-billingdocument }</invoice_no>| &&
     |          <e-way>{ ewaybill }</e-way>| &&
     |          <inv_date>{ lnv_date }</inv_date>| &&
     |          <so_date>{ lv_salesdate }</so_date>| &&
     |          <buyer_date>{ lv_custpur }</buyer_date>| &&
     |          <motor_no>{ wa_billdoc-yy1_vehicleno2_bdh }</motor_no>| &&
     |          <dispatch>{ wa_billdoctp-yy1_vehicletype_bdh }</dispatch>| &&
     |          <destination>{ lv_destination }</destination>| &&
     |        </Subform10>| &&
     |        <shipto_nm>{ sperson }</shipto_nm>| &&
     |        <shipto_addr>{ saddress1 }</shipto_addr>| &&
     |        <shipto_addr1></shipto_addr1>| &&
     |      </headersubform>| &&
     |    </Subform5>| &&
     |  </main_flowed_subform>| .

*
*   SELECT
*      a~billingdocument,
*      a~billingdocumentitemtext,
*      a~salesdocument,
*      a~salesdocumentitem,
*      a~referencesddocument,
*      a~distributionchannel,
*      a~product,
*      a~plant,
*    c~consumptiontaxctrlcode,
*      d~deliverydocument,
*      d~batch,
*      d~shelflifeexpirationdate,
*      d~actualdeliveryquantity,
*      d~deliveryquantityunit
*
*    FROM i_billingdocumentitem AS a
*    LEFT OUTER JOIN i_deliverydocumentitem AS d
*      ON d~deliverydocument = a~referencesddocument
*    LEFT OUTER JOIN i_productplantbasic AS c
*         ON c~product  = a~product
*             AND c~plant = a~plant
*    WHERE a~billingdocument = @io_billingdocument
*    INTO TABLE @DATA(it_bill_del).
*    DELETE it_bill_del WHERE batch IS INITIAL AND distributionchannel <> '30'..
*
*
*    READ TABLE it_billdoc_item INTO wa_billdoc_item
*    WITH KEY billingdocument = io_billingdocument.
*
*    DATA: lv_last_text   TYPE string,
*          lv_header_text TYPE string,
*          lv_detail_text TYPE string.
*
*    CLEAR: lv_last_text, lv_header_text.

    " Items - APPEND in loop using &&=
    "------------------------------------------------------------
    " 1. Fetch Billing + Delivery + Product data
    "------------------------------------------------------------
  "------------------------------------------------------------
" 1. Fetch billing + delivery data
"------------------------------------------------------------
    SELECT
        a~billingdocument,
        a~billingdocumentitem,
        a~billingdocumentitemtext,
        a~salesdocument,
        a~salesdocumentitem,
        a~referencesddocument,
        a~distributionchannel,
        a~product,
        a~plant,
        c~consumptiontaxctrlcode,
        d~deliverydocument,
        d~batch,
        d~shelflifeexpirationdate,
        d~actualdeliveryquantity,
        d~deliveryquantityunit
      FROM i_billingdocumentitem AS a
      LEFT OUTER JOIN i_deliverydocumentitem AS d
        ON d~deliverydocument = a~referencesddocument
         AND d~deliverydocumentitem = a~referencesddocumentitem
      LEFT OUTER JOIN i_productplantbasic AS c
        ON c~product = a~product
       AND c~plant   = a~plant
      WHERE a~billingdocument = @io_billingdocument
      INTO TABLE @DATA(it_bill_del).


    "------------------------------------------------------------
    " Business rule:
    " Distribution channel 30 allows non-batch items
    " Other channels require batch
    "------------------------------------------------------------
    DELETE it_bill_del
      WHERE batch IS INITIAL
        AND distributionchannel <> '30'.

    IF it_bill_del IS INITIAL.
      RETURN.
    ENDIF.

    "------------------------------------------------------------
    " 2. Fetch pricing data ONCE (Performance fix)
    "------------------------------------------------------------
    DATA: it_prcd1 TYPE STANDARD TABLE OF i_salesorderitempricingelement.

    SELECT *
      FROM i_salesorderitempricingelement
      FOR ALL ENTRIES IN @it_bill_del
      WHERE salesorder     = @it_bill_del-salesdocument
        AND salesorderitem = @it_bill_del-salesdocumentitem
      INTO TABLE @it_prcd1.

    "------------------------------------------------------------
    " 3. Variables
    "------------------------------------------------------------
    DATA: lv_last_item   TYPE i_billingdocumentitem-billingdocumentitem,
          lv_header_text TYPE string,
          lv_detail_text TYPE string,
          lv_rate1       TYPE decfloat34,
          lv_tcs_per  TYPE decfloat34,
            lv_tcs       TYPE decfloat34.



    "------------------------------------------------------------
    " 4. Item Processing
    "------------------------------------------------------------

    SORT it_bill_del BY billingdocumentitem.

CLEAR lv_last_item.
    LOOP AT it_bill_del INTO DATA(wa_item).

      CLEAR: lv_rate1, lv_header_text, lv_detail_text, lv_fulldes, lv_expiry.

      "--------------------------------------------------------
      " Pricing calculation
      "--------------------------------------------------------
      LOOP AT it_prcd1 INTO DATA(wa_prcd1)
     WHERE salesorder     = wa_item-salesdocument
       AND salesorderitem = wa_item-salesdocumentitem..

        CASE wa_prcd1-conditiontype.
          WHEN 'ZCIF' OR 'ZSCP' OR 'ZPR0'.
            lv_rate1 = wa_prcd1-conditionrateamount.
          WHEN 'JTC2'.
          lv_tcs_per = wa_prcd1-ConditionRateValue.
            lv_tcs += wa_prcd1-conditionamount.
        ENDCASE.

      ENDLOOP.

      " Apply exchange rate
*  lv_rate1 = lv_rate1 * wa_billdoc-accountingexchangerate.

      "--------------------------------------------------------
      " Serial number
      "--------------------------------------------------------
      lv_sr_no += 1.

      "--------------------------------------------------------
      " Expiry formatting (safe)
      "--------------------------------------------------------
      IF wa_item-shelflifeexpirationdate IS NOT INITIAL.
        lv_expiry =
          |{ wa_item-shelflifeexpirationdate+6(2) }/|
       && |{ wa_item-shelflifeexpirationdate+4(2) }/|
       && |{ wa_item-shelflifeexpirationdate+2(2) }|.
      ENDIF.

      "--------------------------------------------------------
      " Print item text only once per billing item
      "--------------------------------------------------------

        lv_header_text =
          |{ wa_item-billingdocumentitemtext } { wa_sales_itemtp-YY1_Pharmacopiea1_SDI }|
       && |{ cl_abap_char_utilities=>newline }|.

      "--------------------------------------------------------
      " Batch + expiry always printed
      "--------------------------------------------------------
      lv_detail_text =
          |Batch: { wa_item-batch }|
       && |{ cl_abap_char_utilities=>newline }|
       && |Expiry: { lv_expiry }|.

     IF wa_item-batch IS INITIAL.
  lv_fulldes = lv_header_text.
ELSE.
  lv_fulldes = lv_header_text && lv_detail_text.
ENDIF.


      "--------------------------------------------------------
      " Amount calculation
      "--------------------------------------------------------
      lv_amount = lv_rate1 * wa_item-actualdeliveryquantity.

      lv_gst_total = lv_sgst_total + lv_cgst_total + lv_igst_total.

      lv_total_amt += lv_amount.

      lv_total_char = lv_total_amt  + lv_sgst_total + lv_cgst_total + lv_igst_total + lv_tcs .

      IF wa_billdoc-yy1_lutno2_bdh IS NOT INITIAL.
        lv_taxable = lv_total_amt.
      ELSE.
        lv_taxable = lv_total_char.
      ENDIF.


      DATA: total TYPE string.
      total  += lv_taxable.
      lv_hsn = wa_item-consumptiontaxctrlcode.



      "--------------------------------------------------------
      " XML Item Row
      "--------------------------------------------------------
      DATA(lv_item_row) =
          |  <sr_no>{ lv_sr_no }</sr_no>|
       && |  <descr>{ lv_fulldes }</descr>|
       && |  <hsn>{ wa_item-consumptiontaxctrlcode }</hsn>|
       && |  <qty>{ wa_item-actualdeliveryquantity }</qty>|
       && |  <rate>{ lv_rate1 }</rate>|
       && |  <per>{ wa_item-deliveryquantityunit }</per>|
       && |  <amt>{ lv_amount }</amt>|.

      lv_items = lv_items && lv_item_row .
      CLEAR : lv_item_row.

    ENDLOOP.



    DATA: lv_major TYPE string,
          lv_minor TYPE string.

    CLEAR: lv_major, lv_minor.
    CLEAR: lv_major, lv_minor.

    CASE wa_billdoc-transactioncurrency.

        " -------- RUPEE FAMILY --------
      WHEN 'INR'. lv_major = 'Rupee'.   lv_minor = 'Paise'.
      WHEN 'PKR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'NPR'. lv_major = 'Rupee'.   lv_minor = 'Paisa'.
      WHEN 'LKR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.
      WHEN 'SCR'. lv_major = 'Rupee'.   lv_minor = 'Cent'.

        " -------- DOLLAR FAMILY --------
      WHEN 'USD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'AUD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'CAD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'NZD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'SGD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.
      WHEN 'HKD'. lv_major = 'Dollar'.  lv_minor = 'Cent'.

        " -------- EURO --------
      WHEN 'EUR'. lv_major = 'Euro'.    lv_minor = 'Cent'.

        " -------- POUND --------
      WHEN 'GBP'. lv_major = 'Pound'.   lv_minor = 'Penny'.

        " -------- YEN / WON (NO MINOR) --------
      WHEN 'JPY'. lv_major = 'Yen'.     lv_minor = ''.
      WHEN 'KRW'. lv_major = 'Won'.     lv_minor = ''.

        " -------- MIDDLE EAST --------
      WHEN 'AED'. lv_major = 'Dirham'.  lv_minor = 'Fils'.
      WHEN 'SAR'. lv_major = 'Riyal'.   lv_minor = 'Halala'.
      WHEN 'QAR'. lv_major = 'Riyal'.   lv_minor = 'Dirham'.
      WHEN 'OMR'. lv_major = 'Rial'.    lv_minor = 'Baisa'.
      WHEN 'KWD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.
      WHEN 'BHD'. lv_major = 'Dinar'.   lv_minor = 'Fils'.

        " -------- ASIA --------
      WHEN 'CNY'. lv_major = 'Yuan'.    lv_minor = 'Fen'.
      WHEN 'THB'. lv_major = 'Baht'.    lv_minor = 'Satang'.
      WHEN 'MYR'. lv_major = 'Ringgit'. lv_minor = 'Sen'.
      WHEN 'IDR'. lv_major = 'Rupiah'.  lv_minor = 'Sen'.
      WHEN 'PHP'. lv_major = 'Peso'.    lv_minor = 'Centavo'.

        " -------- AFRICA --------
      WHEN 'ZAR'. lv_major = 'Rand'.    lv_minor = 'Cent'.
      WHEN 'NGN'. lv_major = 'Naira'.   lv_minor = 'Kobo'.

        " -------- OTHERS / FALLBACK --------
      WHEN OTHERS.
        lv_major = wa_billdoc-transactioncurrency.
        lv_minor = ''.

    ENDCASE.

data : lv_TCS_text type string.
    lv_TCS_text = |TCS({ lv_tcs_per }%)|.

    DATA:lv_igst_rate_per TYPE string,
         lv_sgst_rate_per TYPE string.
    lv_igst_rate_per = |{ lv_igst_rate }%|.
    lv_sgst_rate_per = |{ lv_sgst_rate }%|.
    " Convert grand total amount to words
    DATA: lv_amount_string TYPE string.

    lv_amount_string = |{  lv_taxable }|.
    CONDENSE lv_amount_string.

    DATA: lv_level      TYPE i.

    CLEAR lv_level.


    lv_amt_inword = me->num2words(
      iv_num   = lv_amount_string
      iv_major = lv_major
      iv_minor = lv_minor
    ).



    DATA: lv_gst_string TYPE string.

    lv_gst_string = |{  lv_gst_total }|.
    CONDENSE lv_gst_string.
    DATA: lv_gst_inwords TYPE string.
    " lv_gst_inwords =  num2words( iv_num = lv_gst_string ).

    lv_gst_inwords = me->num2words(
      iv_num   = lv_gst_string
      iv_major = lv_major
      iv_minor = lv_minor
    ).

*    IF lv_final_tax IS INITIAL OR lv_final_tax = 0.
*      CLEAR lv_final_tax.
*    ENDIF.


DATA: lv_final_tax1_disp TYPE string.

IF lv_final_tax <= 0.
  CLEAR lv_final_tax1_disp.
ELSE.
  lv_final_tax1_disp = |{ lv_final_tax }|.
  CONDENSE lv_final_tax1_disp.

  " Remove trailing zeros after decimal
  REPLACE REGEX '(\.[0-9]+)0+$'
    IN lv_final_tax1_disp WITH '\1'.

  " Remove decimal point if nothing follows
  REPLACE REGEX '\.$'
    IN lv_final_tax1_disp WITH ''.
ENDIF.


*    DATA: lv_final_tax1_disp TYPE string.
*    IF lv_final_tax <= 0.
*      CLEAR lv_final_tax1_disp.   " results in spaces / blank
*    ELSE.
*      lv_final_tax1_disp = lv_final_tax.
*    ENDIF.

    DATA(lv_footer) =
     |  <amtword_subform>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <gst2>{ lv_text_gst }</gst2>| &&
     |        <cgst>{ lv_final_tax1 }</cgst>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |    <amt_in_words>{ lv_amt_inword }</amt_in_words>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <gst1>{ lv_text_gst1 }</gst1>| &&
     |        <sgst>{ lv_final_tax1_disp }</sgst>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
  |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <tcs_per>{ lv_TCS_text }</tcs_per>| &&
     |        <TCS>{ lv_tcs }</TCS>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |    <Table3>| &&
     |      <HeaderRow>| &&
     |        <total>{ lv_taxable }</total>| &&
     |      </HeaderRow>| &&
     |    </Table3>| &&
     |  </amtword_subform>| &&
     |  <gstsubform>| &&
     |    <g_sgst_table>| &&
     |      <Table2>| &&
     |        <HeaderRow>| &&
     |          <Cell2/>| &&
     |          <Cell4/>| &&
     |        </HeaderRow>| &&
     |        <Row1>| &&
     |          <gst_hsn>{ lv_hsn }</gst_hsn>| &&
     |          <gst_taxableval>{ lv_total_amt }</gst_taxableval>| &&
     |          <cgst_rate>{ lv_sgst_rate_per }</cgst_rate>| &&
     |          <cgst_amt>{ lv_cgst_total }</cgst_amt>| &&
     |          <sgst_rate>{ lv_sgst_rate_per }</sgst_rate>| &&
     |          <sgst_amt>{ lv_sgst_total }</sgst_amt>| &&
     |          <total_tax_amt>{ lv_gst_total }</total_tax_amt>| &&
     |        </Row1>| &&
     |        <FooterRow>| &&
     |          <cgst_amt>{ lv_cgst_total }</cgst_amt>| &&
     |          <sgst_amt>{ lv_sgst_total }</sgst_amt>| &&
     |          <grand_total>{ lv_gst_total }</grand_total>| &&
     |        </FooterRow>| &&
     |      </Table2>| &&
     |    </g_sgst_table>| &&
     |    <igst_table>| &&
     |      <Table2>| &&
     |        <HeaderRow>| &&
     |          <Cell2/>| &&
     |        </HeaderRow>| &&
     |        <Row1>| &&
     |          <gst_hsn>{ lv_hsn }</gst_hsn>| &&
     |          <gst_taxableval>{ lv_total_amt }</gst_taxableval>| &&
     |          <igst_rate>{ lv_igst_rate_per }</igst_rate>| &&
     |          <igst_amt>{ lv_igst_total }</igst_amt>| &&
     |          <total_tax_amt>{ lv_gst_total }</total_tax_amt>| &&
     |        </Row1>| &&
     |        <FooterRow>| &&
     |          <igst_amt>{ lv_igst_total }</igst_amt>| &&
     |          <grand_total>{ lv_gst_total }</grand_total>| &&
     |        </FooterRow>| &&
     |      </Table2>| &&
     |    </igst_table>| &&
     |  </gstsubform>| &&
     |  <tax_amt_word>{ lv_gst_inwords }</tax_amt_word>| &&
     |  <remark>{ wa_billdoc-yy1_remarks1_bdh }</remark>| &&
     |  <company_pan>AAACK3198E</company_pan>| &&
     |  <campany_qr>{ wa_irn-signed_qrcode }</campany_qr>| &&
     |</form1>| .


    lv_xml = lv_header && lv_items && lv_footer.

    rv_xml = lv_xml.

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

METHOD sanitize_text.

  CONSTANTS c_nbsp TYPE string VALUE ' '.  " ← NBSP pasted here

  rv_text = iv_text.

  REPLACE ALL OCCURRENCES OF c_nbsp IN rv_text WITH space.

  rv_text = escape(
              val    = rv_text
              format = cl_abap_format=>e_xml_text ).

  REPLACE ALL OCCURRENCES OF '&#160;' IN rv_text WITH space.

  REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
    IN rv_text WITH space.
  REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline
    IN rv_text WITH space.

  CONDENSE rv_text.

ENDMETHOD.







METHOD escape_xml.

  rv_out = CONV string( iv_in ).

  " Normalize NBSP copied from PDF (PASTE NBSP BETWEEN QUOTES)
  REPLACE ALL OCCURRENCES OF ' ' IN rv_out WITH space.

  " Escape XML special characters ONLY
  REPLACE ALL OCCURRENCES OF '&'   IN rv_out WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<'   IN rv_out WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>'   IN rv_out WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"'   IN rv_out WITH '&quot;'.
  REPLACE ALL OCCURRENCES OF ''''  IN rv_out WITH '&apos;'.

ENDMETHOD.





ENDCLASS.
