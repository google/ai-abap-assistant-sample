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
interface ZIF_AI_ASSIST_ENHANCEMENT
  public .


  constants:
    BEGIN OF gc_feature,
      code_explain TYPE ui_func VALUE 'G_EXPLAIN',
      code_review  TYPE ui_func VALUE 'G_REVIEW',
      code_assist  TYPE ui_func VALUE 'G_SUGGEST',
      aut_assist   TYPE ui_func VALUE 'G_AUT',
      translate    TYPE ui_func VALUE 'G_TRANSLAT',
      testcase     TYPE ui_func VALUE 'G_TESTCASE',
      codegen      TYPE ui_func VALUE 'CODEGEN',
      codegen_d    TYPE ui_func VALUE 'CODEGEN_D',
    END OF gc_feature .
  constants GC_AI_ASSIST type GUI_TEXT value 'AI ABAP Assistant' ##NO_TEXT.
  constants GC_PROGRAM type PROGRAM value 'ZR_AI_ABAP_ASSIST_CONTEXT_MENU' ##NO_TEXT.
  constants GC_STATUS type CUA_STATUS value 'WB_CONTEXT_SUBMENU' ##NO_TEXT.
  constants:
    BEGIN OF gc_trigger,
      abap_editor        TYPE char15 VALUE 'ABAP_EDITOR',
      debugger           TYPE char15 VALUE 'DEBUGGER',
      debugger_program   TYPE string VALUE 'CL_TPDA_TOOL_EDITOR_AB4=======CP->HANDLE_CONTEXT_MENU',
      toolbar_init       TYPE string VALUE 'CL_SALV_GUI_FUNCTION_BUILDER==CP->INIT_CONTEXT_MENU',
      toolbar_build      TYPE string VALUE 'CL_SALV_GUI_FUNCTION_BUILDER==CP->TOOLBAR_BUILD',
      editor_context     TYPE string VALUE 'CL_WB_EDITOR==================CP->ON_HANDLER_CONTEXT_MENU',
      editor_context2    TYPE string VALUE 'CL_SEDI_ABS_CTRL_EVENT_HANDLERCP->ON_HANDLER_CONTEXT_MENU',
      gui_create_context TYPE string VALUE 'CL_SALV_GUI_FUNCTION_BUILDER==CP->CREATE_CONTEXT_MENU',
      atc_calc_ctmenu    TYPE string VALUE 'SAPLSATC_AC__UI_RESULT_DISPL->CALCULATE_CTMENU',
      atc_result_disp    TYPE string VALUE 'SAPLSATC_AC__UI_RESULT_DISPL',
    END OF gc_trigger .

  methods BREAKPOINT .
  methods ENHANCE_RIGHT_CLICK
    importing
      !IT_ENTRYTAB type SCTX_ENTRYTAB optional
    returning
      value(RO_MENU_SUB) type ref to CL_CTMENU .
endinterface.
