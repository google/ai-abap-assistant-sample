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
class ZCLCA_AI_LOGGER definition
  public
  final
  create private .

public section.

  interfaces ZIF_AI_LOGGER .

*      gt_feedback TYPE STANDARD TABLE OF zcad_ai_feedback WITH KEY resp_id READ-ONLY
  data GS_CONVO type ZIF_AI_LOGGER~GTY_S_CONVO read-only .

  class-methods GET_INSTANCE
    importing
      !IV_CONVO_ID type ZCAI_AI_CONVO_ID optional
    returning
      value(RO_LOGGER) type ref to ZCLCA_AI_LOGGER .
  class-methods FREE .
protected section.
private section.

  class-data GO_LOGGER type ref to ZCLCA_AI_LOGGER .
  class-data GT_CATEG_CONFIG type ZIF_AI_LOGGER=>GTY_T_FB_CATEG_CONFIG .
  data GV_CURR_REQ_ID type ZCAI_AI_REQ_ID .

  methods CONSTRUCTOR
    importing
      !IV_CONVO_ID type ZCAI_AI_CONVO_ID optional .
  methods NEW .
  methods LOAD
    importing
      !IV_CONVO_ID type ZCAI_AI_CONVO_ID .
ENDCLASS.



CLASS ZCLCA_AI_LOGGER IMPLEMENTATION.


  METHOD constructor.
    IF iv_convo_id IS INITIAL.
      new( ).
    ELSE.
      load( iv_convo_id ).
    ENDIF.
  ENDMETHOD.


  METHOD free.
    FREE go_logger.
  ENDMETHOD.


  METHOD get_instance.
    IF iv_convo_id IS NOT INITIAL.
      IF go_logger IS NOT BOUND OR iv_convo_id <> go_logger->gs_convo-convo_id.
        go_logger = NEW #( iv_convo_id = iv_convo_id ).
      ENDIF.

    ELSEIF go_logger IS NOT BOUND.
      go_logger = NEW #( ).
    ENDIF.

    ro_logger = go_logger.
  ENDMETHOD.


  METHOD load.
    DATA(lt_convo) = me->zif_ai_logger~get_convo_history( iv_convo_id = iv_convo_id ).
    IF lt_convo IS NOT INITIAL.
      gs_convo = lt_convo[ 1 ].
      SORT gs_convo-t_req_resp BY req_timestamp ASCENDING.
    ENDIF.

**    SELECT
**      f~feedback_id,
**      f~resp_id,
**      f~rating,
**      f~user_input,
**      f~timestamp
**      FROM zcaD_AI_feedback AS f
**      INNER JOIN @gs_convo-t_req_resp AS r ON f~resp_id = r~resp_id
**      ORDER BY timestamp ASCENDING
**      INTO CORRESPONDING FIELDS OF TABLE @gt_feedback.
  ENDMETHOD.


  METHOD new.
    TRY.
        DATA(ls_convo) = VALUE zcad_ai_convo( convo_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( )
                                              uname = sy-uname
                                              tcode = COND #( WHEN sy-tcode IS NOT INITIAL THEN sy-tcode
                                                              ELSE '<Eclipse>' )
                                            ).
        INSERT zcad_ai_convo CONNECTION r/3*sap_2th_connect_appl_log FROM ls_convo.
        COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
      CATCH cx_uuid_error INTO DATA(lex_uuid).
        RETURN.
    ENDTRY.

    gs_convo-convo_id = ls_convo-convo_id.
    gs_convo-uname = ls_convo-uname.
  ENDMETHOD.


METHOD zif_ai_logger~get_convo_history.

  DATA: ltr_convo_id TYPE RANGE OF zcai_ai_convo_id.

  IF iv_convo_id IS NOT INITIAL.
    APPEND VALUE #( sign = 'I' option = 'EQ' low = iv_convo_id ) TO ltr_convo_id.
  ENDIF.

  SELECT
    convo_id,
    uname,
    tcode
    INTO CORRESPONDING FIELDS OF TABLE @rt_convo
    FROM zcad_ai_convo
    WHERE uname = @iv_uname AND
          convo_id IN @ltr_convo_id.

  IF sy-subrc = 0.
    IF rt_convo IS NOT INITIAL.
      SELECT
          req~convo_id,
          req~req_id,
          req~request_string,
          req~request_after_preprocess,
          req~timestamp      AS req_timestamp,
          resp~resp_id,
          resp~response_string,
          resp~ret_code,
          resp~ret_text,
          resp~timestamp     AS resp_timestamp,
          resp~accepted
        FROM zcad_ai_req AS req
        LEFT OUTER JOIN zcad_ai_resp AS resp ON resp~req_id = req~req_id
        FOR ALL ENTRIES IN @rt_convo
        WHERE req~convo_id = @rt_convo-convo_id
        INTO TABLE @DATA(lt_req_resp).

      SORT lt_req_resp BY req_timestamp ASCENDING.

      IF sy-subrc = 0 AND lt_req_resp IS NOT INITIAL.
        SELECT
            f~feedback_id,
            f~resp_id,
            f~rating,
            f~user_input,
            f~timestamp,
            s~category_id,
            c~category_desc
          FROM zcad_ai_feedback   AS f
          LEFT OUTER JOIN zcad_ai_fb_cgsel AS s ON s~feedback_id = f~feedback_id
          INNER JOIN zcad_ai_fb_categ   AS c ON c~category_id = s~category_id
          FOR ALL ENTRIES IN @lt_req_resp
          WHERE f~resp_id = @lt_req_resp-resp_id
          INTO TABLE @DATA(lt_feedback).
      ENDIF.
    ENDIF.

    " The logic for reconstructing the nested table structure remains the same
    LOOP AT rt_convo REFERENCE INTO DATA(lr_convo).
      LOOP AT lt_req_resp REFERENCE INTO DATA(lr_req_resp) WHERE convo_id = lr_convo->convo_id.
        IF lr_convo->first_run IS INITIAL.
          lr_convo->first_run = lr_req_resp->req_timestamp.
        ENDIF.

        APPEND VALUE zif_ai_logger=>gty_s_req_resp(
            req_id                   = lr_req_resp->req_id
            request_string           = lr_req_resp->request_string
            request_after_preprocess = lr_req_resp->request_after_preprocess
            req_timestamp            = lr_req_resp->req_timestamp
            resp_id                  = lr_req_resp->resp_id
            response_string          = lr_req_resp->response_string
            ret_code                 = lr_req_resp->ret_code
            ret_text                 = lr_req_resp->ret_text
            resp_timestamp           = lr_req_resp->resp_timestamp
            accepted                 = lr_req_resp->accepted
            ) TO lr_convo->t_req_resp ASSIGNING FIELD-SYMBOL(<ls_req_resp>).

        LOOP AT lt_feedback INTO DATA(ls_fb) WHERE resp_id = <ls_req_resp>-resp_id
          GROUP BY ( resp_id = ls_fb-resp_id )
          REFERENCE INTO DATA(lr_fb).
          LOOP AT GROUP lr_fb ASSIGNING FIELD-SYMBOL(<ls_fb>).
            <ls_req_resp>-s_feedback-feedback_id = <ls_fb>-feedback_id.
            <ls_req_resp>-s_feedback-rating      = <ls_fb>-rating.
            <ls_req_resp>-s_feedback-user_input  = <ls_fb>-user_input.
            <ls_req_resp>-s_feedback-timestamp   = <ls_fb>-timestamp.
            APPEND VALUE #( category_id   = <ls_fb>-category_id
                            category_desc = <ls_fb>-category_desc
                          ) TO <ls_req_resp>-s_feedback-t_categ.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDIF.

  SORT rt_convo BY first_run DESCENDING.
ENDMETHOD.


  METHOD zif_ai_logger~get_feedback_category.
    IF gt_categ_config IS INITIAL.
      SELECT
        category_id,
        linked_rating,
        sort_order,
        category_desc
      FROM zcad_ai_fb_categ
      INTO CORRESPONDING FIELDS OF TABLE @gt_categ_config
      ORDER BY
          linked_rating,
          sort_order.
    ENDIF.
    rt_category = gt_categ_config.

  ENDMETHOD.


  METHOD zif_ai_logger~get_req_resp.
    rs_req_resp = gs_convo.
  ENDMETHOD.


  METHOD zif_ai_logger~log_acceptance.
    TRY.
        DATA(lr_req_resp) = REF #( gs_convo-t_req_resp[ resp_id = iv_resp_id ] ).
        lr_req_resp->accepted = abap_true.

        UPDATE zcad_ai_resp CONNECTION r/3*sap_2th_connect_appl_log SET accepted = lr_req_resp->accepted WHERE resp_id = iv_resp_id.
        IF sy-subrc = 0 AND iv_commit = abap_true.
          COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
        ENDIF.

      CATCH cx_sy_itab_line_not_found.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ai_logger~log_feedback.
    DATA: lt_zcad_ai_fb_cgsel_del TYPE TABLE OF zcad_ai_fb_cgsel,
          lt_zcad_ai_fb_cgsel_ins TYPE TABLE OF zcad_ai_fb_cgsel.

    TRY.
        DATA(lr_feedback) = REF #( gs_convo-t_req_resp[ resp_id = iv_resp_id ]-s_feedback ).
        IF lr_feedback->feedback_id IS INITIAL.
          lr_feedback->feedback_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( ).
          GET TIME STAMP FIELD lr_feedback->timestamp.
        ENDIF.

        IF iv_rating IS SUPPLIED.
          lr_feedback->rating = iv_rating.
        ENDIF.

        IF iv_user_input IS SUPPLIED.
          lr_feedback->user_input = iv_user_input.
        ENDIF.

        IF it_fb_categ IS SUPPLIED.
          LOOP AT lr_feedback->t_categ REFERENCE INTO DATA(ls_categ).
            IF NOT line_exists( it_fb_categ[ table_line = ls_categ->category_id ] ).
              CLEAR ls_categ->*.
              APPEND VALUE #( feedback_id = lr_feedback->feedback_id
                              category_id = ls_categ->category_id
                            ) TO lt_zcad_ai_fb_cgsel_del.
            ENDIF.
          ENDLOOP.
          DELETE lr_feedback->t_categ WHERE table_line IS INITIAL.

          LOOP AT it_fb_categ REFERENCE INTO DATA(ls_fb_categ).
            IF NOT line_exists( lr_feedback->t_categ[ category_id = ls_fb_categ->* ]  ).
              APPEND VALUE #( category_id = ls_fb_categ->*
                              category_desc = VALUE #( gt_categ_config[ category_id = ls_fb_categ->* ]-category_desc OPTIONAL )
                            ) TO lr_feedback->t_categ.

              APPEND VALUE #( feedback_id = lr_feedback->feedback_id
                              category_id = ls_fb_categ->*
                            ) TO lt_zcad_ai_fb_cgsel_ins.
            ENDIF.
          ENDLOOP.

          """""
        ENDIF.

        DATA(ls_feedback) = CORRESPONDING zcad_ai_feedback( lr_feedback->* ).

        IF lt_zcad_ai_fb_cgsel_del IS NOT INITIAL.
          DELETE zcad_ai_fb_cgsel CONNECTION r/3*sap_2th_connect_appl_log FROM TABLE lt_zcad_ai_fb_cgsel_del.
        ENDIF.

        IF lt_zcad_ai_fb_cgsel_ins IS NOT INITIAL.
          INSERT zcad_ai_fb_cgsel CONNECTION r/3*sap_2th_connect_appl_log FROM TABLE lt_zcad_ai_fb_cgsel_ins.
        ENDIF.

        MODIFY zcad_ai_feedback CONNECTION r/3*sap_2th_connect_appl_log FROM ls_feedback.
        IF sy-subrc = 0 AND iv_commit = abap_true.
          COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
        ENDIF.

        rv_feedback_id = ls_feedback-feedback_id.

      CATCH: cx_sy_itab_line_not_found, cx_uuid_error.
    ENDTRY.




******    TRY.
******
******        DATA(lr_feedback) = REF zcad_ai_feedback( gt_feedback[ resp_id = iv_resp_id ] ).
******        lr_feedback->rating = iv_rating.
******        lr_feedback->user_input = iv_user_input.
******        GET TIME STAMP FIELD lr_feedback->timestamp.
******        DATA(ls_feedback) = lr_feedback->*.
******
******      CATCH cx_sy_itab_line_not_found.
******        TRY.
******            ls_feedback = VALUE zcad_ai_feedback(
******                                 feedback_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( )
******                                 resp_id = iv_resp_id
******                                 rating = iv_rating
******                                 user_input = iv_user_input
******                                ).
******            GET TIME STAMP FIELD ls_feedback-timestamp.
******            APPEND ls_feedback TO gt_feedback.
******          CATCH cx_uuid_error INTO DATA(lex_uuid).
******            RETURN.
******        ENDTRY.
******    ENDTRY.
******
******    MODIFY zcad_ai_feedback CONNECTION r/3*sap_2th_connect_appl_log FROM ls_feedback.
******    IF sy-subrc = 0 AND iv_commit = abap_true.
******      COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
******    ENDIF.
******
******    rv_feedback_id = ls_feedback-feedback_id.

  ENDMETHOD.


  METHOD zif_ai_logger~log_request.
    GET TIME STAMP FIELD DATA(lv_timestamp).

    TRY.
        DATA(ls_req) = VALUE zcad_ai_req(
                                    req_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( )
                                    convo_id = gs_convo-convo_id
                                    request_string = iv_req_string
                                    request_after_preprocess = iv_req_after_preprocess
                                    timestamp = lv_timestamp
                                    ).
        INSERT zcad_ai_req CONNECTION r/3*sap_2th_connect_appl_log FROM ls_req.
        IF sy-subrc = 0 AND iv_commit = abap_true.
          COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
        ENDIF.
        rv_req_id = gv_curr_req_id = ls_req-req_id.
        APPEND VALUE zif_ai_logger=>gty_s_req_resp( req_id = ls_req-req_id
                                                    request_string = ls_req-request_string
                                                    request_after_preprocess = ls_req-request_after_preprocess
                                                    req_timestamp = ls_req-timestamp
                                                  ) TO gs_convo-t_req_resp.
      CATCH cx_uuid_error INTO DATA(lex_uuid).
        RETURN.
    ENDTRY.
  ENDMETHOD.


  METHOD zif_ai_logger~log_req_resp.
    me->zif_ai_logger~log_request(
      EXPORTING
        iv_req_string = iv_req_string
        iv_commit     = abap_false
    ).

    rv_resp_id = me->zif_ai_logger~log_response(
      EXPORTING
        iv_resp_string = iv_resp_string
        iv_ret_code    = iv_ret_code
        iv_ret_text    = iv_ret_text
        iv_commit      = abap_false
    ).

    COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
  ENDMETHOD.


  METHOD zif_ai_logger~log_response.
    GET TIME STAMP FIELD DATA(lv_timestamp).

    TRY.
        DATA(ls_resp) = VALUE zcad_ai_resp(
                                    resp_id = cl_system_uuid=>if_system_uuid_static~create_uuid_c32( )
                                    req_id = gv_curr_req_id
                                    response_string = iv_resp_string
                                    ret_code = iv_ret_code
                                    ret_text = iv_ret_text
                                    timestamp = lv_timestamp
                                    ).
        INSERT zcad_ai_resp CONNECTION r/3*sap_2th_connect_appl_log FROM ls_resp.
        IF sy-subrc = 0 AND iv_commit = abap_true.
          COMMIT CONNECTION r/3*sap_2th_connect_appl_log.
          TRY.
              DATA(lr_req_resp) = REF #( gs_convo-t_req_resp[ lines( gs_convo-t_req_resp ) ] ).
              lr_req_resp->resp_id = ls_resp-resp_id.
              lr_req_resp->response_string = ls_resp-response_string.
              lr_req_resp->resp_timestamp = ls_resp-timestamp.
              lr_req_resp->ret_code = ls_resp-ret_code.
              lr_req_resp->ret_text = ls_resp-ret_text.
            CATCH cx_sy_itab_line_not_found.
          ENDTRY.
        ENDIF.
        rv_resp_id = ls_resp-resp_id.
      CATCH cx_uuid_error INTO DATA(lex_uuid).
        RETURN.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
