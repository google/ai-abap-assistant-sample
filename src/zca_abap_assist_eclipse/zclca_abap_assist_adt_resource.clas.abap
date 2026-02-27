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
CLASS zclca_abap_assist_adt_resource DEFINITION
  PUBLIC
  INHERITING FROM cl_adt_rest_resource
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF gc_adt,
                 class_name    TYPE seoclsname VALUE 'ZCLCA_ABAP_ASSIST_ADT_RESOURCE',
                 resource_type TYPE string VALUE 'ADT_RESOURCE',
                 st_name       TYPE string VALUE 'ZCA_ABAP_ASSIST_ADT_ST',
                 root_name     TYPE string VALUE 'ADT_CONVERSATION',
               END   OF gc_adt.

    CLASS-METHODS get_content_handler
      RETURNING
        VALUE(result) TYPE REF TO if_adt_rest_content_handler .
    METHODS get REDEFINITION.
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.



CLASS ZCLCA_ABAP_ASSIST_ADT_RESOURCE IMPLEMENTATION.


  METHOD get.

    DATA: ls_adt_conversation  TYPE zsca_adt_conversation.
    DATA: lo_request    TYPE REF TO cl_adt_rest_request,
          lt_parameters TYPE tihttpnvp.
    DATA: lv_model1 TYPE zca_abap_assist_model_key.
    DATA: lv_convo_id TYPE zcai_ai_convo_id.
    DATA: lt_history TYPE zif_ai_logger=>gty_t_convo.

    lo_request ?= request.

    DATA(lo_rest_base_request) = lo_request->if_adt_rest_request~get_inner_rest_request( ).

    IF lo_rest_base_request IS BOUND.
      lo_rest_base_request->get_uri_query_parameters(
        EXPORTING
          iv_encoded    = abap_false
        RECEIVING
          rt_parameters = lt_parameters  ).
    ENDIF.

    DATA(lv_model) = VALUE #( lt_parameters[ name = 'model' ]-value OPTIONAL ).
    DATA(lv_prompt) = VALUE #( lt_parameters[ name = 'prompt' ]-value OPTIONAL ).
    DATA(lv_context) = VALUE #( lt_parameters[ name = 'context' ]-value OPTIONAL ).
    DATA(lv_option) = VALUE #( lt_parameters[ name = 'option' ]-value OPTIONAL ).
    DATA(lv_user) = VALUE #( lt_parameters[ name = 'userinfo' ]-value OPTIONAL ).
    lv_convo_id = VALUE #( lt_parameters[ name = 'convo_id' ]-value OPTIONAL ).
    DATA(lv_like) = VALUE #( lt_parameters[ name = 'like' ]-value OPTIONAL ).
    DATA(lv_dislike) = VALUE #( lt_parameters[ name = 'dislike' ]-value OPTIONAL ).
    DATA(lv_copy) = VALUE #( lt_parameters[ name = 'copy' ]-value OPTIONAL ).
    DATA(lv_accept) = VALUE #( lt_parameters[ name = 'accept' ]-value OPTIONAL ).

    IF lv_prompt IS NOT INITIAL AND
      lv_option IS NOT INITIAL AND
      lv_context IS NOT INITIAL.
      lv_model1 = lv_model.
      DATA(ls_response) = NEW zclca_abap_assist_aiutil(
                                )->zifca_abap_assist_aiutil~execute_user_action(
                                    iv_prompt         = lv_prompt
                                    iv_option         = CONV #( lv_option )
                                    iv_current_source = lv_context
                                    iv_llm_model = lv_model1
                                    iv_convo_id  = lv_convo_id ).

      DATA(ls_chat_history) = zclca_ai_logger=>get_instance( )->zif_ai_logger~get_req_resp( ).
      APPEND ls_chat_history TO lt_history.
      ls_adt_conversation = VALUE #( model = lv_model
                                     convo_id = ls_chat_history-convo_id
                                     prompt = lv_prompt
                                     response = ls_response-response
                                     additional_info = 'response received'
                                     ) .
      LOOP AT lt_history ASSIGNING FIELD-SYMBOL(<ls_history>).
        APPEND INITIAL LINE TO ls_adt_conversation-history
          ASSIGNING FIELD-SYMBOL(<ls_history_new>).
        <ls_history_new> = VALUE #( convo_id = <ls_history>-convo_id
                                    uname = <ls_history>-uname
                                    first_run = <ls_history>-first_run ).
        LOOP AT <ls_history>-t_req_resp ASSIGNING FIELD-SYMBOL(<ls_req_resp>).
          APPEND INITIAL LINE TO <ls_history_new>-t_req_resp
            ASSIGNING FIELD-SYMBOL(<ls_req_rep_new>).
          MOVE-CORRESPONDING <ls_req_resp> TO  <ls_req_rep_new>.
        ENDLOOP.
      ENDLOOP.
    ENDIF.

    IF lv_user = 'x'.
      DATA: ls_user03 TYPE usr03.

      CALL FUNCTION 'SUSR_SHOW_USER_DETAILS'
        EXPORTING
          bname      = sy-uname
          mandt      = sy-mandt
          no_display = abap_true
        CHANGING
          user_usr03 = ls_user03.

      ls_adt_conversation = VALUE #( username = ls_user03-name1 ).

      SELECT * FROM zcac_abapast_mdl INTO TABLE @DATA(lt_models).
      IF sy-subrc = 0.
        LOOP AT lt_models ASSIGNING FIELD-SYMBOL(<ls_model>).
          APPEND VALUE #( model_key = <ls_model>-model_key
                          model_name = <ls_model>-model_name ) TO  ls_adt_conversation-models.
        ENDLOOP.
        UNASSIGN <ls_model>.
      ENDIF.

      SELECT * FROM zca_prompt_templ INTO TABLE @DATA(lt_templates).
      IF sy-subrc = 0.
        LOOP AT lt_templates ASSIGNING FIELD-SYMBOL(<ls_template>).
          APPEND  VALUE #( template_id = <ls_template>-id
                            description = <ls_template>-description
                            template = <ls_template>-template ) TO ls_adt_conversation-templates.
        ENDLOOP.
        UNASSIGN <ls_template>.
      ENDIF.
      DATA(lt_chat_history) = zclca_ai_logger=>zif_ai_logger~get_convo_history( ).

      SORT lt_chat_history BY first_run DESCENDING.
      DATA(lt_chat_temp) = lt_chat_history.
      IF lines( lt_chat_history ) > 6.
        CLEAR: lt_chat_history.
        APPEND LINES OF lt_chat_temp  FROM 1 TO 6 TO lt_chat_history.
        CLEAR lt_chat_temp.
      ENDIF.

      LOOP AT lt_chat_history ASSIGNING FIELD-SYMBOL(<ls_chat_history>).
        APPEND INITIAL LINE TO ls_adt_conversation-history ASSIGNING FIELD-SYMBOL(<ls_adt>).
        <ls_adt> = VALUE #( convo_id = <ls_chat_history>-convo_id
                            uname = <ls_chat_history>-uname
                            first_run = <ls_chat_history>-first_run ).
        LOOP AT <ls_chat_history>-t_req_resp ASSIGNING <ls_req_resp>.
          APPEND INITIAL LINE TO  <ls_adt>-t_req_resp ASSIGNING <ls_req_rep_new>.
          MOVE-CORRESPONDING <ls_req_resp> TO  <ls_req_rep_new>.
        ENDLOOP.
      ENDLOOP.

    ENDIF.

    IF lv_like IS NOT INITIAL.
      zclca_ai_logger=>get_instance( )->zif_ai_logger~log_feedback(
                                      iv_resp_id = CONV #( lv_like )
                                      iv_rating = zif_ai_logger=>gc_rating-thumbs_up ).
      ls_adt_conversation-additional_info = 'Feedback updated.'.
    ENDIF.

    IF lv_dislike IS NOT INITIAL.
      zclca_ai_logger=>get_instance( )->zif_ai_logger~log_feedback(
                                      iv_resp_id = CONV #( lv_dislike )
                                      iv_rating = zif_ai_logger=>gc_rating-thumbs_down ).
      ls_adt_conversation-additional_info = 'Feedback updated.'.
    ENDIF.

    IF lv_copy IS NOT INITIAL OR lv_accept IS NOT INITIAL.

      DATA(lv_respid) = COND #( WHEN lv_copy IS NOT INITIAL
                                THEN lv_copy
                                WHEN lv_accept IS NOT INITIAL
                                THEN lv_accept ) .

      SELECT SINGLE a~convo_id
        FROM zcad_ai_req AS a
        INNER JOIN zcad_ai_resp AS b
        ON a~req_id = b~req_id
        INTO @DATA(lv_convoid)
        WHERE b~resp_id = @lv_respid.

      zclca_ai_logger=>get_instance( iv_convo_id = lv_convoid )->zif_ai_logger~log_acceptance(
                                     iv_resp_id = CONV #( lv_respid )
                                     iv_commit = abap_true ).
    ENDIF.

    response->set_body_data( content_handler = get_content_handler( )
                             data = ls_adt_conversation ).

  ENDMETHOD.


  METHOD get_content_handler.
    result = cl_adt_rest_cnt_hdl_factory=>get_instance( )->get_handler_for_xml_using_st(
                                                            EXPORTING
                                                            st_name = gc_adt-st_name
                                                            root_name = gc_adt-root_name ).
  ENDMETHOD.
ENDCLASS.
