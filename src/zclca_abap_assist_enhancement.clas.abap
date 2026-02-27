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
CLASS zclca_abap_assist_enhancement DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_sedi_context_menu_extension .

    DATA go_obj TYPE REF TO cl_wb_pgeditor .
    CONSTANTS:
      BEGIN OF gc_fcodes,
        explain   TYPE sy-ucomm VALUE 'G_EXPLAIN',
        explain_d TYPE sy-ucomm VALUE 'EXPLAIN_D',
        codegen   TYPE sy-ucomm VALUE 'CODEGEN',
        codegen_d TYPE sy-ucomm VALUE 'CODEGEN_D',
        review    TYPE sy-ucomm VALUE 'G_REVIEW',
        suggest   TYPE sy-ucomm VALUE 'G_SUGGEST',
        aut       TYPE sy-ucomm VALUE 'G_AUT',
        translate TYPE sy-ucomm VALUE 'G_TRANSLAT',
      END OF gc_fcodes .

    METHODS abap_assist_context_menu
      IMPORTING
        !iv_menu_type TYPE char01
      CHANGING
        !ct_entry_tab TYPE sctx_entrytab .
protected section.
private section.

  methods GET_CURRENT_EDITOR
    returning
      value(RO_PGEDITOR) type ref to CL_WB_PGEDITOR .
  methods IS_ABAP_EDITOR
    returning
      value(RV_RESULT) type BOOLEAN .
ENDCLASS.



CLASS ZCLCA_ABAP_ASSIST_ENHANCEMENT IMPLEMENTATION.


  METHOD abap_assist_context_menu.
    DATA: lo_cmenu          TYPE REF TO cl_ctmenu,
          ls_menu           TYPE sctx_entry,
          lo_menu           TYPE REF TO cl_ctmenu,
          lt_disable_fcodes TYPE ui_functions.

      CASE iv_menu_type.
        WHEN sctx_c_type_submenu.
          ls_menu-type = sctx_c_type_function.
          ls_menu-text = 'ABAP Assistant'.
          ls_menu-fcode = gc_fcodes-codegen.

          IF NOT line_exists( ct_entry_tab[ text = 'ABAP Assistant' ] ).
            INSERT ls_menu INTO ct_entry_tab INDEX 1.
          ENDIF.

          INSERT VALUE #( type = sctx_c_type_separator ) INTO ct_entry_tab INDEX 2.
      ENDCASE.
  ENDMETHOD.


  METHOD get_current_editor.
    CONSTANTS:  lc_editor TYPE string VALUE '(SAPLS38E)abap_pgeditor'.

    IF go_obj IS NOT BOUND.
      ASSIGN (lc_editor) TO FIELD-SYMBOL(<ls_editor>).
      IF <ls_editor> IS ASSIGNED.
        go_obj ?= <ls_editor>.
      ENDIF.
    ENDIF.

    ro_pgeditor = go_obj.
  ENDMETHOD.


  METHOD if_sedi_context_menu_extension~execute_function.


    DATA: lo_event         TYPE REF TO cl_gui_event,
          lt_selected_code TYPE  sedi_source.

    lo_event ?= i_gui_control->cur_event.

    IF i_gui_control->www_active = abap_true.
      MESSAGE i002(zca_abap_assist).
      RETURN.
    ENDIF.

    IF lo_event IS BOUND.
      lo_event->get_event_param(
        EXPORTING
          pid   = 0
        IMPORTING
          value = DATA(lv_fcode) ).
    ENDIF.

    IF i_editor_handle IS BOUND.
      i_editor_handle->get_editor_mode(
        IMPORTING
          mode = DATA(ls_mode) ).
    ENDIF.

    CASE  lv_fcode.
      WHEN gc_fcodes-codegen
        OR gc_fcodes-explain
        OR gc_fcodes-review
        OR gc_fcodes-suggest
        OR gc_fcodes-aut
        OR gc_fcodes-translate.

        IF i_line_from = i_line_to.
          APPEND LINES OF i_source TO lt_selected_code.
        ELSE.
          APPEND LINES OF i_source FROM i_line_from TO i_line_to TO lt_selected_code.
        ENDIF.

        NEW zclca_abap_assist( )->ai_assistance( iv_fcode = CONV #( lv_fcode )
                                                   iv_displaymode = ls_mode-displaymod
                                                   it_source_code = lt_selected_code
                                                   is_trkey = i_trkey
                                                   io_editor_handle = i_editor_handle ).
      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.


  METHOD if_sedi_context_menu_extension~keep_focus.
  ENDMETHOD.


  METHOD is_abap_editor.

    rv_result = abap_true.

    IF  sy-tcode <> 'SE24'
      AND sy-tcode <> 'SE37'
      AND sy-tcode <> 'SE38'
      AND sy-tcode <> 'SE80'
      AND sy-tcode <> 'SESSION_MANAGER'         " Debugger
      AND sy-tcode <> 'TPDA_CALL_EDITOR'
      AND sy-tcode <> 'SEU_INT'.       " Module pool
      rv_result = abap_false.
    ENDIF.

    " @TODO Add checked on calling program that need to ignore by lookup stack.

  ENDMETHOD.
ENDCLASS.
