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
CLASS zclca_ai_assistant_enhancement DEFINITION
  PUBLIC
  FINAL
  CREATE PRIVATE .

  PUBLIC SECTION.

    INTERFACES zif_ai_assist_enhancement .

    ALIASES breakpoint
      FOR zif_ai_assist_enhancement~breakpoint .
    ALIASES enhance_right_click
      FOR zif_ai_assist_enhancement~enhance_right_click .

    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO zif_ai_assist_enhancement .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CLASS-DATA go_instance TYPE REF TO zif_ai_assist_enhancement .


    METHODS get_calling_program
      EXPORTING
        VALUE(ev_block) TYPE string
        !et_callstack   TYPE abap_callstack .
ENDCLASS.



CLASS ZCLCA_AI_ASSISTANT_ENHANCEMENT IMPLEMENTATION.


  METHOD get_calling_program.

    CLEAR: et_callstack, ev_block.

    CALL FUNCTION 'SYSTEM_CALLSTACK'
      EXPORTING
        max_level = 50
      IMPORTING
        callstack = et_callstack.

    TRY.
        DATA(lr_callstack) = REF #( et_callstack[ 4 ] ).

        CASE lr_callstack->blocktype.
          WHEN 'FUNCTION'.
            ev_block = lr_callstack->blockname.
          WHEN 'METHOD'.
            ev_block = |{ lr_callstack->mainprogram }->{ lr_callstack->blockname }|.
          WHEN 'MODULE (PBO)'.
            ev_block = lr_callstack->mainprogram.
          WHEN 'MODULE (PAI)'.
            ev_block = lr_callstack->mainprogram.
          WHEN OTHERS.
            ev_block = lr_callstack->mainprogram.
        ENDCASE.
      CATCH cx_sy_itab_line_not_found.
        ev_block = 'Not found'.
    ENDTRY.

  ENDMETHOD.


  METHOD get_instance.

    IF NOT go_instance IS BOUND.
      go_instance = NEW zclca_ai_assistant_enhancement( ).
    ENDIF.

    ro_instance = go_instance.

  ENDMETHOD.


  METHOD zif_ai_assist_enhancement~breakpoint.

    SELECT SINGLE low FROM tvarvc
      INTO @DATA(lfl_bp_enabled)
      WHERE name = 'GENIE_BREAKPOINT'
        AND low  = @sy-uname.
    IF sy-subrc = 0.
      BREAK-POINT.
    ENDIF.

  ENDMETHOD.


  METHOD zif_ai_assist_enhancement~enhance_right_click.

    CONSTANTS: lc_evt_context_menu_9 TYPE i VALUE 9,
               lc_evt_context_menu_5 TYPE i VALUE 5.
    DATA: lt_function_to_hide TYPE ui_functions.

    breakpoint( ).

    SELECT SINGLE cccategory FROM t000
      INTO @DATA(lv_client_role)
      WHERE mandt = @sy-mandt.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    " Genie features are not relevant for the Production, and SAP systems.
    IF lv_client_role = 'P'
    OR lv_client_role = 'S'.
      RETURN.
    ENDIF.

    IF  sy-tcode <> 'SE24'
    AND sy-tcode <> 'SE37'
    AND sy-tcode <> 'SE38'
    AND sy-tcode <> 'SESSION_MANAGER'         " Debugger
    AND sy-tcode <> 'TPDA_CALL_EDITOR'        " Module pool
    AND sy-tcode <> 'SEU_INT'.
      RETURN.
    ENDIF.

    get_calling_program(
      IMPORTING
        ev_block     = DATA(lv_block)
        et_callstack = DATA(lt_callstack) ).

    " Ensures that the menu option get added only on the editor
    IF ( sy-tcode = 'SE24'
      OR sy-tcode = 'SE37'
      OR sy-tcode = 'SE38'
      OR sy-tcode = 'SEU_INT' )
   AND ( lv_block <> zif_ai_assist_enhancement=>gc_trigger-editor_context
     AND lv_block <> zif_ai_assist_enhancement=>gc_trigger-editor_context2
     AND lv_block <> zif_ai_assist_enhancement=>gc_trigger-atc_calc_ctmenu
     AND lv_block <> zif_ai_assist_enhancement=>gc_trigger-atc_result_disp ).
      RETURN.
    ENDIF.

    " To avoid adding the AI option in the toolbar options.
    IF lv_block = zif_ai_assist_enhancement=>gc_trigger-toolbar_init
    OR lv_block = zif_ai_assist_enhancement=>gc_trigger-toolbar_build.
      RETURN.
    ENDIF.

    IF sy-tcode = 'SESSION_MANAGER'.     "Debugger
      " Logic copied from standard class CL_GUI_CFW->DISPATCH_SYSTEM_EVENTS
      ASSIGN ('(SAPMSSYD)MY_UCOMM') TO FIELD-SYMBOL(<lv_ok_code>).
      IF sy-subrc = 0.
        IF <lv_ok_code>+0(4) = '%_GC'.
          REPLACE '%_GC' IN <lv_ok_code> WITH ''.
          CONDENSE <lv_ok_code>.
          SPLIT <lv_ok_code> AT ' ' INTO DATA(lv_f1) DATA(lv_f2) DATA(lv_f3).
        ENDIF.

        IF lv_f2 <> lc_evt_context_menu_9 AND lv_f2 <> lc_evt_context_menu_5.
          RETURN.
        ENDIF.
      ENDIF.
    ENDIF.

    IF lv_block = zif_ai_assist_enhancement=>gc_trigger-debugger_program.
      APPEND zif_ai_assist_enhancement=>gc_feature-aut_assist TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-code_assist TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-code_review TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-testcase TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-codegen TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-codegen_d TO lt_function_to_hide.
    ENDIF.

    IF lv_client_role = 'T'
    AND lv_block <> zif_ai_assist_enhancement=>gc_trigger-debugger_program.
      APPEND zif_ai_assist_enhancement=>gc_feature-aut_assist TO lt_function_to_hide.
      APPEND zif_ai_assist_enhancement=>gc_feature-code_assist TO lt_function_to_hide.
    ENDIF.

    CREATE OBJECT ro_menu_sub.
    cl_ctmenu=>load_gui_status(
      EXPORTING
        program = zif_ai_assist_enhancement=>gc_program
        status  = zif_ai_assist_enhancement=>gc_status
        disable = lt_function_to_hide
        menu    = ro_menu_sub
      EXCEPTIONS
        OTHERS  = 0 ).

    IF lt_function_to_hide IS NOT INITIAL.
      ro_menu_sub->hide_functions( fcodes = lt_function_to_hide ).
    ENDIF.

  ENDMETHOD.
ENDCLASS.
