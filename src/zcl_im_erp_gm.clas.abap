class ZCL_IM_ERP_GM definition
  public
  final
  create public .

public section.

  interfaces /SCWM/IF_EX_ERP_GOODSMVT .
  interfaces IF_BADI_INTERFACE .
protected section.
private section.

  constants C_DOC_TYPE type /LIME/REF_DOC_TYPE value 'SCWM_REFUI' ##NO_TEXT.

  class-methods Z_PI_ITEM_GET
    importing
      !IS_PI_ITEM_GUID type /LIME/PI_GUID
    exporting
      !ET_PI_ITEM_READ_SINGLE type /LIME/PI_T_ITEM_READ_GETSINGLE .
ENDCLASS.



CLASS ZCL_IM_ERP_GM IMPLEMENTATION.


  METHOD /scwm/if_ex_erp_goodsmvt~change_matdoc.

    "Reference to be found in text type ’scwm_refui’
    DATA: lt_item_pi TYPE /lime/pi_t_guid,
          ls_item_pi TYPE /lime/pi_guid.

    "Set BreakPointID
    BREAK-POINT ID zewmdevbook_1fwa.
* Assumptions:
* 1.NO cumulative posting!
* 2.NO recounts!
* 3.Entries of ordim_c = entries of goodsmvt_item
    DATA(lv_erplines) = lines( ct_goodsmvt_item ).
    DATA(lv_ewmlines) = lines( it_ordim_c ).
    IF lv_erplines <> lv_ewmlines.
      RETURN.
    ENDIF.
    LOOP AT it_ordim_c ASSIGNING FIELD-SYMBOL(<fs_ordim_c>).
      DATA(lv_tabix) = sy-tabix.
      "Is predecessor pi document?
      IF <fs_ordim_c>-qdoccat <> wmegc_doccat_wi1
      AND <fs_ordim_c>-qdocid IS INITIAL.
        CONTINUE.
      ENDIF.
      CLEAR: lt_item_pi, ls_item_pi.
      MOVE <fs_ordim_c>-qdocid TO ls_item_pi-guid.
      APPEND ls_item_pi TO lt_item_pi.
      CALL METHOD me->z_pi_item_get(
        EXPORTING
          is_pi_item_guid        = ls_item_pi
        IMPORTING
          et_pi_item_read_single = DATA(lt_item_read) ).

      "Get reference for PID
      DATA(ls_item_read) = VALUE #( lt_item_read[ 1 ] ).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      DATA(ls_logitem) = VALUE #( ls_item_read-t_logitem[ ref_doc_type = c_doc_type ] ).
      DATA(lv_reference) = ls_logitem-ref_doc_id.
      "Move reference into materialdocument
      READ TABLE ct_goodsmvt_item
      ASSIGNING FIELD-SYMBOL(<fs_gm_item>) INDEX lv_tabix.
      IF  <fs_gm_item> IS ASSIGNED
      AND <fs_gm_item>-item_text IS INITIAL.
        MOVE lv_reference TO <fs_gm_item>-item_text.
      ENDIF.
      CLEAR lv_tabix.
    ENDLOOP.

  ENDMETHOD.


  METHOD z_pi_item_get.

    DATA:
      lt_item_key  TYPE /lime/pi_t_item_key,
      lt_item_read TYPE /lime/pi_t_item_read_getsingle,
      lt_item_pi   TYPE /lime/pi_t_guid,
      lt_item_guid TYPE /lime/pi_t_guid_item.

    CLEAR lt_item_pi.
    APPEND is_pi_item_guid TO lt_item_pi.
    "Get key of PID
    CALL FUNCTION '/LIME/PI_DOCUMENT_GET_ITEM_KEY'
      EXPORTING
        it_line_guid = lt_item_pi
      IMPORTING
        et_item_key  = lt_item_key.
    IF sy-subrc = 0.
      "Get PID
      DATA(ls_item_key) = VALUE #( lt_item_key[ 1 ] ).
      DATA(ls_head) = VALUE /lime/pi_head_attributes(
        process_type = ls_item_key-process_type
        lgnum        = ls_item_key-lgnum ).
      CLEAR lt_item_guid.
      DATA(ls_item_guid) = VALUE /lime/pi_s_guid_item(
        guid_doc = ls_item_key-guid_doc ).
      APPEND ls_item_guid TO lt_item_guid.
      CALL FUNCTION '/LIME/PI_DOCUMENT_READ_SINGLE'
        EXPORTING
          is_head      = ls_head
          it_guid_doc  = lt_item_guid
        IMPORTING
          et_item_read = lt_item_read.
      IF sy-subrc = 0.
        et_pi_item_read_single = lt_item_read.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
