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
INTERFACE zifca_abap_assist_aiutil
  PUBLIC .


  TYPES:
    BEGIN OF ty_response,
      response   TYPE string,
      identifier TYPE string,
    END OF ty_response .
  TYPES gs_response TYPE ty_response .

  CONSTANTS:
    BEGIN OF gc_user_action_enum,
      enter   TYPE int1 VALUE 1,
      explain TYPE int1 VALUE 2,
    END OF gc_user_action_enum .

  METHODS execute_user_action
    IMPORTING
      !iv_prompt         TYPE string
      !iv_option         TYPE char20
      !iv_current_source TYPE string
      !iv_llm_model      TYPE zca_abap_assist_model_key
      !iv_convo_id       TYPE zcai_ai_convo_id OPTIONAL
      !is_trkey          TYPE trkey OPTIONAL
    RETURNING
      VALUE(rs_response) TYPE ty_response .
  METHODS fetch_llm_response
    IMPORTING
      !iv_prompt         TYPE string
      !iv_option         TYPE char20
      !iv_current_source TYPE string
      !iv_llm_model      TYPE zca_abap_assist_model_key
      !iv_convo_id       TYPE zcai_ai_convo_id OPTIONAL
    RETURNING
      VALUE(rs_response) TYPE ty_response .
ENDINTERFACE.
