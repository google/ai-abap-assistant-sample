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
CLASS zclca_abap_assist_aiutil DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES zifca_abap_assist_aiutil .

    TYPES:
      BEGIN OF ty_cache_conv,
        request  TYPE string,
        response TYPE string,
      END OF ty_cache_conv .
    TYPES:
      ty_t_cache_conv TYPE STANDARD TABLE OF ty_cache_conv .

    CLASS-DATA gt_cache_conv TYPE ty_t_cache_conv .

    METHODS constructor .
    METHODS get_prompt
      IMPORTING
        !is_prompt_input TYPE zclca_llm_prompt_manager=>gty_s_prompt_input
        !it_data_key     TYPE zifca_llm_prompt_manager=>ty_gt_data_key
      RETURNING
        VALUE(rv_prompt) TYPE string
      RAISING
        zcxca_llm_prompt_manager .
    METHODS call_llm
      IMPORTING
        !iv_prompt         TYPE string
        !iv_option         TYPE char20
        !iv_current_source TYPE string
        !is_input          TYPE /goog/cl_aiplatform_v1=>ty_726
        !iv_llm_model      TYPE zca_abap_assist_model_key OPTIONAL
      RETURNING
        VALUE(rs_response) TYPE zifca_abap_assist_aiutil=>ty_response .
  PROTECTED SECTION.
  PRIVATE SECTION.

    CONSTANTS gc_llm_app_id TYPE zca_application_id VALUE 'ZAA' ##NO_TEXT.
    CONSTANTS gc_llm_metadata_prompt_id TYPE zca_prompt_id VALUE 'METADATA_PARSER' ##NO_TEXT.
    CONSTANTS gc_llm_content_prompt_id TYPE zca_prompt_id VALUE 'CONTENT_ASSIST' ##NO_TEXT.
    CONSTANTS gc_llm_content_refactor_id TYPE zca_prompt_id VALUE 'CONTENT_REFACTOR' ##NO_TEXT.
    CONSTANTS gc_sql_codeblock_identifier TYPE char6 VALUE '```sql' ##NO_TEXT.
    CONSTANTS gc_abap_codeblock_identifier TYPE char7 VALUE '```abap' ##NO_TEXT.
    CONSTANTS gc_chatbot_prompt_id TYPE zca_prompt_id VALUE 'CODE_GEN' ##NO_TEXT.
    CONSTANTS gc_explain_prompt_id TYPE zca_prompt_id VALUE 'EXPLANATION' ##NO_TEXT.
    CONSTANTS gc_aut_prompt_id TYPE zca_prompt_id VALUE 'UNIT_TEST' ##NO_TEXT.
    CONSTANTS gc_review_prompt_id TYPE zca_prompt_id VALUE 'CODE_REVIEW' ##NO_TEXT.
    CONSTANTS gc_suggest_prompt_id TYPE zca_prompt_id VALUE 'CODE_SUGGEST' ##NO_TEXT.
    CONSTANTS gc_translate_prompt_id TYPE zca_prompt_id VALUE 'TRANSLATE' ##NO_TEXT.

    METHODS preprocessing
      IMPORTING
        !iv_user_prompt           TYPE string
        !iv_option                TYPE char20
        !iv_additional_context    TYPE string
      RETURNING
        VALUE(rv_modified_prompt) TYPE string .
    METHODS response_post_processing
      CHANGING
        VALUE(cs_response) TYPE string .
    METHODS sql_codeblock_post_processing
      CHANGING
        !cs_response TYPE string .
    METHODS is_package_whitelisted
      IMPORTING
        !is_trkey                     TYPE trkey
      RETURNING
        VALUE(rv_package_whitelisted) TYPE flag .
ENDCLASS.



CLASS ZCLCA_ABAP_ASSIST_AIUTIL IMPLEMENTATION.


  METHOD call_llm.
    DATA: lo_aiclient TYPE REF TO /goog/cl_aiplatform_v1.
    DATA:
      lv_p_projects_id   TYPE string,
      lv_p_locations_id  TYPE string,
      lv_p_publishers_id TYPE string,
      lv_p_models_id     TYPE string,
      ls_input           TYPE /goog/cl_aiplatform_v1=>ty_726,
      ls_output          TYPE /goog/cl_aiplatform_v1=>ty_727,
      lv_ret_code        TYPE i,
      lv_err_text        TYPE string,
      ls_err_resp        TYPE /goog/err_resp,
      ls_part            TYPE /goog/cl_aiplatform_v1=>ty_740,
      ls_content         TYPE /goog/cl_aiplatform_v1=>ty_695,
      ls_raw             TYPE string,
      ls_tool            TYPE /goog/cl_aiplatform_v1=>ty_755,
      lt_parts           TYPE /goog/cl_aiplatform_v1=>ty_t_740,
      lo_response        TYPE REF TO /goog/cl_model_response,
      lt_cache           TYPE ty_t_cache_conv,
      lv_modified_prompt TYPE string,
      lr_model_key       TYPE RANGE OF /goog/model_key,
      lr_model_id        TYPE RANGE OF /goog/model_id.

    CONSTANTS: lc_abap_assist TYPE string VALUE 'ABAP_ASSIST'.

    CLEAR lt_cache.

    IF iv_llm_model IS INITIAL.
      lr_model_key = VALUE #( ( low = `*SAPCODEGEN_VERTEX*`
                                option = 'CP'
                                sign = 'I' ) ).

      SELECT SINGLE *
        FROM /goog/ai_config
       WHERE model_key IN @lr_model_key
        INTO @DATA(ls_ai_config).
    ELSE.
      lr_model_key = VALUE #( ( low = `*SAPCODEGEN_VERTEX*`
                                option = 'CP'
                                sign = 'I' ) ).
      lr_model_id = VALUE #( ( low = `*` && iv_llm_model+7 && `*`
                               option = 'CP'
                               sign = 'I' ) ).
      SELECT SINGLE *
        FROM /goog/ai_config
       WHERE model_key IN @lr_model_key AND
             model_id IN @lr_model_id
        INTO @ls_ai_config.
    ENDIF.

    lo_aiclient = NEW #( iv_key_name = ls_ai_config-client_key ).

    IF lo_aiclient IS NOT INITIAL.

      lv_p_projects_id   = lo_aiclient->gv_project_id.
      lv_p_locations_id  = ls_ai_config-locations_id.
      lv_p_publishers_id = ls_ai_config-publishers_id.
      lv_p_models_id     = ls_ai_config-model_id.

      lo_aiclient->set_useragent_suffix(
                    iv_useragent_suffix  =
                      /goog/cl_vertex_ai_sdk_utility=>get_useragent_suffix(
                        iv_module_identifier =
                          /goog/cl_vertex_ai_sdk_utility=>c_useragent-gen_multimodal_ai_inv
                        iv_addnal_identifier = lc_abap_assist ) ).

      lo_aiclient->generate_content_models(
        EXPORTING
          iv_p_projects_id   = lv_p_projects_id
          iv_p_locations_id  = lv_p_locations_id
          iv_p_publishers_id = lv_p_publishers_id
          iv_p_models_id     = lv_p_models_id
          is_input           = is_input
        IMPORTING
          es_raw             = ls_raw
          es_output          = ls_output
          ev_ret_code        = lv_ret_code
          ev_err_text        = lv_err_text
          es_err_resp        = ls_err_resp ).

      IF lv_ret_code = 200.
        lo_response = NEW #( is_content_response = ls_output ).
        rs_response-response = lo_response->get_text( ).
      ELSE.
      ENDIF.
    ENDIF.
  ENDMETHOD.


  METHOD constructor.

  ENDMETHOD.


  METHOD get_prompt.

    DATA: ls_prompt_output TYPE zclca_llm_prompt_manager=>gty_s_prompt_output,
          lt_return        TYPE bapiret2_t.

    DATA(lo_prompt_manager) = NEW zclca_llm_prompt_manager( ).

    rv_prompt = lo_prompt_manager->read_prompt(
                  EXPORTING
                    is_prompt_input  = is_prompt_input
                    it_data_key = it_data_key )-prompt_text.

  ENDMETHOD.


  METHOD is_package_whitelisted.

    " Since there is no clarity from SAP if standard code can be passed to a GenAI model for explanability
    " hence, only custom packages should be whitelisted by the customers.

    " CHECK is_trkey-devclass IS NOT INITIAL.

    SELECT * FROM zcac_aiast_wlist
      INTO TABLE @DATA(lt_whitelisted_package).
    IF sy-subrc <> 0.
      CLEAR rv_package_whitelisted.
      RETURN.
    ENDIF.

    IF line_exists( lt_whitelisted_package[ customer_package = '*' ] )
    OR line_exists( lt_whitelisted_package[ customer_package = is_trkey-devclass ] ).
      rv_package_whitelisted = abap_true.
      RETURN.
    ENDIF.

    DELETE lt_whitelisted_package WHERE customer_package NS '*'.

    LOOP AT lt_whitelisted_package ASSIGNING FIELD-SYMBOL(<ls_package>).
      IF is_trkey-devclass CP <ls_package>-customer_package.
        rv_package_whitelisted = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    UNASSIGN <ls_package>.

  ENDMETHOD.


  METHOD preprocessing.

    rv_modified_prompt = iv_user_prompt.


  ENDMETHOD.


  METHOD response_post_processing.

    sql_codeblock_post_processing(
      CHANGING
        cs_response = cs_response
    ).

  ENDMETHOD.


  METHOD sql_codeblock_post_processing.

    REPLACE gc_sql_codeblock_identifier IN cs_response WITH gc_abap_codeblock_identifier.

  ENDMETHOD.


  METHOD zifca_abap_assist_aiutil~execute_user_action.
    IF NOT is_package_whitelisted( is_trkey ).
      " Package is not whitelisted. Approval required before adding std package.
      MESSAGE i007(zca_abap_assist).
      RETURN.
    ENDIF.

    IF iv_prompt IS NOT INITIAL.
      " Unified call: Route all options through fetch_llm_response
      " This replaces the previous direct call to fetch_response_vertexai
      zifca_abap_assist_aiutil~fetch_llm_response(
        EXPORTING
          iv_prompt         = iv_prompt
          iv_option         = iv_option
          iv_current_source = iv_current_source
          iv_llm_model      = iv_llm_model
          iv_convo_id       = iv_convo_id
        RECEIVING
          rs_response       = rs_response
      ).
    ENDIF.
  ENDMETHOD.


  METHOD zifca_abap_assist_aiutil~fetch_llm_response.
    DATA: lv_intent     TYPE string,
          ls_req_resp   TYPE zif_ai_logger=>gty_s_convo,
          lv_mod_prompt TYPE string,
          lv_context    TYPE string,
          ls_input      TYPE /goog/cl_aiplatform_v1=>ty_726,
          ls_output     TYPE /goog/cl_aiplatform_v1=>ty_727,
          lv_ret_code   TYPE i,
          lv_err_text   TYPE string,
          ls_err_resp   TYPE /goog/err_resp,
          ls_part       TYPE /goog/cl_aiplatform_v1=>ty_740,
          lt_part       TYPE /goog/cl_aiplatform_v1=>ty_t_740,
          ls_content    TYPE /goog/cl_aiplatform_v1=>ty_695,
          lt_content    TYPE /goog/cl_aiplatform_v1=>ty_t_695,
          ls_raw        TYPE string,
          ls_tool       TYPE /goog/cl_aiplatform_v1=>ty_755,
          lt_parts      TYPE /goog/cl_aiplatform_v1=>ty_t_740,
          lo_response   TYPE REF TO /goog/cl_model_response,
          ls_response   TYPE zifca_abap_assist_aiutil=>ty_response.

    DATA: ls_prompt_input     TYPE zclca_llm_prompt_manager=>gty_s_prompt_input,
          lt_prompt_output    TYPE zclca_llm_prompt_manager=>gty_t_prompt_output,
          lt_return           TYPE bapiret2_t,
          lt_data_key         TYPE zifca_llm_prompt_manager=>ty_gt_data_key,
          lo_badi_content_mod TYPE REF TO zbadi_ca_llm_content_mod.

    CONSTANTS: lv_keyname TYPE /goog/keyname VALUE 'ABAP_CODEGEN'.

    DATA(lv_prompt) = preprocessing(  iv_user_prompt = iv_prompt
                                      iv_option = iv_option
                                      iv_additional_context = iv_current_source ).

    CASE iv_option.
      WHEN 'content'.
        " Logic moved from execute_user_action
        APPEND VALUE #( name  = '{user_prompt}'
                        value = lv_prompt ) TO lt_data_key.
        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id      = gc_llm_content_prompt_id.
        ls_prompt_input-version        = 1.
      WHEN 'eclipseRefactor'.
        " Logic moved from execute_user_action
        APPEND VALUE #( name  = '{user_prompt}'
                        value = lv_prompt ) TO lt_data_key.
        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id      = gc_llm_content_refactor_id.
        ls_prompt_input-version        = 1.
      WHEN 'explain'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_explain_prompt_id.
        ls_prompt_input-version = 1.

      WHEN 'chatbot'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_chatbot_prompt_id.
        ls_prompt_input-version = 1.

      WHEN 'suggest'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_suggest_prompt_id.
        ls_prompt_input-version = 1.

      WHEN 'aut'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_aut_prompt_id.
        ls_prompt_input-version = 1.

      WHEN 'review'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_review_prompt_id.
        ls_prompt_input-version = 1.

      WHEN 'translate'.

        APPEND VALUE #( name = '{current_code_context}' value = iv_current_source ) TO lt_data_key.
        APPEND VALUE #( name = '{user_prompt}' value = lv_prompt ) TO lt_data_key.

        ls_prompt_input-application_id = gc_llm_app_id.
        ls_prompt_input-prompt_id = gc_translate_prompt_id.
        ls_prompt_input-version = 1.

      WHEN OTHERS.

    ENDCASE.

    TRY.

        lv_prompt = get_prompt( EXPORTING is_prompt_input = ls_prompt_input
                                          it_data_key     = lt_data_key ).
      CATCH zcxca_llm_prompt_manager INTO DATA(lo_exception).
    ENDTRY.

    TRY.

        ls_req_resp = zclca_ai_logger=>get_instance( iv_convo_id = iv_convo_id )->zif_ai_logger~get_req_resp( ).

        CLEAR: lt_content.
        LOOP AT ls_req_resp-t_req_resp ASSIGNING FIELD-SYMBOL(<ls_req_response>).
          CLEAR: lt_part, ls_part, ls_content.
          ls_content-role = 'USER'.
          ls_part-text = <ls_req_response>-request_string.
          APPEND ls_part TO lt_part.
          ls_content-parts = lt_part.
          APPEND ls_content TO lt_content.

          CLEAR: ls_content, lt_part, ls_part.
          IF <ls_req_response>-response_string IS NOT INITIAL.
            ls_content-role = 'MODEL'.
            ls_part-text = <ls_req_response>-response_string.
            APPEND ls_part TO lt_part.
            ls_content-parts = lt_part.
            APPEND ls_content TO lt_content.
          ENDIF.
        ENDLOOP.

        CLEAR: ls_content, lt_part, ls_part.
        ls_content-role = 'USER'.
        IF lt_content IS INITIAL.
          ls_part-text = lv_prompt.
        ELSE.
          ls_part-text = iv_prompt.
        ENDIF.

        APPEND ls_part TO lt_part.
        ls_content-parts = lt_part.
        APPEND ls_content TO lt_content.

        TRY.
            GET BADI lo_badi_content_mod.

            CALL BADI lo_badi_content_mod->modify_content
              EXPORTING
                iv_prompt  = lv_prompt
                iv_option  = iv_option
              CHANGING
                ct_content = lt_content.
          CATCH cx_badi_not_implemented cx_badi_multiply_implemented.
            " BAdI not implemented or multiple active impl (if not allowed)
            " Proceed with standard content
        ENDTRY.

        ls_input-contents = lt_content.

        zclca_ai_logger=>get_instance( iv_convo_id = iv_convo_id )->zif_ai_logger~log_request(
                     iv_req_string = iv_prompt
                     iv_req_after_preprocess = lv_prompt ).

        ls_response = call_llm( EXPORTING iv_prompt         = lv_prompt
                                          iv_option         = ''
                                          iv_current_source = iv_current_source
                                          is_input          = ls_input
                                          iv_llm_model      = iv_llm_model ).

        response_post_processing(
          CHANGING
            cs_response = ls_response-response
        ).

        rs_response-identifier = zclca_ai_logger=>get_instance(
                                          )->zif_ai_logger~log_response(
                                                iv_resp_string = ls_response-response
                                                iv_ret_code = CONV #( lv_ret_code )
                                                iv_ret_text = lv_err_text
                                                ).
      CATCH cx_root INTO DATA(lx_root).
    ENDTRY.

    rs_response-response = ls_response-response.
  ENDMETHOD.
ENDCLASS.
