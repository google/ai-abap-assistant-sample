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
interface ZIF_AI_LOGGER
  public .


  types:
    BEGIN OF gty_s_fb_categ_config,
           category_id   TYPE zcad_ai_fb_categ-category_id,
           linked_rating TYPE zcad_ai_fb_categ-linked_rating,
           sort_order    TYPE zcad_ai_fb_categ-sort_order,
           category_desc TYPE zcad_ai_fb_categ-category_desc,
         END OF gty_s_fb_categ_config .
  types:
    gty_t_fb_categ_config TYPE STANDARD TABLE OF gty_s_fb_categ_config WITH KEY category_id .
  types:
    BEGIN OF gty_s_feedback_categ,
           category_id   TYPE zcad_ai_fb_categ_id,
           category_desc TYPE zcad_ai_fb_categ_desc,
         END OF gty_s_feedback_categ .
  types:
    gty_t_feedback_categ TYPE STANDARD TABLE OF gty_s_feedback_categ WITH KEY category_id .
  types:
    BEGIN OF gty_s_feedback,
           feedback_id TYPE zcai_ai_feedback_id,
           rating      TYPE zcai_ai_feedback_rating,
           user_input  TYPE string,
           timestamp   TYPE timestamp,
           t_categ     TYPE gty_t_feedback_categ,
         END OF gty_s_feedback .
  types:
    BEGIN OF gty_s_req_resp,
           req_id                   TYPE zcai_ai_req_id,
           request_string           TYPE string,
           request_after_preprocess TYPE string,
           req_timestamp            TYPE timestamp,
           resp_id                  TYPE zcai_ai_resp_id,
           response_string          TYPE string,
           ret_code                 TYPE zcai_ai_ret_code,
           ret_text                 TYPE string,
           resp_timestamp           TYPE timestamp,
           accepted                 TYPE boole_d,
           s_feedback               TYPE gty_s_feedback,
         END OF gty_s_req_resp .
  types:
    gty_t_req_resp TYPE STANDARD TABLE OF gty_s_req_resp WITH KEY req_id .
  types:
    BEGIN OF gty_s_convo,
           convo_id   TYPE zcai_ai_convo_id,
           uname      TYPE syuname,
           tcode      TYPE sytcode,
           first_run  TYPE timestamp,
           t_req_resp TYPE gty_t_req_resp,
         END OF gty_s_convo .
  types:
    gty_t_convo       TYPE STANDARD TABLE OF gty_s_convo WITH KEY convo_id .
  types:
    gty_t_fb_categ_id TYPE STANDARD TABLE OF zcad_ai_fb_categ_id .

  constants:
    BEGIN OF gc_rating,
      thumbs_up   TYPE zcai_ai_feedback_rating VALUE 'U',
      thumbs_down TYPE zcai_ai_feedback_rating VALUE 'D',
    END OF gc_rating .

  class-methods GET_CONVO_HISTORY
    importing
      !IV_UNAME type SYUNAME default SY-UNAME
      !IV_CONVO_ID type ZCAI_AI_CONVO_ID optional
    returning
      value(RT_CONVO) type GTY_T_CONVO .
  class-methods GET_FEEDBACK_CATEGORY
    returning
      value(RT_CATEGORY) type GTY_T_FB_CATEG_CONFIG .
  methods LOG_REQUEST
    importing
      !IV_REQ_STRING type ZCAD_AI_REQ-REQUEST_STRING
      !IV_REQ_AFTER_PREPROCESS type STRING optional
      !IV_COMMIT type ABAP_BOOL default ABAP_TRUE
    returning
      value(RV_REQ_ID) type ZCAI_AI_REQ_ID .
  methods LOG_RESPONSE
    importing
      !IV_RESP_STRING type ZCAD_AI_RESP-RESPONSE_STRING
      !IV_RET_CODE type ZCAD_AI_RESP-RET_CODE optional
      !IV_RET_TEXT type ZCAD_AI_RESP-RET_TEXT optional
      !IV_COMMIT type ABAP_BOOL default ABAP_TRUE
    returning
      value(RV_RESP_ID) type ZCAI_AI_RESP_ID .
  methods LOG_FEEDBACK
    importing
      !IV_RESP_ID type ZCAI_AI_RESP_ID
      !IV_RATING type ZCAI_AI_FEEDBACK_RATING optional
      !IT_FB_CATEG type GTY_T_FB_CATEG_ID optional
      !IV_USER_INPUT type ZCAD_AI_FEEDBACK-USER_INPUT optional
      !IV_COMMIT type ABAP_BOOL default ABAP_TRUE
    returning
      value(RV_FEEDBACK_ID) type ZCAD_AI_FEEDBACK-FEEDBACK_ID .
  methods LOG_ACCEPTANCE
    importing
      !IV_RESP_ID type ZCAI_AI_RESP_ID
      !IV_COMMIT type ABAP_BOOL default ABAP_TRUE .
  methods LOG_REQ_RESP
    importing
      !IV_REQ_STRING type ZCAD_AI_REQ-REQUEST_STRING
      !IV_RESP_STRING type ZCAD_AI_RESP-RESPONSE_STRING
      !IV_RET_CODE type ZCAD_AI_RESP-RET_CODE optional
      !IV_RET_TEXT type ZCAD_AI_RESP-RET_TEXT optional
    returning
      value(RV_RESP_ID) type ZCAI_AI_RESP_ID .
  methods GET_REQ_RESP
    returning
      value(RS_REQ_RESP) type GTY_S_CONVO .
endinterface.
