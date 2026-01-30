
 CLASS lsc_zi_tax_invoice DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_tax_invoice IMPLEMENTATION.

  METHOD save_modified.
    DATA lo_pfd TYPE REF TO zcl_tax_invoice.  "<-write your class name
    DATA wa_data TYPE ztb_tax_new.  "<-write your table name
    CREATE OBJECT lo_pfd.

    IF update-zi_tax_invoice_doc IS NOT INITIAL."<-write your interface name

      LOOP AT update-zi_tax_invoice_doc INTO DATA(ls_data)."<-write your interface name

        DATA(new) = NEW zbg_tax_invoice( iv_bill = ls_data-billingdocument iv_m_ind = ls_data-m_ind )."<-write your background process class

        DATA background_process TYPE REF TO if_bgmc_process_single_op.

        TRY.

            background_process = cl_bgmc_process_factory=>get_default( )->create( ).

            background_process->set_operation_tx_uncontrolled( new ).

            IF ls_data-m_ind EQ 'X'.
*                 MOVE-CORRESPONDING ls_data TO wa_data.
              wa_data-billingdocument    = ls_data-billingdocument.
              wa_data-base64_3 = ls_data-base64.
              wa_data-m_ind    = ls_data-m_ind.
              MODIFY ztb_tax_new FROM @wa_data.  "<-write your table name
            ENDIF.

            background_process->save_for_execution( ).

          CATCH cx_bgmc INTO DATA(exception).
            "handle exception
        ENDTRY.

      ENDLOOP.
    ENDIF.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_zi_tax_invoice_DOC DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_tax_invoice_doc RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_tax_invoice_doc RESULT result.

    METHODS zprint FOR MODIFY
      IMPORTING keys FOR ACTION zi_tax_invoice_doc~zprint RESULT result.

ENDCLASS.


CLASS lhc_zi_tax_invoice_DOC IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD zprint.

    DATA lo_pfd TYPE REF TO zcl_tax_invoice. "<-write your logic class

    CREATE OBJECT lo_pfd.

    READ ENTITIES OF zi_tax_invoice IN LOCAL MODE "<-write your interface name
           ENTITY zi_tax_invoice_doc   "<-write your interface name
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT DATA(lt_result).

    LOOP AT lt_result INTO DATA(lw_result).

      DATA : update_lines TYPE TABLE FOR UPDATE  zi_tax_invoice,   "<-write your interface name
             update_line  TYPE STRUCTURE FOR UPDATE  zi_tax_invoice.   "<-write your interface name

      update_line-%tky                   = lw_result-%tky.
      update_line-base64                 = 'A'.

      IF update_line-base64 IS NOT INITIAL.

        APPEND update_line TO update_lines.

        MODIFY ENTITIES OF  zi_tax_invoice IN LOCAL MODE    "<-write your interface name
         ENTITY zi_tax_invoice_doc    "<-write your interface behaviour definition name
           UPDATE
           FIELDS ( base64 )
           WITH update_lines
         REPORTED reported
         FAILED failed
         MAPPED mapped.

        READ ENTITIES OF zi_tax_invoice IN LOCAL MODE  ENTITY zi_tax_invoice_doc  "<-write your interface name and behaviour definition name
            ALL FIELDS WITH CORRESPONDING #( lt_result ) RESULT DATA(lt_final).

        result =  VALUE #( FOR  lw_final IN  lt_final ( %tky = lw_final-%tky
         %param = lw_final  )  ).

        APPEND VALUE #( %tky = keys[ 1 ]-%tky
                        %msg = new_message_with_text(
                        severity = if_abap_behv_message=>severity-success
                        text = 'PDF Generated!, Please Wait for 30 Sec' )
                         ) TO reported-zi_tax_invoice_doc.    "<-write your interface behaviour definition name

      ELSE.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
