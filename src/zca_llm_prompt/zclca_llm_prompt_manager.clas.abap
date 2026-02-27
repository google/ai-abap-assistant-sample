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
CLASS zclca_llm_prompt_manager DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zifca_llm_prompt_manager .

    ALIASES read_prompt
      FOR zifca_llm_prompt_manager~read_prompt .
    ALIASES gty_s_prompt_data
      FOR zifca_llm_prompt_manager~gty_s_prompt_data .
    ALIASES gty_s_prompt_input
      FOR zifca_llm_prompt_manager~gty_s_prompt_input .
    ALIASES gty_s_prompt_output
      FOR zifca_llm_prompt_manager~gty_s_prompt_output .
    ALIASES gty_t_prompt_data
      FOR zifca_llm_prompt_manager~gty_t_prompt_data .
    ALIASES gty_t_prompt_output
      FOR zifca_llm_prompt_manager~gty_t_prompt_output .

    DATA gc_active TYPE zca_prompt_status VALUE 'ACTIVE' ##NO_TEXT.
    DATA gt_data_key TYPE zifca_llm_prompt_manager=>ty_gt_data_key .

    METHODS replace_placeholder
      IMPORTING
        !iv_replace_string TYPE string
        !it_data_key       TYPE zifca_llm_prompt_manager=>ty_gt_data_key OPTIONAL
      RETURNING
        VALUE(rv_result)   TYPE string .
PROTECTED SECTION.
PRIVATE SECTION.

  METHODS read_prompt_data
    IMPORTING
      !is_prompt_input TYPE gty_s_prompt_input
    RETURNING
      VALUE(rs_prompt) TYPE gty_s_prompt_data
    RAISING
      zcxca_llm_prompt_manager .
  METHODS read_prompt_template
    IMPORTING
      !iv_indx_id           TYPE indx_srtfd
      !it_data_key          TYPE zifca_llm_prompt_manager=>ty_gt_data_key
    RETURNING
      VALUE(rv_prompt_text) TYPE string
    RAISING
      resumable(zcxca_llm_prompt_manager) .
ENDCLASS.



CLASS ZCLCA_LLM_PROMPT_MANAGER IMPLEMENTATION.


  METHOD read_prompt_data.

    IF is_prompt_input-application_id IS INITIAL OR
       is_prompt_input-prompt_id IS INITIAL.
      "Raise Exception if no record found in DB
      " RAISE EXCEPTION TYPE zcxca_llm_prompt_manager MESSAGE e002(zca_llm_prompt).
    ENDIF.

    "Read DB table zcac_prompt
    SELECT SINGLE *
     FROM zcac_prompt_data
    WHERE application_id = @is_prompt_input-application_id
      AND prompt_id      = @is_prompt_input-prompt_id
      AND version        = ( SELECT MAX( version )
                               FROM zcac_prompt_data
                              WHERE application_id = @is_prompt_input-application_id
                                AND prompt_id      = @is_prompt_input-prompt_id
                                AND status         = @gc_active )
      AND status         = @gc_active
    INTO @rs_prompt.
    IF sy-subrc <> 0.
      "Raise Exception if no record found in DB
      RAISE EXCEPTION TYPE zcxca_llm_prompt_manager.
      MESSAGE e001(zca_llm_prompt) WITH 'ZCAC_PROMPT' 'ZLLM_PROMPT_MANAGER'.
    ENDIF.

  ENDMETHOD.


  METHOD read_prompt_template.

    DATA: lv_prompt_text TYPE string.
    TYPES: BEGIN OF ty_prompt_line,
             line(256) TYPE c,
           END OF ty_prompt_line .
    TYPES: ty_t_prompt_lines TYPE TABLE OF ty_prompt_line WITH DEFAULT KEY.
    DATA: lt_prompt_lines TYPE ty_t_prompt_lines.

    TRY.
        lt_prompt_lines = zclca_llm_prompt_manager_util=>read_prompt_text(
                            iv_id_indx = iv_indx_id ).
        LOOP AT lt_prompt_lines INTO DATA(ls_lines).
          CONCATENATE lv_prompt_text ls_lines INTO lv_prompt_text
            SEPARATED BY cl_abap_char_utilities=>cr_lf.
        ENDLOOP.

        rv_prompt_text = replace_placeholder(
                           iv_replace_string = lv_prompt_text
                           it_data_key = it_data_key ).

      CATCH cx_root INTO DATA(lo_excep).
        RAISE RESUMABLE EXCEPTION TYPE zcxca_llm_prompt_manager.
    ENDTRY.

  ENDMETHOD.


  METHOD replace_placeholder.

    rv_result = iv_replace_string.

    "Global data could have been built using set methods, so always append to existing.
    IF it_data_key IS NOT INITIAL.
      APPEND LINES OF it_data_key TO gt_data_key.
    ENDIF.

    LOOP AT gt_data_key INTO DATA(ls_data_key).
      REPLACE ALL OCCURRENCES OF ls_data_key-name IN rv_result WITH ls_data_key-value.
    ENDLOOP.

  ENDMETHOD.


  METHOD zifca_llm_prompt_manager~read_prompt.
    DATA: ls_prompt TYPE gty_s_prompt_data.
    "Get the LLM template id from LLM config data
    ls_prompt = read_prompt_data( is_prompt_input = is_prompt_input ).

    "Get the LLM template data
    DATA(lv_prompt_string) = read_prompt_template(
                                  EXPORTING iv_indx_id = ls_prompt-prompt_idx_id
                                            it_data_key = it_data_key ).

    rs_prompt_output-application_id = ls_prompt-application_id.
    rs_prompt_output-prompt_id = ls_prompt-prompt_id.
    rs_prompt_output-version = ls_prompt-version.
    rs_prompt_output-description = ls_prompt-description.
    rs_prompt_output-status = ls_prompt-status.
    rs_prompt_output-prompt_text = lv_prompt_string.
  ENDMETHOD.
ENDCLASS.
