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
*----------------------------------------------------------------------*
***INCLUDE LZCA_ABAPASSIST_UIO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET TITLEBAR 'ACT'.
  SET PF-STATUS 'MAIN_STATUS'.
  gv_disclaimer = TEXT-001.
  zclca_abap_assist_ui=>get_instance( )->pbo_of_screen_100( ).
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module SET_DEFAULT_MODEL_ONCE OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE set_default_model_once OUTPUT.
  IF gv_first_time = abap_true.
*    ycac_abapast_mdl-model_key = 'models/gemini-1.5-flash'.
*    ycac_abapast_mdl-model_name = 'Gemini 1.5 Flash'.
    SELECT SINGLE model_key, model_name FROM zcac_abapast_mdl INTO ( @zcac_abapast_mdl-model_key, @zcac_abapast_mdl-model_name ).
    zclca_abap_assist_ui=>get_instance( )->llm_model_reselected( iv_model_key = zcac_abapast_mdl-model_key ).
    zclca_abap_assist_ui=>get_instance( )->fill_model_dropdown( ).
    gv_first_time = abap_false.
  ENDIF.
ENDMODULE.
