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
CLASS zclca_llm_prompt_manager_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_prompt_line,
        line(256) TYPE c,
      END OF ty_prompt_line .
    TYPES ty_zcac_prompt_data TYPE zcac_prompt_data .
    TYPES:
      ty_t_prompt_lines TYPE TABLE OF ty_prompt_line WITH DEFAULT KEY .

    CLASS-METHODS create_prompt
      IMPORTING
        !i_prompt_data TYPE ty_zcac_prompt_data .
    CLASS-METHODS read_prompt
      IMPORTING
        !i_prompt_id   TYPE zca_prompt_id
        !i_app_id      TYPE zca_application_id
        !i_version     TYPE zca_prompt_version
      EXPORTING
        !e_prompt_data TYPE ty_zcac_prompt_data .
    CLASS-METHODS update_prompt
      IMPORTING
        !i_prompt_data TYPE ty_zcac_prompt_data .
    CLASS-METHODS delete_prompt
      IMPORTING
        !i_prompt_data TYPE ty_zcac_prompt_data .
    CLASS-METHODS is_approval_auth_granted
      IMPORTING
        !iv_app_id                      TYPE zca_application_id
      RETURNING
        VALUE(rv_approval_auth_granted) TYPE abap_bool .
    CLASS-METHODS approve_prompt
      IMPORTING
        !i_prompt_data TYPE ty_zcac_prompt_data .
    CLASS-METHODS read_prompt_text
      IMPORTING
        !iv_id_indx            TYPE indx_srtfd
      RETURNING
        VALUE(rt_prompt_lines) TYPE ty_t_prompt_lines .
    CLASS-METHODS deprecate_while_approve_prompt
      IMPORTING
        !i_prompt_data TYPE ty_zcac_prompt_data .
PROTECTED SECTION.
PRIVATE SECTION.
ENDCLASS.



CLASS ZCLCA_LLM_PROMPT_MANAGER_UTIL IMPLEMENTATION.


  METHOD approve_prompt.
**********************************************************************
* Change History:
* Date        Author               Description
* 11/07/2025  Siddharth(1640987)   V2 - TR ED4K996415 Added deprecating functionality
**********************************************************************
    DATA: ls_prompt_data TYPE ty_zcac_prompt_data.

    TRY.
        zclca_llm_prompt_manager_util=>deprecate_while_approve_prompt(
          i_prompt_data = i_prompt_data ).

        ls_prompt_data = i_prompt_data.
        ls_prompt_data-approved_by = sy-uname.
        ls_prompt_data-approved_on = sy-datum.
        UPDATE zcac_prompt_data FROM ls_prompt_data.
        COMMIT WORK.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD create_prompt.
    TRY.
        INSERT zcac_prompt_data FROM i_prompt_data.
        COMMIT WORK AND WAIT.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD delete_prompt.
    TRY.
        DELETE zcac_prompt_data FROM i_prompt_data.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.


  METHOD deprecate_while_approve_prompt.
**********************************************************************
* Method Name: DEPRECATE_WHILE_APPROVE_PROMPT
* Description: Method to deprecate active status prompt upon approving
*              new Active status
* Author:      Siddharth Das (16409987)
* Created On:  11/07/2025
**********************************************************************


    CONSTANTS : lc_active TYPE char10 VALUE 'ACTIVE',
                lc_dep    TYPE char12 VALUE 'DEPRECATED'.

    DATA: ls_prompt_data TYPE ty_zcac_prompt_data.

*** Fetching details of previously Active prompt and deprecating it.
    TRY.
        SELECT SINGLE *
          FROM zcac_prompt_data
          WHERE application_id = @i_prompt_data-application_id
          AND prompt_id = @i_prompt_data-prompt_id
          AND status = @lc_active
          INTO @DATA(ls_act_prompt).

        IF sy-subrc = 0.

          ls_prompt_data-application_id = ls_act_prompt-application_id.
          ls_prompt_data-prompt_id = ls_act_prompt-prompt_id.
          ls_prompt_data-version = ls_act_prompt-version.
          ls_prompt_data-status = lc_dep.
          ls_prompt_data-prompt_idx_id = ls_act_prompt-prompt_idx_id.
          ls_prompt_data-description = ls_act_prompt-description.
          ls_prompt_data-created_by = ls_act_prompt-created_by.
          ls_prompt_data-created_on = ls_act_prompt-created_on.
          ls_prompt_data-changed_by = sy-uname.
          ls_prompt_data-changed_on = sy-datum.
          zclca_llm_prompt_manager_util=>update_prompt( i_prompt_data = ls_prompt_data ).

        ENDIF.
      CATCH cx_root.
    ENDTRY.

  ENDMETHOD.


  METHOD is_approval_auth_granted.
    SELECT SINGLE *
      FROM zcac_prompt_appr
      INTO @DATA(ls_approver)
     WHERE application_id = @iv_app_id AND
           approverid = @sy-uname.

    IF ls_approver IS NOT INITIAL.
      rv_approval_auth_granted = abap_true.
    ELSE.
      rv_approval_auth_granted = abap_false.
    ENDIF.
  ENDMETHOD.


  METHOD read_prompt.
    SELECT SINGLE *
      FROM zcac_prompt_data
      INTO e_prompt_data
      WHERE application_id = i_app_id AND
             prompt_id = i_prompt_id AND
            version = i_version.
    IF sy-subrc <> 0.
    ENDIF.

  ENDMETHOD.


  METHOD read_prompt_text.

    TYPES: BEGIN OF prompt_line,
             line(256) TYPE c,
           END OF prompt_line.

    DATA gt_prompttable TYPE TABLE OF prompt_line.

    IMPORT gt_prompttable = gt_prompttable FROM DATABASE zcac_prompt_indx(pm) ID iv_id_indx.
    rt_prompt_lines = gt_prompttable.

  ENDMETHOD.


  METHOD update_prompt.
    TRY.
        UPDATE zcac_prompt_data FROM i_prompt_data.
        COMMIT WORK.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
