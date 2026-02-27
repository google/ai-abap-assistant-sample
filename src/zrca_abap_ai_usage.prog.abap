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
*&---------------------------------------------------------------------*
*& Report ZRCA_ABAP_AI_USAGE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZRCA_ABAP_AI_USAGE.

TYPES: BEGIN OF gty_s_op,
         convo_id        TYPE zcad_ai_convo-convo_id,
         uname           TYPE zcad_ai_convo-uname,
         name_text       TYPE adrp-name_text,
         request_string  TYPE zcad_ai_req-request_string,
         response_string TYPE zcad_ai_resp-response_string,
         rating          TYPE zcad_ai_feedback-rating,
         date            TYPE sy-datum,
         time            TYPE sy-timlo,
       END OF gty_s_op.

DATA: gv_name      TYPE xubname,
      gv_timestamp TYPE timestamp,
      gt_op        TYPE STANDARD TABLE OF gty_s_op,
      gtr_tmstmp   TYPE RANGE OF timestamp
      .


SELECT-OPTIONS:s_uname FOR gv_name,
               s_tmstmp FOR gv_timestamp
               .



START-OF-SELECTION.
  SELECT
  c~convo_id,
  c~uname,
  a~name_text,
  req~request_string,
  resp~response_string,
  req~timestamp,
  f~rating
    FROM zcad_ai_convo AS c
    INNER JOIN usr21 AS u ON c~uname = u~bname
    INNER JOIN adrp AS a ON a~persnumber = u~persnumber
    LEFT OUTER JOIN zcad_ai_req AS req ON req~convo_id = c~convo_id
    LEFT OUTER JOIN zcad_ai_resp AS resp ON resp~req_id = req~req_id
    LEFT OUTER JOIN zcad_ai_feedback AS f ON f~resp_id = resp~resp_id
    INTO TABLE @DATA(lt_convo)
    WHERE c~uname IN @s_uname AND
          req~timestamp IN @s_tmstmp
    ORDER BY req~timestamp DESCENDING.

  LOOP AT lt_convo REFERENCE INTO DATA(ls_convo).
    APPEND INITIAL LINE TO gt_op ASSIGNING FIELD-SYMBOL(<ls_op>).
    MOVE-CORRESPONDING ls_convo->* TO <ls_op>.
    CONVERT TIME STAMP ls_convo->timestamp TIME ZONE sy-zonlo INTO DATE <ls_op>-date TIME <ls_op>-time.
  ENDLOOP.


  DATA(lt_convo2) = lt_convo.
  SORT lt_convo2 BY convo_id.
  DELETE ADJACENT DUPLICATES FROM lt_convo2 COMPARING convo_id.
  DATA(gv_cnt_convo) = lines( lt_convo2 ).

  lt_convo2 = lt_convo.
  SORT lt_convo2 BY uname.
  DELETE ADJACENT DUPLICATES FROM lt_convo2 COMPARING uname.
  DATA(gv_cnt_uname) = lines( lt_convo2 ).


  DATA:
    go_salv    TYPE REF TO cl_salv_table,
    go_header  TYPE REF TO cl_salv_form_layout_grid,
    go_h_label TYPE REF TO cl_salv_form_label,
    go_h_flow  TYPE REF TO cl_salv_form_layout_flow.
  .


  TRY.
      cl_salv_table=>factory( IMPORTING r_salv_table = go_salv
                              CHANGING  t_table      = gt_op ).

      go_header = NEW #( ).
      go_salv->set_top_of_list( go_header ).
      go_salv->set_top_of_list_print( go_header ).


      go_h_label = go_header->create_label( row = 1 column = 1 ).
      go_h_label->set_text( 'Unique Conversations:' ).

      go_h_flow = go_header->create_flow( row = 1 column = 2 ).
      go_h_flow->create_text( text = gv_cnt_convo ).




      go_h_label = go_header->create_label( row = 2 column = 1 ).
      go_h_label->set_text( 'Unique Users:' ).

      go_h_flow = go_header->create_flow( row = 2 column = 2 ).
      go_h_flow->create_text( text = gv_cnt_uname ).



* Blank row
      go_h_label = go_header->create_label( row = 3 column = 1 ).
      go_h_label->set_text( '' ).

      go_h_flow = go_header->create_flow( row = 3 column = 2 ).
      go_h_flow->create_text( text = '' ).


      go_h_flow = go_header->create_flow( row = 2 column = 2 ).
      go_h_flow->create_text( text = gv_cnt_uname ).
      IF go_salv IS BOUND.
        DATA(go_columns) = go_salv->get_columns( ).
        IF go_columns IS BOUND.
          go_columns->set_optimize( abap_true ).
        ENDIF.

        TRY.
            DATA(go_column) = go_columns->get_column( 'REQUEST_STRING' ).
            IF go_column IS BOUND.
              go_column->set_short_text( 'Req string' ).
              go_column->set_medium_text( 'Req string' ).
              go_column->set_long_text( 'Request string' ).
            ENDIF.
          CATCH cx_salv_not_found.
          CATCH cx_sy_ref_is_initial.
        ENDTRY.


        TRY.
            go_column = go_columns->get_column( 'RESPONSE_STRING' ).
            IF go_column IS BOUND.
              go_column->set_short_text( 'Resp str' ).
              go_column->set_medium_text( 'Resp string' ).
              go_column->set_long_text( 'Response string' ).
            ENDIF.
          CATCH cx_salv_not_found.
          CATCH cx_sy_ref_is_initial.
        ENDTRY.

        TRY.
            go_column = go_columns->get_column( 'DATE' ).
            IF go_column IS BOUND.
              go_column->set_short_text( 'Req Date' ).
              go_column->set_medium_text( 'Req Date' ).
              go_column->set_long_text( 'Req Date' ).
            ENDIF.
          CATCH cx_salv_not_found.
          CATCH cx_sy_ref_is_initial.
        ENDTRY.

        TRY.
            go_column = go_columns->get_column( 'TIME' ).
            IF go_column IS BOUND.
              go_column->set_short_text( 'Req Time' ).
              go_column->set_medium_text( 'Req Time' ).
              go_column->set_long_text( 'Req Time' ).
            ENDIF.
          CATCH cx_salv_not_found.
          CATCH cx_sy_ref_is_initial.
        ENDTRY.

        go_salv->get_functions( )->set_all( ).
        go_salv->display( ).
      ENDIF.
    CATCH cx_salv_msg.
  ENDTRY.
