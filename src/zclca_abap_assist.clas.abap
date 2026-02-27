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
class ZCLCA_ABAP_ASSIST definition
  public
  final
  create public .

public section.

  methods AI_ASSISTANCE
    importing
      !IV_FCODE type SY-UCOMM optional
      !IV_DISPLAYMODE type CHAR1 optional
      !IT_SOURCE_CODE type RSWSOURCET optional
      !IV_FULLSCREEN type BOOLEAN optional
      !IS_TRKEY type TRKEY optional
      !IO_EDITOR_HANDLE type ref to CL_WB_EDITOR optional .
protected section.
private section.
ENDCLASS.



CLASS ZCLCA_ABAP_ASSIST IMPLEMENTATION.


  METHOD ai_assistance.

    NEW zclca_abap_assist_ui( )->zifca_abap_assist_ui~show_codegen_dialog(
      EXPORTING
        iv_fcode       = iv_fcode
        iv_displaymode = iv_displaymode
        it_source_code = it_source_code
        iv_fullscreen = iv_fullscreen
        is_trkey = is_trkey
        io_editor_handle = io_editor_handle ).

  ENDMETHOD.
ENDCLASS.
