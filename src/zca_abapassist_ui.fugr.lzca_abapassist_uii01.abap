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
***INCLUDE LZCA_ABAPASSIST_UII01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'SELECTED'.
      zclca_abap_assist_ui=>get_instance( )->llm_model_reselected( CONV #( zcac_abapast_mdl-model_key ) ).
    WHEN OTHERS.
      zclca_abap_assist_ui=>get_instance( )->pai_of_screen_100( iv_ok_code = ok_code ).
  ENDCASE.
*
*  IF ok_code = 'SELECTED'.
*    DATA(lv_msg) = |Selected model is { ycac_abapast_mdl-model_name }|.
*    MESSAGE lv_msg TYPE 'I'.
*    lv_msg = |Selected model key is { ycac_abapast_mdl-model_key }|.
*    MESSAGE lv_msg TYPE 'I'.
*  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  FILL_MODEL_DROPDOWN  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE fill_model_dropdown INPUT.
  zclca_abap_assist_ui=>get_instance( )->fill_model_dropdown( ).
ENDMODULE.
