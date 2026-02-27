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
*& Include          ZECA_GENIE_CONTEXT_MENU
*&---------------------------------------------------------------------*

DATA: lt_function TYPE ui_functions.
DATA: ls_entry TYPE sctx_entry.

IF NOT line_exists( entrytab[ text = zif_ai_assist_enhancement=>gc_ai_assist ] ) .
  DATA(lo_menu_sub) = zclca_ai_assistant_enhancement=>get_instance( )->enhance_right_click(
                        EXPORTING
                          it_entrytab = entrytab ).
  IF lo_menu_sub IS BOUND.
    ls_entry-type = sctx_c_type_submenu.
    ls_entry-menu = lo_menu_sub.
    ls_entry-text = zif_ai_assist_enhancement=>gc_ai_assist.

    SET HANDLER on_submenu_changed FOR lo_menu_sub.
    APPEND ls_entry TO entrytab.
    RAISE EVENT changed.

    CALL METHOD add_separator.
  ENDIF.

ENDIF.
