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
CLASS zclca_abap_assist_ui DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    CLASS cl_gui_cfw DEFINITION LOAD .

    INTERFACES zifca_abap_assist_ui .

    ALIASES show_codegen_dialog
      FOR zifca_abap_assist_ui~show_codegen_dialog .

    TYPES:
      ty_node_t TYPE STANDARD TABLE OF mtreesnode
                                           WITH DEFAULT KEY .
    TYPES:
      BEGIN OF ty_table_line,
        line(150) TYPE c,
      END OF ty_table_line .
    TYPES:
      BEGIN OF ty_code,
        id   TYPE char10,
        code TYPE STANDARD TABLE OF string WITH DEFAULT KEY,
      END OF ty_code .

    CLASS-DATA:
      gt_templates TYPE STANDARD TABLE OF zca_prompt_templ .
    CLASS-DATA gv_sendrequest TYPE char1 .
    CLASS-DATA gv_codecounter TYPE char10 .
    CLASS-DATA gv_inprocess TYPE char1 .
    CLASS-DATA gt_response_table TYPE ztca_response_table .
    CLASS-DATA gt_chat_history TYPE ztca_response_table .
    CLASS-DATA go_promoptedit TYPE REF TO cl_gui_textedit .
    CLASS-DATA go_code_gen_ui TYPE REF TO zclca_abap_assist_ui .
    CONSTANTS:
      BEGIN OF gc_constants,
        editor      TYPE string VALUE '(SAPLS38E)abap_pgeditor',
        edit        TYPE string VALUE '(SAPLLOCAL_EDT1)c_editor',
        std         TYPE char30 VALUE 'STD',
        wmethod     TYPE char30 VALUE 'WMETHOD',
        pesudo      TYPE char30 VALUE 'PESUDO',
        crud        TYPE char30 VALUE 'CRUD',
        line_length TYPE i VALUE 150,
        name        TYPE string VALUE '&NAME&',
        stylesheet  TYPE string VALUE '&STYLESHEET&',
        prompt      TYPE string VALUE '&PROMPT&',
        response    TYPE string VALUE '&RESPONSE&',
*        html_template       TYPE tdobname VALUE 'YCA_ABAPCODEGEN_HTML',
*        stylesheet_template TYPE tdobname VALUE 'YCA_ABAPCODEGEN_CSS',
      END OF gc_constants .
    CONSTANTS:
      BEGIN OF gc_fcodes,
        accept       TYPE syst_ucomm VALUE 'ACCEPT',
        copy         TYPE syst_ucomm VALUE 'COPY',
        explain      TYPE sy-ucomm VALUE 'G_EXPLAIN',
        codegen      TYPE sy-ucomm VALUE 'CODEGEN',
        codegen_d    TYPE sy-ucomm VALUE 'CODEGEN_D',
        review       TYPE sy-ucomm VALUE 'G_REVIEW',
        suggest      TYPE sy-ucomm VALUE 'G_SUGGEST',
        aut          TYPE sy-ucomm VALUE 'G_AUT',
        translate    TYPE sy-ucomm VALUE 'G_TRANSLAT',
        t1           TYPE syst_ucomm VALUE 'T1',
        t2           TYPE syst_ucomm VALUE 'T2',
        t3           TYPE syst_ucomm VALUE 'T3',
        t4           TYPE syst_ucomm VALUE 'T4',
        template     TYPE syst_ucomm VALUE 'TEMPLATE',
        quick_action TYPE syst_ucomm VALUE 'QA',
        cancel       TYPE syst_ucomm VALUE 'CANC',
        enter        TYPE syst_ucomm VALUE 'ENTER',
        reset        TYPE  syst_ucomm VALUE 'RESET',
        resetprompt  TYPE syst_ucomm VALUE 'RESETPRMT',
        back         TYPE syst_ucomm VALUE 'BACK',
        like         TYPE syst_ucomm VALUE 'LIKE',
        dislike      TYPE syst_ucomm VALUE 'DISLIKE',
        model_select TYPE syst_ucomm VALUE 'SELECTED',
        new_chat     TYPE syst_ucomm VALUE 'NEWCHAT',
        recent_chat  TYPE syst-ucomm VALUE 'RECENTCHAT',
        ongenerate   TYPE syst-ucomm VALUE 'GENERATE',
      END OF gc_fcodes .
    CLASS-DATA go_custom_container TYPE REF TO cl_gui_custom_container .
    CLASS-DATA go_editor TYPE REF TO cl_gui_textedit .
    CLASS-DATA go_input_container TYPE REF TO cl_gui_custom_container .
    CLASS-DATA go_input_text_editor TYPE REF TO cl_gui_textedit .
    CLASS-DATA go_html_viewer TYPE REF TO cl_gui_html_viewer .
    CLASS-DATA gv_first_time TYPE char1 .
    DATA gv_repid LIKE sy-repid .
    DATA gv_prompt TYPE char3000 .
    DATA go_tree TYPE REF TO cl_gui_simple_tree .
    DATA gv_ok_code TYPE sy-ucomm .
    DATA gv_selected_options TYPE tv_nodekey .
    CLASS-DATA go_obj TYPE REF TO cl_wb_pgeditor .
    CLASS-DATA go_editobj TYPE REF TO cl_gui_abapedit .
    DATA:
      gt_table        TYPE TABLE OF ty_table_line .
    DATA:
      gt_prompttable    TYPE TABLE OF ty_table_line WITH EMPTY KEY .
    DATA:
      gt_response    TYPE TABLE OF ty_table_line .
    DATA gs_textstruct TYPE ty_table_line .
    DATA:
      gv_html(10000) TYPE c .
    DATA gt_html TYPE ztca_response_table .
    DATA gv_loaded TYPE c .
    DATA:
      gv_url(1024)  TYPE c .
    DATA:
      gs_html LIKE LINE OF gt_html .
    DATA gv_color TYPE string VALUE '#e5f1f4' ##NO_TEXT.
    DATA gt_event TYPE cntl_simple_events .
    DATA gs_event TYPE cntl_simple_event .
    DATA gt_postdata_tab TYPE cnht_post_data_tab .
    DATA gt_edquery_table TYPE cnht_query_table .
    CLASS-DATA:
      gt_code  TYPE STANDARD TABLE OF ty_code .
    CLASS-DATA gv_node_key TYPE tv_nodekey .
    CLASS-DATA gv_abap_fcode TYPE sy-ucomm .
    CLASS-DATA gv_abap_displaymode TYPE char1 .
    DATA gt_selected_code TYPE sedi_source .
    DATA gv_fullscreen TYPE boolean .
    DATA gs_trkey TYPE trkey .
    DATA go_editor_handle TYPE REF TO cl_wb_editor .

    METHODS split_string_to_table
      IMPORTING
        !iv_string       TYPE string
      RETURNING
        VALUE(et_output) TYPE ztca_response_table .
    CLASS-METHODS get_instance
      RETURNING
        VALUE(ro_instance) TYPE REF TO zclca_abap_assist_ui .
    METHODS pai_of_screen_100
      IMPORTING
        !iv_ok_code TYPE sy-ucomm .
    METHODS pbo_of_screen_100 .
    METHODS on_sapevent
        FOR EVENT sapevent OF cl_gui_html_viewer
      IMPORTING
        !action
        !frame
        !getdata
        !postdata
        !query_table .
    METHODS pretty_print
      CHANGING
        !ct_pattern TYPE swbse_max_line_tab .
    METHODS constructor .
    METHODS fill_model_dropdown .
    METHODS llm_model_reselected
      IMPORTING
        !iv_model_key TYPE zca_abap_assist_model_key .
PROTECTED SECTION.
PRIVATE SECTION.

  TYPES:
    pict_line(1022) TYPE x .
  TYPES:
    pict_tab        TYPE STANDARD TABLE OF pict_line
                                        WITH EMPTY KEY .

  DATA go_aiutil TYPE REF TO zifca_abap_assist_aiutil .
  DATA gv_llm_model TYPE zca_abap_assist_model_key .
  DATA gv_convo_id TYPE zcai_ai_convo_id .

  METHODS prepare_for_recent_chat
    IMPORTING
      !iv_convo_id TYPE zcai_ai_convo_id .
  METHODS build_collapsing_button
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS build_model_dropdown
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS build_new_chat_button
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS build_recent_chat_menu
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS build_script
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS explain_code
    IMPORTING
      !iv_from_pbo TYPE abap_bool OPTIONAL .
  METHODS quick_action
    IMPORTING
      !iv_action TYPE char50 .
  METHODS populate_template
    IMPORTING
      !iv_template_id TYPE string .
  METHODS build_code_block
    IMPORTING
      !iv_code       TYPE string
      !iv_respid     TYPE zcai_ai_resp_id
    RETURNING
      VALUE(rv_html) TYPE string .
  METHODS build_explanation_block
    IMPORTING
      !iv_code       TYPE string
    RETURNING
      VALUE(rv_html) TYPE string .
  METHODS build_html_parsing_response
    IMPORTING
      !iv_input      TYPE string
      !iv_respid     TYPE zcai_ai_resp_id
    RETURNING
      VALUE(rv_html) TYPE string .
  METHODS build_banner
    CHANGING
      !ct_banner TYPE ztca_response_table .
  METHODS build_html
    IMPORTING
      VALUE(iv_input_request) TYPE string OPTIONAL
      !iv_response_content    TYPE string OPTIONAL
      !iv_option_selected     TYPE char10 OPTIONAL
      !it_context_code        TYPE seop_source_string OPTIONAL
      !iv_conv_identifier     TYPE string OPTIONAL
    RETURNING
      VALUE(ct_table)         TYPE ztca_response_table .
  METHODS build_request_html_tag
    IMPORTING
      !iv_input       TYPE string
    CHANGING
      VALUE(ct_table) TYPE ztca_response_table .
  METHODS build_response_html_tag
    IMPORTING
      !iv_input           TYPE string
      !iv_option_selected TYPE char10 OPTIONAL
      !iv_respid          TYPE zcai_ai_resp_id
    CHANGING
      !ct_table           TYPE ztca_response_table .
  METHODS show_html
    CHANGING
      !it_html_table  TYPE ztca_response_table
      !io_html_viewer TYPE REF TO cl_gui_html_viewer
      !cv_url         TYPE char1024 .
  METHODS create_custom_container
    IMPORTING
      !iv_name           TYPE char100
    RETURNING
      VALUE(eo_instance) TYPE REF TO cl_gui_custom_container .
  METHODS get_ai_utililty
    RETURNING
      VALUE(ro_aiutil) TYPE REF TO zifca_abap_assist_aiutil .
  METHODS split_lines
    IMPORTING
      !iv_text  TYPE string
    EXPORTING
      !et_lines TYPE string_table .
  METHODS build_stylesheet
    CHANGING
      !ct_stylesheet_tags TYPE ztca_response_table .
  METHODS build_startup_tiles
    CHANGING
      !ct_output TYPE ztca_response_table .
  METHODS build_code_string
    RETURNING
      VALUE(rv_code_string) TYPE string .
  METHODS code_review
    IMPORTING
      !iv_from_pbo TYPE abap_bool OPTIONAL .
  METHODS suggest_code_improvement
    IMPORTING
      !iv_from_pbo TYPE abap_bool OPTIONAL .
  METHODS translate
    IMPORTING
      !iv_from_pbo TYPE abap_bool OPTIONAL .
  METHODS abap_unit_test
    IMPORTING
      !iv_from_pbo TYPE abap_bool OPTIONAL .
  CLASS-METHODS get_pict_tab
    IMPORTING
      !mime_url       TYPE csequence
    RETURNING
      VALUE(pict_tab) TYPE pict_tab .
  METHODS build_feedback_bar
    IMPORTING
      !iv_conv_identifier TYPE zcai_ai_resp_id OPTIONAL
    CHANGING
      !ct_output          TYPE ztca_response_table .
  METHODS build_conversation
    IMPORTING
      !iv_request         TYPE string
      !iv_response        TYPE string
      !iv_conv_identifier TYPE string OPTIONAL
    EXPORTING
      !et_output          TYPE ztca_response_table .
  METHODS build_nav_menu
    CHANGING
      !ct_table TYPE ztca_response_table .
  METHODS build_main_container
    IMPORTING
      VALUE(iv_input_request) TYPE string OPTIONAL
      !iv_response_content    TYPE string OPTIONAL
      !iv_option_selected     TYPE char10 OPTIONAL
      !it_context_code        TYPE seop_source_string OPTIONAL
      !iv_conv_identifier     TYPE string OPTIONAL
    CHANGING
      VALUE(ct_table)         TYPE ztca_response_table .
ENDCLASS.



CLASS ZCLCA_ABAP_ASSIST_UI IMPLEMENTATION.


  METHOD abap_unit_test.

    DATA: lv_prompt   TYPE string,
          ls_response TYPE zifca_abap_assist_aiutil=>type_response.

    lv_prompt = TEXT-006.

    IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
       zclca_abap_assist_ui=>gv_sendrequest IS INITIAL AND
       iv_from_pbo IS INITIAL.
      zclca_abap_assist_ui=>gv_inprocess = abap_true.
    ELSE.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      get_ai_utililty( )->execute_user_action(
       EXPORTING
         iv_prompt         = lv_prompt
         iv_option         = 'aut'
         iv_current_source = build_code_string( )
         iv_llm_model = gv_llm_model
         is_trkey = gs_trkey
       RECEIVING
         rs_response         = ls_response
         ).
    ENDIF.

    gt_html = build_html(
                iv_input_request    = lv_prompt
                iv_response_content = ls_response-response
                iv_conv_identifier  = ls_response-identifier
              ).

    show_html( CHANGING it_html_table  = gt_html
                        io_html_viewer = go_html_viewer
                        cv_url         = gv_url ).

  ENDMETHOD.


  METHOD build_banner.
    DATA: ls_user03 TYPE usr03.

    CALL FUNCTION 'SUSR_SHOW_USER_DETAILS'
      EXPORTING
        bname      = sy-uname
        mandt      = sy-mandt
        no_display = abap_true
      CHANGING
        user_usr03 = ls_user03.

    APPEND |<div class = "welcome-banner" ><h1 class = "gradient-text" > Hello, | &
           |{ ls_user03-name1 }| & |</h1></div>| TO ct_banner.

  ENDMETHOD.


  METHOD build_code_block.

    DATA: lv_code        TYPE char200,
          lv_code_string TYPE string,
          lv_codeonly    TYPE string.

    DATA: lv_chunk  TYPE string,
          lv_offset TYPE i,
          lv_length TYPE i.

    " Split the string by line breaks (manual approach)
    DATA: lt_code_lines TYPE TABLE OF string,
          lv_line       TYPE string,
          lv_remaining  TYPE string.

    lv_remaining = iv_code.

    split_lines(
      EXPORTING
        iv_text  =  iv_code
      IMPORTING
        et_lines = lt_code_lines ).

    gv_codecounter = gv_codecounter + 1.
    CONDENSE gv_codecounter.

    DATA(code_style) = `<pre><code class="coding-block">`.
    rv_html = rv_html && code_style.

    rv_html = rv_html && |<div class="code-bar">|.
    rv_html = rv_html && |<span>ABAP</span>|.

    CONCATENATE rv_html '<a href="SAPEVENT:COPY?'  gv_codecounter  '|' iv_respid
                '"><button class="rounded-button">Copy</button></a>' INTO rv_html.

    IF gv_abap_displaymode = 'A' AND gv_fullscreen = abap_false.
      CONCATENATE rv_html '&nbsp<a href="SAPEVENT:ACCEPT?'  gv_codecounter '|' iv_respid
                  '"><button class="rounded-button">Accept</button></a>' INTO rv_html.
    ENDIF.
    rv_html = rv_html && |</div>|.

    LOOP AT lt_code_lines INTO lv_line.
      CONCATENATE  rv_html  lv_line '<br>' INTO rv_html.
    ENDLOOP.

    APPEND VALUE #( id = gv_codecounter
                    code = lt_code_lines ) TO gt_code.

    rv_html = rv_html && `</code></pre>`.

  ENDMETHOD.


  METHOD build_code_string.
    LOOP AT gt_selected_code INTO DATA(ls_selected_code).
      CONCATENATE rv_code_string ls_selected_code INTO rv_code_string.
    ENDLOOP.
  ENDMETHOD.


  METHOD build_collapsing_button.

    APPEND |<button class="collapse-btn left-box"">☰</button>| TO ct_table.
    APPEND |<button class="expand-btn left-box"">☰</button><br>| TO ct_table.

  ENDMETHOD.


  METHOD build_conversation.

    DATA : lt_output         TYPE ztca_response_table,
           ls_output         TYPE char200,
           lt_request_lines  TYPE ztca_response_table,
           lt_response_lines TYPE ztca_response_table,
           lv_response_temp  TYPE string.

    TYPES:
      BEGIN OF type_cache_conv,
        request  TYPE string,
        response TYPE string,
      END OF type_cache_conv .
    TYPES:
      type_t_cache_conv TYPE STANDARD TABLE OF type_cache_conv.

    DATA: lt_cache_conv TYPE type_t_cache_conv,
          lo_ai_logger  TYPE REF TO zclca_ai_logger.

    lo_ai_logger ?= zclca_ai_logger=>get_instance( gv_convo_id ).
    IF lo_ai_logger IS BOUND.
      DATA(ls_req_response) = lo_ai_logger->zif_ai_logger~get_req_resp( ).
    ENDIF.
    DATA(lt_req_response) = ls_req_response-t_req_resp.
    "Check to see the history
    IF lt_req_response IS NOT INITIAL.
      LOOP AT lt_req_response INTO DATA(ls_cache_conv).
        CLEAR lt_request_lines.
***
        " Build User Prompt block
***
        CLEAR ls_output.
        IF ls_cache_conv-request_string IS NOT INITIAL.
          build_request_html_tag( EXPORTING iv_input = ls_cache_conv-request_string
                                  CHANGING  ct_table = lt_request_lines ).
          APPEND LINES OF lt_request_lines TO et_output.
        ENDIF.

** Build the response block

        IF ls_cache_conv-response_string IS INITIAL.
          CLEAR: ls_output.
***
          " Build the deafult response text
***
          lv_response_temp = TEXT-007.
          build_response_html_tag( EXPORTING iv_input = lv_response_temp
                                             iv_option_selected = ''
                                             iv_respid = ls_cache_conv-resp_id
                                  CHANGING ct_table = lt_response_lines ).
          APPEND LINES OF lt_response_lines TO et_output.
        ELSE.
***
          " Build the response block from the service
***
          CLEAR: ls_output.
          build_response_html_tag( EXPORTING iv_input = ls_cache_conv-response_string
                                             iv_option_selected = ''
                                             iv_respid = ls_cache_conv-resp_id
                                  CHANGING ct_table = lt_response_lines ).
          APPEND LINES OF lt_response_lines TO et_output.

          build_feedback_bar( EXPORTING iv_conv_identifier = ls_cache_conv-resp_id
                              CHANGING ct_output = et_output ).
        ENDIF.
      ENDLOOP.
    ENDIF.

***
    " Build User Prompt block
***
    CLEAR: ls_output, lt_request_lines.
    IF iv_request IS NOT INITIAL AND iv_response IS INITIAL.
      build_request_html_tag( EXPORTING iv_input = iv_request
                              CHANGING  ct_table = lt_request_lines ).
      APPEND LINES OF lt_request_lines TO et_output.
      IF zclca_abap_assist_ui=>gv_sendrequest IS INITIAL.
        ls_output =  |<div class="left-box"><h6 class="gradient-text">ABAP Assist:</h6>|.
        APPEND ls_output TO et_output.

***
        " Build the Loading dots
***
        ls_output =  |<div class="loading-dots"><div class ="row-box-normal"><span></span><span></span><span></span></div></div></div>|.
        APPEND ls_output TO et_output.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD build_explanation_block.

    DATA: lv_chunk  TYPE string,
          lv_html   TYPE string,
          lv_offset TYPE i,
          lt_lines  TYPE STANDARD TABLE OF string,
          lv_length TYPE i.

    split_lines(
      EXPORTING
        iv_text  = iv_code
      IMPORTING
        et_lines = lt_lines                 " Table of Strings
    ).

    LOOP AT lt_lines INTO DATA(ls_line).
      REPLACE ALL OCCURRENCES OF '*' IN ls_line WITH ''.
      REPLACE ALL OCCURRENCES OF '`' IN ls_line WITH ''.
      rv_html = rv_html && ls_line.
    ENDLOOP.

    rv_html = rv_html && lv_html.

  ENDMETHOD.


  METHOD build_feedback_bar.


    APPEND '<br/><div class="like-dislike-container"><a href="SAPEVENT:LIKE?' && iv_conv_identifier && '"><button class="like-dislike-button" id="likeButton">' TO ct_output.
    APPEND '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="256" height="256" viewBox="0 0 256 256" xml:space="preserve">' TO ct_output.
    APPEND '<defs></defs><g style="stroke: none; stroke-width: 0; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: none;' TO ct_output.
    APPEND ' fill-rule: nonzero; opacity: 1;" transform="translate(1.4065934065934016 1.4065934065934016) scale(2.81 2.81)" >' TO ct_output.
    APPEND '<circle cx="45" cy="45" r="45" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; ' TO ct_output.
    APPEND 'fill: rgb(26,198,26); fill-rule: nonzero; opacity: 1;" transform="  matrix(1 0 0 1 0 0) "/>' TO ct_output.
    APPEND '<path d="M 20.142 66.312 h 10.208 c 0.795 0 1.44 -0.645 1.44 -1.44 V 37.665 c 0 -0.795 -0.645 -1.44 -1.44 -1.44 H 20.142 V 66.312 z" style="stroke: none; ' TO ct_output.
    APPEND 'stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,255,255); fill-rule: nonzero; opacity: 1;"' TO ct_output.
    APPEND 'transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />' TO ct_output.
    APPEND '<path d="M 66.094 43.729 c 2.079 0 3.764 -1.685 3.764 -3.764 c 0 -2.079 -1.685 -3.764 -3.764 -3.764 h -11.93 c 2.076 -3.739 2.139 -15.096 -2.787 -16.46 c -0.933' TO ct_output.
    APPEND ' -0.258 -1.859 0.454 -1.963 1.417 c -0.866 7.97 -5.742 17.877 -10.7 18.164 h -3.862 v 23.755 h 2.003 c 1.078 0 2.108 0.368 3.008 0.963 c 2.245 1.486 6.025 2.356 9.648 2.265' TO ct_output.
    APPEND ' h 1.752 v 0.006 h 12.036 c 2.079 0 3.764 -1.685 3.764 -3.764 s -1.685 -3.764 -3.764 -3.764 h 1.678 c 2.079 0 3.764 -1.685 3.764 -3.764 c 0 -2.079 -1.685 -3.764 -3.764 -3.764 h 1.118' TO ct_output.
    APPEND ' c 2.079 0 3.764 -1.685 3.764 -3.764 S 68.173 43.729 66.094 43.729 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: ' TO ct_output.
    APPEND 'miter; stroke-miterlimit: 10; fill: rgb(255,255,255); fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />' TO ct_output.
    APPEND '</g></svg></button></a>' TO ct_output.

    APPEND '<a href="SAPEVENT:DISLIKE?' && iv_conv_identifier && '"><button class="like-dislike-button" id="dislikeButton">' TO ct_output.
    APPEND '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" width="256" height="256" viewBox="0 0 256 256" xml:space="preserve">' TO ct_output.
    APPEND '<defs></defs><g style="stroke: none; stroke-width: 0; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: none; fill-rule:' TO ct_output.
    APPEND 'nonzero; opacity: 1;" transform="translate(1.4065934065934016 1.4065934065934016) scale(2.81 2.81)" >' TO ct_output.
    APPEND '<circle cx="45" cy="45" r="45" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill:' TO ct_output.
    APPEND 'rgb(178,22,22); fill-rule: nonzero; opacity: 1;" transform="  matrix(1 0 0 1 0 0) "/><path d="M 20.1 27.7 h 10.2 c 0.8 0 1.4 0.6 1.4 1.4 v 27.2 c 0 0.8 -0.6 1.4 -1.4 1.4 H 20.1' TO ct_output.
    APPEND 'V 27.7 z" style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,255,255); fill-rule: ' TO ct_output.
    APPEND 'nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" />	<path d="M 66.1 50.3 c 2.1 0 3.8 1.7 3.8 3.8 s -1.7 3.8 -3.8 3.8 H 54.2 c 2.1 3.7 2.1 15.1' TO ct_output.
    APPEND ' -2.8 16.5 c -0.9 0.3 -1.9 -0.5 -2 -1.4 c -0.9 -8 -5.7 -17.9 -10.7 -18.2 h -3.9 V 30.9 h 2 c 1.1 0 2.1 -0.4 3 -1 c 2.2 -1.5 6 -2.4 9.6 -2.3 h 1.8 v 0 h 12' TO ct_output.
    APPEND '  c 2.1 0 3.8 1.7 3.8 3.8 s -1.7 3.8 -3.8 3.8 H 65 c 2.1 0 3.8 1.7 3.8 3.8 s -1.7 3.8 -3.8 3.8 h 1.1 c 2.1 0 3.8 1.7 3.8 3.8 S 68.2 50.3 66.1 50.3 z" ' TO ct_output.
    APPEND ' style="stroke: none; stroke-width: 1; stroke-dasharray: none; stroke-linecap: butt; stroke-linejoin: miter; stroke-miterlimit: 10; fill: rgb(255,255,255); ' TO ct_output.
    APPEND ' fill-rule: nonzero; opacity: 1;" transform=" matrix(1 0 0 1 0 0) " stroke-linecap="round" /></g></svg>' TO ct_output.
    APPEND '</button></a></div>' TO ct_output.

  ENDMETHOD.


  METHOD build_html.

    DATA : lt_output              TYPE ztca_response_table,
           ls_output              TYPE char200,
           lt_banner              TYPE ztca_response_table,
           lt_request_lines       TYPE ztca_response_table,
           lt_response_lines      TYPE ztca_response_table,
           lv_response_temp       TYPE string,
           lv_explain_code_prompt TYPE string.

***
    " HTML Header Tags
***
    ls_output = '<html><head><title>ABAP AI Code Gen</title>'.
    APPEND ls_output TO lt_output.

    build_script( CHANGING ct_table = lt_output ).

    APPEND |</head>| TO lt_output.
***
    " Style sheet for the HTML
***
    build_stylesheet( CHANGING ct_stylesheet_tags = lt_output ).

    CLEAR ls_output.
    ls_output = '<body><div class="container">'.
    APPEND ls_output TO lt_output.


*1. Nav Menus(Contains Chat History and New Conversation options)
    build_nav_menu( CHANGING ct_table = lt_output ).

*2. Container(contains everything else)
    build_main_container(
      EXPORTING
        iv_input_request    = iv_input_request
        iv_response_content = iv_response_content
        iv_option_selected  = iv_option_selected  " Character Field with Length 10
        it_context_code     = it_context_code
        iv_conv_identifier  = iv_conv_identifier
      CHANGING
        ct_table            = lt_output " Schedule Failure Log: User-Defined Text of Multiple Messages
    ).

***
    ls_output = '</div></body></html>'.
    APPEND ls_output TO lt_output.

    ct_table = lt_output.

  ENDMETHOD.


  METHOD build_html_parsing_response.

    DATA: lv_code_start  TYPE i,
          lv_code_end    TYPE i,
          lv_offset      TYPE i,
          lv_length      TYPE i,
          lv_code        TYPE string,
          lv_explanation TYPE string,
          lv_remaining   TYPE string,
          lv_input       TYPE string.

    lv_input = iv_input.

    rv_html = rv_html && |<div class="left-box"><h6 class="gradient-text">ABAP Assist:</h6>|.

    rv_html = rv_html && |<div class="message-block">|.

    WHILE lv_input IS NOT INITIAL.
      lv_code_start = find( val = lv_input sub = '```abap' ).

      IF lv_code_start >= 0.
        IF lv_code_start > 0.
          lv_explanation = substring( val = lv_input off = 0 len = lv_code_start ).
          IF lv_explanation IS NOT INITIAL.
            rv_html = rv_html && build_explanation_block( iv_code = lv_explanation ).
          ENDIF.
        ENDIF.

        lv_code_end = find( val = lv_input sub = '```' off = lv_code_start + strlen( '```abap' ) ).

        IF lv_code_end > 0.
          lv_offset = lv_code_start + 7.
          lv_length = lv_code_end - lv_code_start - 7.
          lv_code = substring( val = lv_input off = lv_offset len = lv_length ).
          rv_html = rv_html && build_code_block( iv_code = lv_code iv_respid = iv_respid ).

          lv_remaining = substring( val = lv_input off = lv_code_end + 3 ).
          lv_input = lv_remaining.
        ELSE.
          rv_html = rv_html && '<p>Error: Unclosed code block found.</p>'.
          EXIT.
        ENDIF.

      ELSE.
        rv_html = rv_html && build_explanation_block( iv_code = lv_input ).
        lv_input = ''.
        EXIT.
      ENDIF.
    ENDWHILE.
    rv_html = rv_html && |</div></div><br/>|.

  ENDMETHOD.


  METHOD build_main_container.

    DATA: ls_output    LIKE LINE OF ct_table,
          lo_ai_logger TYPE REF TO zclca_ai_logger.

    lo_ai_logger ?= zclca_ai_logger=>get_instance( gv_convo_id ).
    IF lo_ai_logger IS BOUND.
      DATA(ls_req_response) = lo_ai_logger->zif_ai_logger~get_req_resp( ).
    ENDIF.

    CLEAR ls_output.
    ls_output = '<div class="outercontainer"><div class="main-container">'.
    APPEND ls_output TO ct_table.

    build_model_dropdown( CHANGING ct_table = ct_table ).

***
    " Banner HTML tag
***
    build_banner( CHANGING ct_banner = ct_table ).

    IF iv_input_request IS INITIAL AND iv_response_content IS INITIAL
      AND ls_req_response-t_req_resp IS INITIAL.
      build_startup_tiles( CHANGING ct_output = ct_table ).
    ENDIF.

*** Build conversation

    build_conversation(
      EXPORTING
        iv_request  = iv_input_request
        iv_response = iv_response_content
        iv_conv_identifier = iv_conv_identifier
      IMPORTING
        et_output   = DATA(lt_response_lines)                 " Table of Strings
    ).
    APPEND LINES OF lt_response_lines TO ct_table.

    ls_output = '</div>'.
    APPEND ls_output TO ct_table.

*** Build Feedback bar
*
*    IF iv_response_content IS NOT INITIAL AND gv_sendrequest IS NOT INITIAL.
*      build_feedback_bar( EXPORTING iv_conv_identifier = iv_conv_identifier CHANGING ct_output = ct_table ).
*    ENDIF.

* Build input box **
    "Build the HTML closing tags
    ls_output = `<div class="input-container" style="max-width: 99%;"> <textarea id="promptInput" class="input-box"`.
    APPEND ls_output TO ct_table.
    ls_output =  `placeholder="Enter your prompt here..." rows="2"></textarea>`.
    APPEND ls_output TO ct_table.
    ls_output = `<button id="sendButton" class="send-button" onClick="sendInput();"><svg xmlns="http://www.w3.org/2000/svg" `.
    APPEND ls_output TO ct_table.
    ls_output = `viewBox="0 0 20 20" fill="currentColor" class="send-icon">`.
    APPEND ls_output TO ct_table.
    ls_output = `<path d="M10.894 2.553a1 1 0 0 0-1.788 0l-7 7a1 1 0 0 0 1.167 1.282L10 5.233l6.531 5.602a1 1 0 0 0 1.167-1.282l-7-7z" />`.
    APPEND ls_output TO ct_table.
    ls_output = `</svg></button></div>`.
    APPEND ls_output TO ct_table.
    ls_output = `*LLMs can make mistakes. Consider double-checking responses before implementing any changes in your system.`.

    " Build the Div closing tags
***
    ls_output = '</div>'.
    APPEND ls_output TO ct_table.

  ENDMETHOD.


  METHOD build_model_dropdown.
  ENDMETHOD.


  METHOD build_nav_menu.

    DATA: ls_output LIKE LINE OF ct_table.
    APPEND |<div class = "navbar">| TO ct_table.
    build_collapsing_button( CHANGING ct_table = ct_table ).
    build_new_chat_button( CHANGING ct_table = ct_table ).
    build_recent_chat_menu( CHANGING ct_table = ct_table ).
    APPEND |</div>| TO ct_table.

  ENDMETHOD.


  METHOD build_new_chat_button.
    APPEND |<div class="nav-items"><a href="SAPEVENT:QA?NEWCHAT"><button class="rounded-button left-box"> +  New Chat</button></a></div>| TO ct_table.
  ENDMETHOD.


  METHOD build_recent_chat_menu.

    DATA: lt_chat   TYPE zclca_ai_logger=>zif_ai_logger~gty_t_convo,
          lv_length TYPE int4.


    DATA(lt_chat_history) = zclca_ai_logger=>zif_ai_logger~get_convo_history( ).
    APPEND LINES OF lt_chat_history FROM 1 TO 6 TO lt_chat.
    IF lt_chat IS NOT INITIAL.
      LOOP AT lt_chat INTO DATA(ls_chat_history) WHERE t_req_resp IS NOT INITIAL.
        IF sy-tabix = 1.
          APPEND |<ul class="recent-list"><h6>Recent</h6>| TO ct_table.
        ENDIF.
        lv_length = strlen( ls_chat_history-t_req_resp[ 1 ]-request_string ).
        IF lv_length > 35.
          lv_length = 35.
        ENDIF.
        DATA(lv_str) = ls_chat_history-t_req_resp[ 1 ]-request_string.
        lv_str = lv_str(lv_length).
        lv_str = lv_str && |...|.
        APPEND |<li><a href="SAPEVENT:RECENTCHAT?{ ls_chat_history-convo_id }"><button class="recent-list-item">{ lv_str  }</button></a></li><br/>| TO ct_table.
        CLEAR: lv_length, lv_str.
      ENDLOOP.
      APPEND |</ul>| TO ct_table.
    ENDIF.

  ENDMETHOD.


  METHOD build_request_html_tag.

    DATA: lv_output  TYPE char200.
    DATA(lt_request_table) = split_string_to_table( EXPORTING iv_string  = iv_input ).

    lv_output = |<br/><div class="right-box"><div class="message user-message"><div class="message-content">| .
    APPEND lv_output TO ct_table.
    CLEAR lv_output.
    APPEND LINES OF lt_request_table TO ct_table.
    lv_output = |</div></div></div>|.
    APPEND lv_output TO ct_table.

  ENDMETHOD.


  METHOD build_response_html_tag.

    IF iv_input IS NOT INITIAL.
      DATA(lv_response_str) =  build_html_parsing_response( EXPORTING iv_input = iv_input iv_respid = iv_respid ).
    ENDIF.

    ct_table = split_string_to_table( iv_string = lv_response_str ).

  ENDMETHOD.


  METHOD build_script.

    APPEND `<script>` TO ct_table.
    APPEND `window.addEventListener('load', function() {` TO ct_table.
    APPEND `setTimeout(function() {` TO ct_table.
    APPEND `const mainContainer = document.querySelector('.main-container');` TO ct_table.
    APPEND `if (mainContainer) {` TO ct_table.
    APPEND `mainContainer.scrollTop = mainContainer.scrollHeight;` TO ct_table.
    APPEND `} }, 30);` TO ct_table.
    APPEND `});` TO ct_table.
    APPEND `function setMessageInput(template) {` TO ct_table.
    APPEND `document.getElementById('promptInput').value = template; }` TO ct_table.

    APPEND `document.addEventListener('DOMContentLoaded', function() {` TO ct_table.
    APPEND `const navbar = document.querySelector('.navbar');` TO ct_table.
    APPEND `const collapseBtn = document.querySelector('.collapse-btn');` TO ct_table.
    APPEND `const expandBtn = document.querySelector('.expand-btn');` TO ct_table.
    APPEND `const promptInput = document.getElementById('promptInput');` TO ct_table.

    APPEND `collapseBtn.addEventListener('click', () => {` TO ct_table.
    APPEND `navbar.classList.add('collapsed');` TO ct_table.
    APPEND `});` TO ct_table.
    APPEND `expandBtn.addEventListener('click', () => {` TO ct_table.
    APPEND `navbar.classList.remove('collapsed');` TO ct_table.
    APPEND `}); ` TO ct_table.

    APPEND `const recentListItems = document.querySelectorAll('.recent-list-item');` TO ct_table.
    APPEND `recentListItems.forEach(item => {` TO ct_table.
    APPEND `item.addEventListener('click', function() {` TO ct_table.
    APPEND `recentListItems.forEach(i => i.classList.remove('selected')); ` TO ct_table.
    APPEND `this.classList.add('selected'); ` TO ct_table.
    APPEND `}); ` TO ct_table.
    APPEND `}); ` TO ct_table.

    APPEND `promptInput.addEventListener('input', function() { ` TO ct_table.
    APPEND `this.style.height = 'auto'; ` TO ct_table.
    APPEND `this.style.overflowY = 'hidden';` TO ct_table.
    APPEND `this.style.height = (this.scrollHeight) + 'px';` TO ct_table.

    APPEND `const lineHeight = parseFloat(window.getComputedStyle(this).lineHeight);` TO ct_table.
    APPEND `const fontSize = parseFloat(window.getComputedStyle(this).fontSize);` TO ct_table.
    APPEND `const estimatedLineHeight = lineHeight || fontSize * 1.5;` TO ct_table.

    APPEND `const maxHeight = estimatedLineHeight * 8;` TO ct_table.

    APPEND `if (this.scrollHeight > maxHeight) { ` TO ct_table.
    APPEND `this.style.height = maxHeight + 'px'; ` TO ct_table.
    APPEND `this.style.overflowY = 'auto'; ` TO ct_table.
    APPEND `}` TO ct_table.
    APPEND `});` TO ct_table.
    APPEND `});` TO ct_table.
    APPEND `function sendInput(){const inputValue = document.getElementById("promptInput").value;` TO ct_table.
    APPEND `const sapEventURL = "SAPEVENT:GENERATE?" + ` TO ct_table.
    APPEND `inputValue ;window.location.href = sapEventURL; }` TO ct_table.
    APPEND `</script>` TO ct_table.
  ENDMETHOD.


  METHOD build_startup_tiles.

    SELECT * FROM zca_prompt_templ
        INTO TABLE gt_templates.

    APPEND |<div class="welcome-box-container">Level up your coding. Get the help you need in ABAP to build your projects and learn as you go.</div><br/>|
    TO ct_output.

    APPEND '<div class="welcome-box-container">' TO ct_output.

    LOOP AT gt_templates ASSIGNING FIELD-SYMBOL(<ls_template>).
      APPEND `<button class="welcome-box" onclick="setMessageInput('`
      && <ls_template>-template
      && `');">`
      && <ls_template>-description && '</button>' TO ct_output.
    ENDLOOP.

    APPEND '</div><br/><br/>' TO ct_output.

    IF gv_fullscreen = abap_false.
      APPEND '<h4 class="gradient-text">Quick action</h4>' TO ct_output.
      APPEND '<div class="welcome-box-container">' TO ct_output.
      APPEND '<a href="SAPEVENT:QA?G_EXPLAIN"><button class="rounded-button">Explain code</button></a>' TO ct_output.
      APPEND '<a href="SAPEVENT:QA?G_REVIEW"><button class="rounded-button">Review code</button></a>' TO ct_output.
      APPEND '<a href="SAPEVENT:QA?G_SUGGEST"><button class="rounded-button">Suggest Improvements</button></a>' TO ct_output.
      APPEND '<a href="SAPEVENT:QA?G_AUT"><button class="rounded-button">Write ABAP Unit test</button></a></div>' TO ct_output.
    ENDIF.
  ENDMETHOD.


  METHOD build_stylesheet.

    DATA: lv_text TYPE char200.

    lv_text = '<style>'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='html, body { height: 100%; margin: 0; box-sizing: border-box; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'body{ font-family: Roboto, Arial, Helvetica; line-height: 1.5; font-size: 0.8rem; background-color: transparent; margin: 0; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'h1{ font-family: Roboto, sans-serif; font-weight: 700; margin-bottom: 0.5em; font-size: 2.6em; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'h4{ font-family: Roboto, sans-serif; font-weight: 600 ; margin-bottom: 0.5em; font-size: 1.6em; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'h5 {font-family: Roboto, sans-serif; font-weight: 600; margin-bottom: 0.5em;  font-size: 1.5em;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'h6 {font-family: Roboto ;font-weight: 100; margin-bottom: 0.5em;  font-size: 1.25em;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'p, ul, li  { font-size: 0.7rem;  margin: 0 auto;  word-wrap: break-word;} .left-aligned-div { text-align: left; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar {  width: 270px; height: 100%; background-color: #e9e9e9;  border-right: 1px solid #ccc;  transition: width 0.3s ease;  overflow: hidden; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar.collapsed {  width: 40px; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar .collapse-btn,.navbar .expand-btn {  cursor: pointer;  padding: 10px;  background-color: #e9e9e9;  border: none;  width: 100%;  text-align: left;} '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar .expand-btn {  display: none;} .navbar.collapsed .collapse-btn {  display: none; } .navbar.collapsed .expand-btn {  display: block; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar .nav-items {  padding: 5px; } .navbar.collapsed .nav-items {  display: none; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.recent-list { list-style: none; padding: 5;  margin: 0;} '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.recent-list-item {  padding: 8px 12px;  cursor: pointer; border: none; border-radius: 4px; background-color: #e9e9e9;  transition: background-color 0.2s ease; text-align: left;} '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.recent-list-item:hover {  background-color: rgba(0, 0, 0, 0.1);} .recent-list-item.selected { background-color: #e8f0fe;  color: #1a73e8;} '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.navbar.collapsed .recent-list{  display: none; } .navbar.collapsed .recent-list-item{  display: none; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.container { display: flex; flex-direction: row; width: 100%; height: 100%;  align-items: flex-start;  }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.outercontainer { display: flex; flex-direction: column; width: 100%; height: 100%; justify-content: space-between; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.main-container { display: flex; flex-direction: column; width: 100%; height: 100%; flex: 1; overflow-y: auto; justify-content: flex-start;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'box-sizing: border-box; align-items: center; } .main-container > * { flex-shrink: 0;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' .right-box { display: flex; flex-direction: column; width: 100%; box-sizing: border-box; align-items: flex-end;  text-align: right; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' .left-box { display: flex; flex-direction: column; width: 100%; box-sizing: border-box; align-items: flex-start; padding:30px }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' .row-box-normal { display: flex; flex-direction: row; width: 100%; align-items: center;  }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.welcome-banner { text-align: center; margin-bottom: 20px; padding: 10px; border-radius: 8px 8px 0 0;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.welcome-box-container { display: flex; gap: 20px; justify-content: center; align-items: center; font-size: 1.25rem; font-family: Nunito Sans, sans-serif;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.welcome-box {background-color: #e0e0e0; border-radius: 8px; padding: 15px; width: 200px; text-align: center; font-size: 0.9rem; '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.1); cursor: pointer; transition: transform 0.2s ease, box-shadow 0.2s ease; border-color: #e0e0e0;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.welcome-box:hover { transform: translateY(-5px); box-shadow: 4px 4px 8px rgba(0, 0, 0, 0.15); }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.rounded-button { display: inline-block; font-size: 0.9rem;  padding: 8; text-align: center; text-decoration: none;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'cursor: pointer; border: none; border-radius: 25px; background-color: #2196F3; color: white; transition: background-color 0.3s ease, transform 0.2s ease;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'white-space: nowrap;border: none; border-radius: 4px; cursor: pointer; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.small-button.default { background-color: #007bff; color: white; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.gradient-text { font-family: Nunito Sans, sans-serif;  font-weight: 600;  font-style: normal;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' background-image: linear-gradient(to right, #4980FF, #A059FF, #FF5757);'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '-webkit-background-clip: text; -webkit-text-fill-color: transparent; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.message { display: flex; align-items: flex-start; margin-bottom: 0.5em  }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.user-message { justify-content: flex-end;  width: 95%; max-width: 100%;}'.  "Key Change 1
    APPEND lv_text TO ct_stylesheet_tags.

    "
    CLEAR lv_text.
    lv_text = '.user-message .message-content { background-color: #e9ecef;  color: black;  border-radius: 12px 12px 12px 12px;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'overflow-x: hidden; word-wrap: break-word; width: 95%; max-width: 100%; box-sizing: border-box; padding: 12px }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.message-block {  background-color: #e9ecef;  width: 95%; max-width: 100%; box-sizing: border-box; overflow-x: hidden; word-wrap: break-word;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'border-radius: 12px 12px 12px 12px; font-family: Roboto, Arial, Helvetica; line-height: 1.5;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'padding: 12px; box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1); }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='.loading-dots { display: inline-block; width: 6em; height: 6em; text-align: center; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='.loading-dots span { display: block; vertical-align: middle; width: 1.25em; height: 1.25em; margin: 0 0.2em;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='background-color: #999;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='border-radius: 50%;opacity: 0;animation: dot-pulse 1.5s infinite;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='.loading-dots span:nth-child(1) { animation-delay: 0s; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text ='.loading-dots span:nth-child(2) { animation-delay: 0.5s; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.loading-dots span:nth-child(3) { animation-delay: 1s; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =  '@keyframes dot-pulse { 0% { opacity: 0; transform: scale(0.8); }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '50% { opacity: 1; transform: scale(1); }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '100% { opacity: 0; transform: scale(0.8); } }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.button-row { display:flex; gap:10px;  justify-content: flex-end; flex-direction: row; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.coding-block { box-sizing: border-box; display: block; width: 90%; max-width: 100%; overflow-x: hidden; overflow-wrap: break-word;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =  'font-family: Courier New; color: #333; border: 0; border-radius: 0; '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =     'background-color: #d9e9fa; padding: .6em .75em; '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =   ' margin: 1.5em 0; position: static; border-left: .6rem solid #008FD3; white-space: pre-wrap; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =   '.code-bar {display: flex; align-items: center; background-color: #d9e9fa; padding: 8px 12px; display: flex; border-bottom: 1px solid #ccc; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =   '.code-bar span { margin-right: auto; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text =   '.copy-button { background: none; border: none; padding: 0;  cursor: pointer;  } .copy-button-img { width: 20px; height: 20px; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.copy-button img { width: 20px; height: 20px; } '.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.like-dislike-container { display: flex; flex-direction: row; align-items: flex-start; gap: 10px; margin-left: 0; margin-right: auto; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.like-dislike-button { background: none;  border: none; padding: 5px; cursor: pointer; opacity: 0.6; transition: opacity 0.3s ease, transform 0.2s ease; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.like-dislike-button svg { width: 30px;  height: 30px; fill: #888;  }  .like-dislike-button:hover { opacity: 0.8; transform: scale(1.1);  }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.like-dislike-button.active { opacity: 1; } .like-dislike-button.active svg { fill: #007bff;} .like-dislike-button:disabled { opacity: 0.3; cursor: default; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' .input-container {display: flex; align-items: center; border-radius: 0.5rem;'.
    APPEND lv_text TO ct_stylesheet_tags.
    CLEAR lv_text.
    lv_text = 'box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);  margin-top: auto;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = ' border: 1px solid #525252; margin-left: 10px; margin-top: 5px; margin-bottom: 5px;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.input-box { flex: 1; border: none;outline: none;padding: 0.75rem 1rem;font-size: 1rem;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'border-radius: 3rem; background-color: transparent;resize: none; min-height: 2.5rem;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'line-height: 1.4; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.input-box:focus { box-shadow: none; outline: none; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.send-button { padding: 0.5rem; border: none; border-radius: 50%; background-color: #4299e1; color: white; cursor: pointer;'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = 'display: flex;align-items: center;justify-content: center;transition: background-color 0.2s ease; margin-left: 0.5rem; margin-right: 1.0rem; }'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '.send-button:hover { background-color: #3182ce; }.send-icon { width: 1.5rem; height: 1.5rem;}'.
    APPEND lv_text TO ct_stylesheet_tags.

    CLEAR lv_text.
    lv_text = '</style>'.
    APPEND lv_text TO ct_stylesheet_tags.

  ENDMETHOD.


  METHOD code_review.

    DATA: lv_prompt   TYPE string,
          ls_response TYPE zifca_abap_assist_aiutil=>type_response.

    lv_prompt = TEXT-004.

    IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
       zclca_abap_assist_ui=>gv_sendrequest IS INITIAL AND
       iv_from_pbo IS INITIAL.
      zclca_abap_assist_ui=>gv_inprocess = abap_true.
    ELSE.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      get_ai_utililty( )->execute_user_action(
       EXPORTING
         iv_prompt         = lv_prompt
         iv_option         = 'review'
         iv_current_source = build_code_string( )
         iv_llm_model = gv_llm_model
         is_trkey = gs_trkey
       RECEIVING
         rs_response       = ls_response ).
    ENDIF.

    gt_html = build_html(
                iv_input_request    = lv_prompt
                iv_response_content = ls_response-response
                iv_conv_identifier = ls_response-identifier
              ).

    show_html( CHANGING it_html_table  = gt_html
                        io_html_viewer = go_html_viewer
                        cv_url         = gv_url ).

  ENDMETHOD.


  METHOD constructor.

    go_code_gen_ui = me.

  ENDMETHOD.


  METHOD create_custom_container.
    eo_instance = new #( container_name = iv_name ).

  ENDMETHOD.


  METHOD explain_code.

    DATA: lv_prompt   TYPE string,
          ls_response TYPE zifca_abap_assist_aiutil=>type_response.

    lv_prompt = TEXT-003.

    IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
       zclca_abap_assist_ui=>gv_sendrequest IS INITIAL AND
       iv_from_pbo IS INITIAL.
      zclca_abap_assist_ui=>gv_inprocess = abap_true.
    ELSE.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      get_ai_utililty( )->execute_user_action(
       EXPORTING
         iv_prompt         = lv_prompt
         iv_option         = 'explain'
         iv_current_source = build_code_string( )
         iv_llm_model = gv_llm_model
         is_trkey = gs_trkey
       RECEIVING
         rs_response         = ls_response
         ).
    ENDIF.

    gt_html = build_html(
                iv_input_request    = lv_prompt
                iv_response_content = ls_response-response
                iv_conv_identifier =  ls_response-identifier
              ).

    show_html( CHANGING it_html_table  = gt_html
                        io_html_viewer = go_html_viewer
                        cv_url         = gv_url ).

  ENDMETHOD.


  METHOD fill_model_dropdown.

    DATA: lt_list TYPE vrm_values.

    SELECT model_key, model_name FROM zcac_abapast_mdl INTO TABLE @DATA(lt_abap_assist_models).
    IF sy-subrc = 0.

      lt_list = VALUE #( FOR ls_model IN lt_abap_assist_models ( key = ls_model-model_key
                                                                 text = ls_model-model_name ) ).

      CALL FUNCTION 'VRM_SET_VALUES'
        EXPORTING
          id     = 'ZCAC_ABAPAST_MDL-MODEL_KEY'
          values = lt_list.
      IF sy-subrc <> 0.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_ai_utililty.
    go_aiutil = COND #( WHEN go_aiutil IS BOUND
                        THEN go_aiutil
                        ELSE NEW zclca_abap_assist_aiutil( ) ).

    ro_aiutil = go_aiutil.
  ENDMETHOD.


  METHOD get_instance.

    IF go_code_gen_ui IS NOT BOUND.
      go_code_gen_ui = NEW #( ).
    ENDIF.

    ro_instance = go_code_gen_ui.
  ENDMETHOD.


  METHOD get_pict_tab.
    cl_mime_repository_api=>get_api( )->get(
    EXPORTING i_url = mime_url
    IMPORTING e_content = DATA(pict_wa)
    EXCEPTIONS OTHERS = 4 ).
    IF sy-subrc = 4.
      RETURN.
    ENDIF.
    pict_tab =
      VALUE #( LET l1 = xstrlen( pict_wa ) l2 = l1 - 1022 IN
               FOR j = 0 THEN j + 1022  UNTIL j >= l1
                 ( COND #( WHEN j <= l2 THEN
                                pict_wa+j(1022)
                           ELSE pict_wa+j ) ) ).
  ENDMETHOD.


  METHOD llm_model_reselected.
    gv_llm_model = iv_model_key.
  ENDMETHOD.


  METHOD on_sapevent.

    DATA: lt_buffer    TYPE swbse_max_line_tab,
          ls_buffer    TYPE swbse_max_line,
          lv_from_line TYPE i,
          lv_rc        TYPE i.

    DATA: lv_offset      TYPE i,
          lv_length      TYPE i,
          ls_prompt_line TYPE ty_table_line.

    TRY.
        SPLIT getdata AT '|' INTO DATA(lv_codecounter) DATA(lv_respid).
        APPEND LINES OF zclca_abap_assist_ui=>gt_code[ id = lv_codecounter ]-code TO lt_buffer.
      CATCH cx_sy_itab_line_not_found INTO DATA(lobj_error).
    ENDTRY.

    CASE action.
      WHEN gc_fcodes-ongenerate.
        lv_offset = 0.
        WHILE lv_offset < strlen( getdata ).
          IF strlen( getdata ) - lv_offset >= 150.
            lv_length = 150.
          ELSE.
            lv_length = strlen( getdata ) - lv_offset.
          ENDIF.
          ls_prompt_line-line = getdata+lv_offset(lv_length).
          APPEND ls_prompt_line TO gt_prompttable.
          lv_offset = lv_offset + lv_length.
        ENDWHILE.

        IF gt_prompttable IS NOT INITIAL.
          quick_action( iv_action = CONV #( gc_fcodes-enter ) ).
        ENDIF.

      WHEN gc_fcodes-accept.
        zclca_ai_logger=>get_instance( )->zif_ai_logger~log_acceptance(
                                           iv_resp_id = CONV #( lv_respid )
                                           iv_commit = abap_true ).

        go_editor_handle->get_cursor(
          IMPORTING
            cursor_line   = lv_from_line                 " Cursor Line
        ).

        IF lt_buffer IS NOT INITIAL.

          LOOP AT lt_buffer ASSIGNING FIELD-SYMBOL(<ls_bufline>).
            IF <ls_bufline> = cl_abap_char_utilities=>cr_lf.
              <ls_bufline> = ''.
              MODIFY lt_buffer FROM <ls_bufline>.
            ENDIF.
          ENDLOOP.
          pretty_print( CHANGING ct_pattern = lt_buffer ).

          CLEAR gt_prompttable.
          gv_first_time = abap_true.
          CLEAR gt_chat_history.


          go_editor_handle->insert_block(
            EXPORTING
              p_line   = lv_from_line
            CHANGING
              p_buffer = lt_buffer ).

          LEAVE TO SCREEN 0.

        ENDIF.

      WHEN gc_fcodes-copy.
        zclca_ai_logger=>get_instance( )->zif_ai_logger~log_acceptance(
                                           iv_resp_id = CONV #( lv_respid )
                                           iv_commit = abap_true ).
        IF lt_buffer IS NOT INITIAL.
          cl_gui_frontend_services=>clipboard_export(
              EXPORTING
                no_auth_check = space
              IMPORTING
                data          = lt_buffer
              CHANGING
                rc            = lv_rc ).
        ENDIF.
      WHEN gc_fcodes-quick_action.
        quick_action( iv_action = CONV #( getdata ) ).
      WHEN gc_fcodes-template.
        populate_template( iv_template_id = CONV #( getdata ) ).
      WHEN gc_fcodes-like.
        zclca_ai_logger=>get_instance( )->zif_ai_logger~log_feedback(
                                              iv_resp_id = CONV #( getdata )
                                              iv_rating = zif_ai_logger=>gc_rating-thumbs_up ).
      WHEN gc_fcodes-dislike.
        zclca_ai_logger=>get_instance( )->zif_ai_logger~log_feedback(
                                              iv_resp_id = CONV #( getdata )
                                              iv_rating = zif_ai_logger=>gc_rating-thumbs_down ).
      WHEN gc_fcodes-recent_chat.
        prepare_for_recent_chat( CONV #( getdata ) ).
    ENDCASE.

  ENDMETHOD.


  METHOD pai_of_screen_100.
    DATA: lv_request      TYPE string,
          lt_context_code TYPE seop_source_string,
          ls_response     TYPE zifca_abap_assist_aiutil=>type_response,
          lt_html         TYPE ztca_response_table,
          lv_prompt       TYPE string,
          lv_handle       TYPE i.

    CLEAR: gt_chat_history,
           lt_context_code.

    ASSIGN (gc_constants-editor) TO FIELD-SYMBOL(<ls_editor>).
    IF <ls_editor> IS ASSIGNED.
      go_obj ?= <ls_editor>.
    ENDIF.

    ASSIGN (gc_constants-edit) TO FIELD-SYMBOL(<ls_edit>).
    IF <ls_edit> IS ASSIGNED .
      go_editobj ?= <ls_edit>.
    ENDIF.


    CASE iv_ok_code.
      WHEN gc_fcodes-model_select.
      WHEN gc_fcodes-cancel.
        gv_first_time = abap_true.
        CLEAR: gt_prompttable,
              gt_chat_history,
              gt_selected_code,
              gv_sendrequest,
               gv_inprocess.

        IF go_custom_container IS BOUND.
          go_custom_container->free( ).
        ENDIF.

        IF go_input_container IS BOUND.
          go_input_container->free( ).
        ENDIF.

        IF go_html_viewer IS BOUND.
          go_html_viewer->get_mode(
            IMPORTING
              mode              = lv_handle
            EXCEPTIONS
              cntl_error        = 1
              cntl_system_error = 2
              OTHERS            = 3
          ).
          IF sy-subrc = 0.
            go_html_viewer->free( ).
          ENDIF.
        ENDIF.

        CLEAR: go_custom_container, go_html_viewer, go_input_container, go_input_text_editor.
        LEAVE TO SCREEN 0.
      WHEN gc_fcodes-enter.
        CLEAR lv_request.

        IF gt_prompttable IS NOT INITIAL.
          LOOP AT gt_prompttable INTO DATA(ls_promptstring).
            CONCATENATE lv_request ls_promptstring-line INTO lv_request.
          ENDLOOP.

          LOOP AT gt_prompttable ASSIGNING FIELD-SYMBOL(<ls_prompttable>).
            CONCATENATE lv_prompt <ls_prompttable> INTO lv_prompt SEPARATED BY ' '.
          ENDLOOP.

          IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
             zclca_abap_assist_ui=>gv_sendrequest IS INITIAL.
            zclca_abap_assist_ui=>gv_inprocess = abap_true.
          ELSE.
            get_ai_utililty( )->execute_user_action(
             EXPORTING
               iv_prompt         = lv_prompt
               iv_option         = 'chatbot'
               iv_current_source = build_code_string( )
               iv_llm_model      = gv_llm_model
               is_trkey          = gs_trkey
             RECEIVING
               rs_response       = ls_response
               ).
          ENDIF.

          CLEAR lt_html.
          lt_html = build_html( EXPORTING iv_input_request    = lv_request
                                          it_context_code     = lt_context_code
                                          iv_option_selected  = CONV #( gv_node_key )
                                          iv_response_content = ls_response-response
                                          iv_conv_identifier  = ls_response-identifier ).

          show_html( CHANGING it_html_table  = lt_html
                              io_html_viewer = go_html_viewer
                              cv_url         = gv_url ).

          APPEND LINES OF gt_chat_history TO gt_response_table.
          CLEAR lt_html.
          CLEAR gv_first_time.

          IF zclca_abap_assist_ui=>gv_sendrequest IS NOT INITIAL.
            CLEAR zclca_abap_assist_ui=>gv_sendrequest.
          ENDIF.

          IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL.
            cl_gui_cfw=>flush( ).
            CLEAR gt_prompttable.
          ENDIF.
        ENDIF.
      WHEN gc_fcodes-reset OR gc_fcodes-new_chat.
        CLEAR: gt_prompttable,
               gt_chat_history,
               gv_convo_id.
        cl_gui_cfw=>flush( ).
        gv_first_time = 'X'.
        zclca_ai_logger=>free( ).
      WHEN gc_fcodes-resetprompt.
        CLEAR: gt_prompttable,
               gt_html,
               gv_sendrequest,
               gv_inprocess.
        gv_first_time = 'X'.
        zclca_ai_logger=>free( ).
      WHEN gc_fcodes-back.
        CLEAR: gt_prompttable,
               gt_chat_history,
               gt_selected_code.
        gv_first_time = abap_true.
        LEAVE TO SCREEN 0.

      WHEN gc_fcodes-review.
        code_review( ).
      WHEN gc_fcodes-aut.
        abap_unit_test( ).
      WHEN gc_fcodes-explain.
        explain_code( ).
      WHEN gc_fcodes-suggest.
        suggest_code_improvement( ).

      WHEN OTHERS.
    ENDCASE.
  ENDMETHOD.


  METHOD pbo_of_screen_100.
    CONSTANTS: lc_input  TYPE char100 VALUE 'INPUT',
               lc_output TYPE char100 VALUE 'OUTPUT'.
    DATA: lv_ucomm TYPE sy-ucomm.

    IF go_custom_container IS NOT BOUND.
      go_custom_container = create_custom_container( iv_name = lc_output ).
    ENDIF.

**    IF go_html_viewer IS INITIAL.
    IF go_html_viewer IS NOT BOUND.
      go_html_viewer = NEW cl_gui_html_viewer(
          parent                   = go_custom_container
          query_table_disabled     = abap_true ).

      gs_event-eventid = go_html_viewer->m_id_sapevent.
      gs_event-appl_event = 'x'.
      APPEND gs_event TO gt_event.
      go_html_viewer->set_registered_events(
        EXPORTING
          events = gt_event ).

      SET HANDLER on_sapevent
                  FOR go_html_viewer.
    ENDIF.

    IF gv_first_time = abap_true OR gv_abap_fcode = 'EXPLAIN'.
      CLEAR gt_html.
      CASE gv_abap_fcode.
        WHEN gc_fcodes-review.
          code_review( abap_true ).
        WHEN gc_fcodes-aut.
          abap_unit_test( abap_true ).
        WHEN gc_fcodes-explain.
          explain_code( abap_true ).
        WHEN gc_fcodes-suggest.
          suggest_code_improvement( abap_true ).
        WHEN gc_fcodes-translate.
          translate( abap_true ).
        WHEN OTHERS.
          gt_html = build_html( ).

          show_html( CHANGING it_html_table  = gt_html
                              io_html_viewer = go_html_viewer
                              cv_url         = gv_url ).
      ENDCASE.
      CLEAR gt_html.
      CLEAR gv_first_time.
    ENDIF.

    IF zclca_abap_assist_ui=>gv_inprocess = abap_true. " OR gv_abap_fcode = 'EXPLAIN'.
      zclca_abap_assist_ui=>gv_inprocess = abap_false.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      IF sy-ucomm IS INITIAL.
        lv_ucomm =  'ENTER'.
      ELSE.
        lv_ucomm = sy-ucomm.
      ENDIF.
      CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
        EXPORTING
          functioncode = lv_ucomm. "'ENTER'.
    ENDIF.
  ENDMETHOD.


  METHOD populate_template.

    CLEAR: gt_prompttable.
    APPEND  VALUE #( gt_templates[ id = iv_template_id ]-template OPTIONAL ) TO gt_prompttable.

    go_input_text_editor->set_text_as_r3table(
      EXPORTING
        table           =  gt_prompttable
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3
    ).
    IF sy-subrc <> 0.

    ENDIF.
  ENDMETHOD.


  METHOD prepare_for_recent_chat.

    CLEAR: gt_prompttable,
           gt_chat_history.

    gv_first_time = abap_true.
    gv_convo_id = iv_convo_id.

    cl_gui_cfw=>flush( ).

  ENDMETHOD.


  METHOD pretty_print.
    DATA:
      lv_case_mode TYPE string,
      lt_buffer    TYPE rswsourcet,
      wb_settings  TYPE rseumod.

    lt_buffer[] = ct_pattern.

    CALL FUNCTION 'RS_WORKBENCH_CUSTOMIZING'
      EXPORTING
        choice          = 'WB'
        suppress_dialog = abap_true
        disable_wb99    = abap_true
      IMPORTING
        setting         = wb_settings.

    cl_sedi_shared=>map_case_mode( EXPORTING i_wb_settings = wb_settings
                                   IMPORTING e_case_mode   = lv_case_mode ).

    CALL FUNCTION 'CREATE_PRETTY_PRINT_FORMAT'
      EXPORTING
        mode          = lv_case_mode
      TABLES
        source        = lt_buffer
      EXCEPTIONS
        syntax_errors = 0.

    CLEAR ct_pattern.

    ct_pattern = lt_buffer[].
  ENDMETHOD.


  METHOD quick_action.

    CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
      EXPORTING
        functioncode = iv_action.

  ENDMETHOD.


  METHOD show_html.
    DATA: lv_changed TYPE boolean.

    io_html_viewer->load_data(
       EXPORTING
         url              = cv_url
       IMPORTING
         assigned_url     = cv_url
       CHANGING
         data_table       = it_html_table
         iscontentchanged = lv_changed ).

*** Show Url
    io_html_viewer->show_url(
       EXPORTING
         url = cv_url ).

    cl_gui_html_viewer=>set_focus(
       EXPORTING
         control           = io_html_viewer
       EXCEPTIONS
         cntl_error        = 1
         cntl_system_error = 2 ).
  ENDMETHOD.


  METHOD split_lines.
    DATA: lo_regex   TYPE REF TO cl_abap_regex,
          lo_matcher TYPE REF TO cl_abap_matcher,
          lv_offset  TYPE i,
          lv_line    TYPE string.

    TRY.
        lo_regex = NEW cl_abap_regex( pattern = '[\r\n]+' ).
        lo_matcher = NEW cl_abap_matcher(
            regex         = lo_regex
            text          = iv_text ).

        WHILE lo_matcher->find_next( ) = abap_true.
          DATA(lv_value) = lo_matcher->get_offset( ) - lv_offset.
          lv_line = iv_text+lv_offset(lv_value).
          APPEND lv_line TO et_lines.
          lv_offset = lo_matcher->get_offset( ) + lo_matcher->get_length( ).
        ENDWHILE.

        "Handle the last line
        IF lv_offset < strlen( iv_text ).
          lv_line = iv_text+lv_offset.
          APPEND lv_line TO et_lines.
        ENDIF.

      CATCH cx_root. " Catch potential regex errors
        MESSAGE e000(zca_abap_assist) WITH 'Invalid regular expression'.
    ENDTRY.
  ENDMETHOD.


  METHOD split_string_to_table.
    DATA: lt_lines  TYPE ztca_response_table,
          lv_line   TYPE char200,
          lv_length TYPE i,
          lv_string TYPE string.

    lv_string = iv_string.

    lv_length = strlen( iv_string ).

    REPLACE ALL OCCURRENCES OF '```abap' IN lv_string WITH ''.

    REPLACE ALL OCCURRENCES OF '```' IN lv_string WITH ''.

    WHILE lv_length >= 200.
      lv_line = lv_string(200).
      APPEND lv_line TO lt_lines.
      lv_string = lv_string+200.
      lv_length = lv_length - 200.
    ENDWHILE.

* Handle remaining characters if string length is not a multiple of 200
    IF lv_string <> ''.
      APPEND lv_string TO lt_lines.
    ENDIF.

    et_output = lt_lines.
  ENDMETHOD.


  METHOD suggest_code_improvement.

    DATA: lv_prompt   TYPE string,
          ls_response TYPE zifca_abap_assist_aiutil=>type_response.

    lv_prompt = TEXT-005.

    IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
       zclca_abap_assist_ui=>gv_sendrequest IS INITIAL AND
       iv_from_pbo IS INITIAL.
      zclca_abap_assist_ui=>gv_inprocess = abap_true.
    ELSE.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      get_ai_utililty( )->execute_user_action(
       EXPORTING
         iv_prompt         = lv_prompt
         iv_option         = 'suggest'
         iv_current_source = build_code_string( )
         iv_llm_model = gv_llm_model
         is_trkey = gs_trkey
       RECEIVING
         rs_response       = ls_response
         ).
    ENDIF.

    gt_html = build_html(
                iv_input_request    = lv_prompt
                iv_response_content = ls_response-response
                iv_conv_identifier  = ls_response-identifier
              ).

    show_html( CHANGING it_html_table  = gt_html
                        io_html_viewer = go_html_viewer
                        cv_url         = gv_url ).

  ENDMETHOD.


  METHOD translate.

    DATA: lv_prompt   TYPE string,
          ls_response TYPE zifca_abap_assist_aiutil=>type_response.

    lv_prompt = text-005.

    IF zclca_abap_assist_ui=>gv_inprocess IS INITIAL AND
       zclca_abap_assist_ui=>gv_sendrequest IS INITIAL AND
       iv_from_pbo IS INITIAL.
      zclca_abap_assist_ui=>gv_inprocess = abap_true.
    ELSE.
      zclca_abap_assist_ui=>gv_sendrequest = abap_true.
      get_ai_utililty( )->execute_user_action(
       EXPORTING
         iv_prompt         = lv_prompt
         iv_option         = 'translate'
         iv_current_source = build_code_string( )
         iv_llm_model = gv_llm_model
         is_trkey = gs_trkey
       RECEIVING
         rs_response       = ls_response
         ).
    ENDIF.

    gt_html = build_html(
                iv_input_request    = lv_prompt
                iv_response_content = ls_response-response
                iv_conv_identifier  = ls_response-identifier
              ).

    show_html( CHANGING it_html_table  = gt_html
                        io_html_viewer = go_html_viewer
                        cv_url         = gv_url ).

  ENDMETHOD.


  METHOD zifca_abap_assist_ui~show_codegen_dialog.

    gv_first_time = abap_true.
    gv_abap_displaymode = iv_displaymode.
    gv_abap_fcode = iv_fcode.
    gt_selected_code = it_source_code.
    gv_fullscreen = iv_fullscreen.
    gs_trkey = is_trkey.
    go_editor_handle = io_editor_handle.
    CLEAR gt_chat_history.
    cl_gui_cfw=>flush( ).

    CALL FUNCTION 'Z_CA_ABAPASSIST_UI'
      EXPORTING
        iv_fullscreen = iv_fullscreen.

  ENDMETHOD.
ENDCLASS.
