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
INTERFACE zifca_llm_prompt_manager
  PUBLIC .


  TYPES:
    BEGIN OF ty_gs_data_key,
      name  TYPE string,
      value TYPE string,
    END   OF ty_gs_data_key .
  TYPES:
    ty_gt_data_key TYPE STANDARD TABLE OF ty_gs_data_key WITH EMPTY KEY .
  TYPES:
    BEGIN OF gty_s_prompt_input,
      application_id TYPE zcac_prompt-application_id,
      prompt_id      TYPE zcac_prompt-prompt_id,
      version        TYPE zcac_prompt-version,
    END OF gty_s_prompt_input .
  TYPES:
    BEGIN OF gty_s_prompt_output,
      application_id TYPE zcac_prompt-application_id,
      prompt_id      TYPE zcac_prompt-prompt_id,
      version        TYPE zcac_prompt-version,
      description    TYPE zcac_prompt-description,
      status         TYPE zcac_prompt-status,
      prompt_text    TYPE string,
    END OF gty_s_prompt_output .
  TYPES:
    gty_t_prompt_output TYPE STANDARD TABLE OF gty_s_prompt_output WITH DEFAULT KEY .
  TYPES gty_s_prompt_data TYPE zcac_prompt_data .
  TYPES:
    gty_t_prompt_data TYPE STANDARD TABLE OF gty_s_prompt_data WITH DEFAULT KEY .

  METHODS read_prompt
    IMPORTING
      !is_prompt_input        TYPE gty_s_prompt_input
      !it_data_key            TYPE ty_gt_data_key OPTIONAL
    RETURNING
      VALUE(rs_prompt_output) TYPE gty_s_prompt_output
    RAISING
      zcxca_llm_prompt_manager .
ENDINTERFACE.
