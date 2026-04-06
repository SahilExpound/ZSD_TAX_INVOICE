CLASS zcl_test_billing_header DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

ENDCLASS.



CLASS ZCL_TEST_BILLING_HEADER IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF i_billingdocumenttp
      ENTITY billingdocument
      BY \_text
      ALL FIELDS
      WITH VALUE #( ( billingdocument = '0090000087' ) )
      RESULT DATA(lt_text_result)
      FAILED FINAL(ls_failed_read)
      REPORTED FINAL(ls_reported_read).

*READ ENTITIES OF I_BillingDocumentTP
*  ENTITY BillingDocumentItem
*  BY \_ItemText
*  ALL FIELDS WITH
*  VALUE #( ( BillingDocument = '0090000054'
*             BillingDocumentItem = '000010' ) )
*  RESULT DATA(lt_text_result)
*  FAILED DATA(ls_failed_read)
*  REPORTED DATA(ls_reported).

    CHECK ls_failed_read IS INITIAL.

    DATA lt_filtered_text LIKE lt_text_result.

    lt_filtered_text = VALUE #(
      FOR ls_text IN lt_text_result
      WHERE ( language   = 'E'
          AND longtextid = 'ZS00' )
      ( ls_text )
    ).

    CHECK lt_filtered_text IS NOT INITIAL.

    DATA(lv_longtext) = lt_filtered_text[ 1 ]-longtext.

  ENDMETHOD.
ENDCLASS.
