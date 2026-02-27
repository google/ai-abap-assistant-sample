**********************************************************************
*  Copyright 2025 Google LLC                                         *
*                                                                    *
*  Licensed under the Apache License, Version 2.0 (the "License");   *
*  you may not use this file except in compliance with the License.  *
*  You may obtain a copy of the License at                           *
*      https://www.apache.org/licenses/LICENSE-2.0                   *
*  Unless required by applicable law or agreed to in writing,        *
*  software distributed under the License is distributed on an       *
*  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,      *
*  either express or implied.                                        *
*  See the License for the specific language governing permissions   *
*  and limitations under the License.                                *
**********************************************************************
*&---------------------------------------------------------------------*
*& Modulpool ZRCA_LLM_PROMPT_MANAGER
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
*************************************************************************
PROGRAM zrca_llm_prompt_manager.

DATA: gv_action_type TYPE c.
DATA: gs_prompt_data TYPE zcac_prompt_data.
DATA: go_rich_text_editor TYPE REF TO cl_gui_textedit,
      gc_ccontroller      TYPE REF TO cl_gui_custom_container.

DATA: s_app_id      TYPE zca_application_id,
      s_prompt_id   TYPE zca_prompt_id,
      s_version     TYPE zca_prompt_version,
      s_status      TYPE zca_prompt_status,
      s_description TYPE zca_prompt_description.

CONSTANTS: lc_line_length TYPE i VALUE 256.

* define table type for data exchange
TYPES: BEGIN OF prompt_line,
         line(lc_line_length) TYPE c,
       END OF prompt_line.

* table to exchange text
DATA gt_prompttable TYPE TABLE OF prompt_line.
DATA: lv_current_line     TYPE string,
      lv_remaining_length TYPE i,
      "ls_mytable          TYPE mytable_line,
      lv_index            TYPE i.

CLASS lcl_prompt_manager DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS:
      on_pbo_0100,
      on_pai_0100
        IMPORTING
          iv_ucomm TYPE sy-ucomm,
      on_pbo_0200,
      on_pai_0200
        IMPORTING
          iv_ucomm TYPE sy-ucomm,
      on_f4_help
        IMPORTING
          iv_retfield TYPE dfies-fieldname
          iv_dynfield TYPE dynfnam.
  PRIVATE SECTION.
    CLASS-METHODS:
      handle_execute,
      handle_create,
      handle_send,
      handle_approve,
      handle_copy,
      handle_save,
      handle_delete,
      check_approval_auth
        RETURNING VALUE(rv_authorized) TYPE abap_bool.
ENDCLASS.

MODULE status_0100 OUTPUT.
  lcl_prompt_manager=>on_pbo_0100( ).
ENDMODULE.

MODULE user_command_0100 INPUT.
  lcl_prompt_manager=>on_pai_0100( sy-ucomm ).
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_0200 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  lcl_prompt_manager=>on_pbo_0200( ).
ENDMODULE.
MODULE user_command_0200 INPUT.
  lcl_prompt_manager=>on_pai_0200( sy-ucomm ).
ENDMODULE.

***Search help for Prompt ID
MODULE f4_help_1.
  lcl_prompt_manager=>on_f4_help( iv_retfield = 'PROMPT_ID' iv_dynfield = 'S_PROMPT_ID' ).
ENDMODULE.

***Search help for App ID
MODULE f4_help_2.
  lcl_prompt_manager=>on_f4_help( iv_retfield = 'APPLICATION_ID' iv_dynfield = 'S_APP_ID' ).
ENDMODULE.

***Search help for Version
MODULE f4_help_3.
  lcl_prompt_manager=>on_f4_help( iv_retfield = 'VERSION' iv_dynfield = 'S_VERSION' ).
ENDMODULE.


*&---------------------------------------------------------------------*
*& Class Implementation: lcl_prompt_manager
*&---------------------------------------------------------------------*
CLASS lcl_prompt_manager IMPLEMENTATION.
  METHOD on_pbo_0100.
    SET PF-STATUS 'ZSTATUS_100'.
    SET TITLEBAR 'Z100'.
  ENDMETHOD.
  METHOD on_pai_0100.
    CLEAR: gs_prompt_data,
           gv_action_type,
           gt_prompttable.
    CASE iv_ucomm.
      WHEN 'EXECUTE'.
        handle_execute( ).
      WHEN 'CREATE'.
        handle_create( ).
      WHEN 'BACK' OR 'EXIT' OR 'CANC'.
        IF iv_ucomm = 'EXIT'.
          LEAVE PROGRAM.
        ELSE.
          LEAVE TO SCREEN 0.
        ENDIF.
      WHEN 'SEND'.
        handle_send( ).
      WHEN 'APPROVE'.
        handle_approve( ).
      WHEN 'COPY'.
        handle_copy( ).
    ENDCASE.
  ENDMETHOD.
  METHOD handle_execute.
    gv_action_type = 'E'.
    zclca_llm_prompt_manager_util=>read_prompt(
      EXPORTING
        i_prompt_id   = s_prompt_id
        i_app_id      = s_app_id
        i_version     = s_version
      IMPORTING
        e_prompt_data = gs_prompt_data
    ).
    IF gs_prompt_data IS NOT INITIAL.
      CALL SCREEN 200.
    ELSE.
      MESSAGE 'No prompts found' TYPE 'S'.
    ENDIF.
  ENDMETHOD.
  METHOD handle_create.
    IF s_app_id IS INITIAL OR s_prompt_id IS INITIAL OR s_version IS INITIAL.
      MESSAGE 'Please fill mandatory fields' TYPE 'S'.
      RETURN.
    ENDIF.
    gv_action_type = 'C'.
    zclca_llm_prompt_manager_util=>read_prompt(
      EXPORTING
        i_prompt_id   = s_prompt_id
        i_app_id      = s_app_id
        i_version     = s_version
      IMPORTING
        e_prompt_data = gs_prompt_data
    ).
    IF gs_prompt_data IS NOT INITIAL.
      MESSAGE 'This prompt already exist cannot create new' TYPE 'S'.
    ELSE.
      CALL SCREEN 200.
    ENDIF.
  ENDMETHOD.
  METHOD handle_send.
    zclca_llm_prompt_manager_util=>read_prompt(
      EXPORTING
        i_prompt_id   = s_prompt_id
        i_app_id      = s_app_id
        i_version     = s_version
      IMPORTING
        e_prompt_data = gs_prompt_data
    ).
    IF gs_prompt_data IS INITIAL.
      MESSAGE 'Prompt version does not exist' TYPE 'S'.
      RETURN.
    ENDIF.
    CASE gs_prompt_data-status.
      WHEN 'DEPRECATED'.
        MESSAGE 'This prompt already exist cannot create new' TYPE 'S'.
      WHEN 'INREVIEW'.
        MESSAGE 'Already pending approval' TYPE 'S'.
      WHEN 'ACTIVE'.
        MESSAGE 'Prompt is already approved' TYPE 'S'.
      WHEN 'DRAFT'.
        gs_prompt_data-application_id = s_app_id.
        gs_prompt_data-prompt_id      = s_prompt_id.
        gs_prompt_data-version        = s_version.
        gs_prompt_data-status         = 'INREVIEW'.
        gs_prompt_data-changed_by     = sy-uname.
        gs_prompt_data-changed_on     = sy-datum.
        zclca_llm_prompt_manager_util=>update_prompt( i_prompt_data = gs_prompt_data ).
        MESSAGE 'Marked as In Review - Sent for Approval' TYPE 'S'.
    ENDCASE.
  ENDMETHOD.
  METHOD handle_approve.
    IF check_approval_auth( ) = abap_false.
      MESSAGE 'You are not authorized to approve' TYPE 'S'.
      RETURN.
    ENDIF.
    zclca_llm_prompt_manager_util=>read_prompt(
      EXPORTING
        i_prompt_id   = s_prompt_id
        i_app_id      = s_app_id
        i_version     = s_version
      IMPORTING
        e_prompt_data = gs_prompt_data
    ).
    IF gs_prompt_data IS INITIAL.
      MESSAGE 'Prompt version does not exist' TYPE 'S'.
      RETURN.
    ENDIF.
    CASE gs_prompt_data-status.
      WHEN 'ACTIVE'.
        MESSAGE 'Prompt is already approved' TYPE 'S'.
      WHEN 'DRAFT'.
        MESSAGE 'This prompt version is not ready for approval' TYPE 'S'.
      WHEN 'DEPRECATED'.
        MESSAGE 'This prompt version is deprecated cannot be approved' TYPE 'S'.
      WHEN 'INREVIEW'.
        gs_prompt_data-application_id = s_app_id.
        gs_prompt_data-prompt_id      = s_prompt_id.
        gs_prompt_data-version        = s_version.
        gs_prompt_data-status         = 'ACTIVE'.
        gs_prompt_data-changed_by     = sy-uname.
        gs_prompt_data-changed_on     = sy-datum.
        zclca_llm_prompt_manager_util=>approve_prompt( i_prompt_data = gs_prompt_data ).
        MESSAGE 'Approved ! - Marked as Active' TYPE 'S'.
    ENDCASE.
  ENDMETHOD.
  METHOD check_approval_auth.
    rv_authorized = zclca_llm_prompt_manager_util=>is_approval_auth_granted(
                      iv_app_id = s_app_id
                    ).
  ENDMETHOD.
  METHOD handle_copy.
    zclca_llm_prompt_manager_util=>read_prompt(
      EXPORTING
        i_prompt_id   = s_prompt_id
        i_app_id      = s_app_id
        i_version     = s_version
      IMPORTING
        e_prompt_data = gs_prompt_data
    ).
    IMPORT gt_prompttable TO gt_prompttable FROM DATABASE zcac_prompt_indx(pm)
      ID gs_prompt_data-prompt_idx_id.
    IF gt_prompttable IS NOT INITIAL.
      DATA(lv_prompt_idx_id_1) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
      EXPORT gt_prompttable FROM gt_prompttable TO DATABASE zcac_prompt_indx(pm)
        ID lv_prompt_idx_id_1.

      SELECT MAX( version )
        FROM zcac_prompt_data
        WHERE prompt_id      = @s_prompt_id
          AND application_id = @s_app_id
        INTO @DATA(lv_ver).
      IF sy-subrc = 0.
        gs_prompt_data-version = lv_ver + 1.
      ENDIF.

      gs_prompt_data-application_id = s_app_id.
      gs_prompt_data-prompt_id      = s_prompt_id.
      gs_prompt_data-description    = s_description.
      gs_prompt_data-prompt_idx_id  = lv_prompt_idx_id_1.
      gs_prompt_data-status         = text-003. "Assumed text symbol
      gs_prompt_data-created_by     = sy-uname.
      gs_prompt_data-created_on     = sy-datum.
      gs_prompt_data-changed_by     = sy-uname.
      gs_prompt_data-changed_on     = sy-datum.
      zclca_llm_prompt_manager_util=>create_prompt( i_prompt_data = gs_prompt_data ).
      MESSAGE | { text-002 } { gs_prompt_data-version } | TYPE 'S'.
      cl_gui_cfw=>flush( ).
    ENDIF.
  ENDMETHOD.
  METHOD on_pbo_0200.
    IF gv_action_type = 'C'.
      SET PF-STATUS 'ZSTATUS_200_C'.
    ELSE.
      IF gv_action_type = 'E'.
        IF gs_prompt_data-status = 'DRAFT' OR gs_prompt_data-status = 'INREVIEW'.
          SET PF-STATUS 'ZSTATUS_200'.
        ELSE.
          SET PF-STATUS 'ZSTATUS_200' EXCLUDING 'SAVE'.
        ENDIF.
      ENDIF.
    ENDIF.
    SET TITLEBAR 'Z200'.
    s_status      = gs_prompt_data-status.
    s_description = gs_prompt_data-description.
    TRY.
        IF gc_ccontroller IS NOT INITIAL.
          gc_ccontroller->free(
            EXCEPTIONS
              cntl_error        = 1
              cntl_system_error = 2
              OTHERS            = 3 ).
          IF sy-subrc <> 0.
            MESSAGE text-005 TYPE 'S'.
          ENDIF.
        ENDIF.
        gc_ccontroller = NEW #( container_name = 'CC_TEXTEDIT' ).
        go_rich_text_editor = NEW #(
          parent                     = gc_ccontroller
          wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
          wordwrap_to_linebreak_mode = cl_gui_textedit=>true
        ).
      CATCH cx_root.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDTRY.
    IF go_rich_text_editor IS BOUND.
      go_rich_text_editor->delete_text( ).
      cl_gui_cfw=>flush( ).
      go_rich_text_editor->set_toolbar_mode( toolbar_mode = 1 ).
      IF gv_action_type = 'E'.
        IF gs_prompt_data-status = 'DRAFT' OR gs_prompt_data-status = 'INREVIEW'.
          go_rich_text_editor->set_readonly_mode( readonly_mode = 0 ).
        ELSE.
          LOOP AT SCREEN.
            IF screen-name = 'S_DESCRIPTION'.
              screen-input = '0'.
              MODIFY SCREEN.
            ENDIF.
          ENDLOOP.
          go_rich_text_editor->set_readonly_mode( readonly_mode = 1 ).
        ENDIF.
        CLEAR gt_prompttable.
        IMPORT gt_prompttable TO gt_prompttable FROM DATABASE zcac_prompt_indx(pm)
          ID gs_prompt_data-prompt_idx_id.
        go_rich_text_editor->set_text_as_r3table( table = gt_prompttable ).
        cl_gui_cfw=>flush( ).
      ELSEIF gv_action_type = 'C'.
        CLEAR gt_prompttable.
        go_rich_text_editor->set_text_as_r3table( table = gt_prompttable ).
        go_rich_text_editor->set_readonly_mode( readonly_mode = 0 ).
      ENDIF.
    ENDIF.
  ENDMETHOD.
  METHOD on_pai_0200.
    CASE iv_ucomm.
      WHEN 'SAVE'.
        handle_save( ).
      WHEN 'BACK' OR 'CANC' OR 'EXIT'.
        IF iv_ucomm = 'EXIT'.
          LEAVE PROGRAM.
        ELSE.
          LEAVE TO SCREEN 0.
        ENDIF.
      WHEN 'DELETE'.
        handle_delete( ).
      WHEN text-004. "Assume this is 'COPY' based on original code context
        handle_copy( ).
        LEAVE TO SCREEN 0.
    ENDCASE.
  ENDMETHOD.
  METHOD handle_save.
    go_rich_text_editor->get_text_as_r3table( IMPORTING table = gt_prompttable ).
    IF gt_prompttable IS NOT INITIAL.
      DATA(lv_prompt_idx_id) = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
      EXPORT gt_prompttable FROM gt_prompttable TO DATABASE zcac_prompt_indx(pm)
        ID lv_prompt_idx_id.
      gs_prompt_data-application_id = s_app_id.
      gs_prompt_data-prompt_id      = s_prompt_id.
      gs_prompt_data-version        = s_version.
      gs_prompt_data-description    = s_description.
      gs_prompt_data-prompt_idx_id  = lv_prompt_idx_id.
      gs_prompt_data-status         = s_status.
      gs_prompt_data-created_by     = sy-uname.
      gs_prompt_data-created_on     = sy-datum.
      gs_prompt_data-changed_by     = sy-uname.
      gs_prompt_data-changed_on     = sy-datum.
      IF gs_prompt_data-status IS INITIAL.
        gs_prompt_data-status = 'DRAFT'.
        zclca_llm_prompt_manager_util=>create_prompt( i_prompt_data = gs_prompt_data ).
      ELSE.
        CASE gs_prompt_data-status.
          WHEN 'DRAFT' OR 'INREVIEW'.
            zclca_llm_prompt_manager_util=>update_prompt( i_prompt_data = gs_prompt_data ).
          WHEN 'ACTIVE'.
            MESSAGE 'Prompt cannot be updated its already Active' TYPE 'S'.
            RETURN.
          WHEN 'DEPRECATED'.
            MESSAGE 'Prompt is already deprecated' TYPE 'S'.
            RETURN.
        ENDCASE.
      ENDIF.
      MESSAGE 'Prompt created successfully' TYPE 'S'.
      LEAVE TO SCREEN 0.
    ELSE.
      MESSAGE 'Please enter prompt' TYPE 'S'.
    ENDIF.
  ENDMETHOD.
  METHOD handle_delete.
    IF gs_prompt_data-status = 'DEPRECATED'.
      MESSAGE 'Prompt is already deprecated' TYPE 'S'.
      LEAVE TO SCREEN 0.
    ENDIF.
    gs_prompt_data-application_id = s_app_id.
    gs_prompt_data-prompt_id      = s_prompt_id.
    gs_prompt_data-version        = s_version.
    gs_prompt_data-status         = 'DEPRECATED'.
    gs_prompt_data-changed_by     = sy-uname.
    gs_prompt_data-changed_on     = sy-datum.
    zclca_llm_prompt_manager_util=>update_prompt( i_prompt_data = gs_prompt_data ).
    MESSAGE 'Prompt marked as deprecated' TYPE 'S'.
    LEAVE TO SCREEN 0.
  ENDMETHOD.
  METHOD on_f4_help.
    DATA: lt_fieldtab        TYPE TABLE OF dfies,
          lt_returntab       TYPE TABLE OF ddshretval,
          lt_dynpfld         TYPE TABLE OF dselc,
          lt_dynpfields      TYPE TABLE OF dynpread,
          lt_dynpfields_read TYPE TABLE OF dynpread,
          lr_app_id          TYPE RANGE OF zca_application_id,
          lr_prmp_id         TYPE RANGE OF zca_prompt_id,
          lr_ver             TYPE RANGE OF zca_prompt_version.
    CONSTANTS: lc_s_app_id    TYPE dynfnam VALUE 'S_APP_ID',
               lc_s_prompt_id TYPE dynfnam VALUE 'S_PROMPT_ID',
               lc_s_version   TYPE dynfnam VALUE 'S_VERSION'.
    " Prepare fields to read
    lt_dynpfields_read = VALUE #(
      ( fieldname = lc_s_app_id )
      ( fieldname = lc_s_prompt_id )
      ( fieldname = lc_s_version )
    ).
    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname     = sy-repid
        dynumb     = sy-dynnr
      TABLES
        dynpfields = lt_dynpfields_read
      EXCEPTIONS
        OTHERS     = 1.
    IF sy-subrc <> 0.
      MESSAGE text-006 TYPE 'S'.
      RETURN.
    ENDIF.
    " Parse read values into Ranges
    LOOP AT lt_dynpfields_read INTO DATA(ls_read).
      IF ls_read-fieldvalue IS NOT INITIAL.
        CASE ls_read-fieldname.
          WHEN lc_s_app_id.
            lr_app_id = VALUE #( ( sign = 'I' option = 'EQ'
                                   low = to_upper( ls_read-fieldvalue ) ) ).
          WHEN lc_s_prompt_id.
            lr_prmp_id = VALUE #( ( sign = 'I' option = 'EQ'
                                    low = to_upper( ls_read-fieldvalue ) ) ).
          WHEN lc_s_version.
            lr_ver = VALUE #( ( sign = 'I' option = 'EQ'
                                low = ls_read-fieldvalue ) ).
        ENDCASE.
      ENDIF.
    ENDLOOP.
    " Set up mapping for F4 return
    lt_dynpfld = VALUE #(
      ( fldname = 'F0001' dyfldname = lc_s_app_id )
      ( fldname = 'F0002' dyfldname = lc_s_prompt_id )
      ( fldname = 'F0003' dyfldname = lc_s_version )
    ).
    " Fetch Data
    SELECT application_id, prompt_id, version, description, status
      FROM zcac_prompt_data
      WHERE application_id IN @lr_app_id
        AND prompt_id      IN @lr_prmp_id
        AND version        IN @lr_ver
      INTO TABLE @DATA(lt_prompt).
    IF lt_prompt IS INITIAL.
      MESSAGE text-001 TYPE 'S'.
      RETURN.
    ENDIF.
    " Call F4 Function
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
      EXPORTING
        retfield        = iv_retfield
        dynpprog        = sy-repid
        dynpnr          = sy-dynnr
        dynprofield     = iv_dynfield
        value_org       = 'S'
      TABLES
        value_tab       = lt_prompt
        field_tab       = lt_fieldtab
        return_tab      = lt_returntab
        dynpfld_mapping = lt_dynpfld
      EXCEPTIONS
        OTHERS          = 3.
    IF sy-subrc <> 0.
      MESSAGE text-001 TYPE 'S'.
    ELSE.
      " Update screen fields based on selection
      LOOP AT lt_returntab INTO DATA(ls_return).
        CONDENSE ls_return-fieldval.
        lt_dynpfields = VALUE #( BASE lt_dynpfields
          ( fieldname = ls_return-retfield fieldvalue = ls_return-fieldval )
        ).
      ENDLOOP.
      CALL FUNCTION 'DYNP_VALUES_UPDATE'
        EXPORTING
          dyname     = sy-repid
          dynumb     = sy-dynnr
        TABLES
          dynpfields = lt_dynpfields
        EXCEPTIONS
          OTHERS     = 0.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
