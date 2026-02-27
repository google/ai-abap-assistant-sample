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
CLASS Zclca_adt_rest_app DEFINITION
  PUBLIC
  INHERITING FROM cl_adt_disc_res_app_base
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS if_adt_rest_rfc_application~get_static_uri_path
        REDEFINITION .
  PROTECTED SECTION.

    METHODS get_application_title
        REDEFINITION .
    METHODS register_resources
        REDEFINITION .
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCLCA_ADT_REST_APP IMPLEMENTATION.


  METHOD get_application_title.
    result = 'Abap Assist'.
  ENDMETHOD.


  METHOD if_adt_rest_rfc_application~get_static_uri_path.
    result = super->if_adt_rest_rfc_application~get_static_uri_path( ).
  ENDMETHOD.


  METHOD register_resources.


    DATA lo_collection TYPE REF TO if_adt_discovery_collection.

    registry->register_discoverable_resource(
      url             = '/zabapassist/adt_resource/conversations'
      handler_class   = 'ZCLCA_ABAP_ASSIST_ADT_RESOURCE'
      description     = 'Conversation'
      category_scheme = '/sap/bc/adt/zabapassist/adt_resource/conversations'
      category_term   = 'conversation' ).

    lo_collection = registry->register_discoverable_resource(
      EXPORTING
        url             = '/zabapassist/adt_resource/conversations'
        handler_class   = 'ZCLCA_ABAP_ASSIST_ADT_RESOURCE' "Handler class is just used for example
        description     = 'Conversation'
        category_scheme =
                          '/sap/bc/adt/zabapassist/adt_resource/conversations'
        category_term   = 'conversation' ).

    lo_collection->register_disc_res_w_template(
      EXPORTING
        relation      =
                        '/zabapassist/adt_resource/contentAssistProposals/singleProposal'
        template      =
                        '/contentAssistProposals/singleProposal/{model}/{id}/{prompt}'
        description   = 'ABAP Assist Content Assist'
        type          = 'application/xml'
        handler_class = 'ZCLCA_ABAP_ASSIST_ADT_RES_CONT'
    ).

    " content assist
    registry->register_discoverable_resource(
      url             = '/zabapassist/adt_resource/contentAssistProposals'
      handler_class   = 'ZCLCA_ABAP_ASSIST_ADT_RES_CONT'
      description     = 'ContentAssist'
      category_scheme = '/sap/bc/adt/zabapassist/adt_resource/contentAssistPropsals'
      category_term   = 'contentAssist' ).

    lo_collection = registry->register_discoverable_resource(
      EXPORTING
        url             = '/zabapassist/adt_resource/contentAssistProposals'
        handler_class   = 'ZCLCA_ABAP_ASSIST_ADT_RESOURCE' "Handler class is just used for example
        description     = 'ContentAssist'
        category_scheme =
                          '/sap/bc/adt/zabapassist/adt_resource/contentAssistProposals'
        category_term   = 'contentAssist' ).

    lo_collection->register_disc_res_w_template(
      EXPORTING
        relation      =
                        '/zabapassist/adt_resource/contentAssistProposals/singleProposal'
        template      =
                        '/contentAssistProposals/singleProposal/{model}/{id}/{prompt}'
        description   = 'ABAP Assist Content Assist'
        type          = 'application/xml'
        handler_class = 'ZCLCA_ABAP_ASSIST_ADT_RES_CONT'
    ).

  ENDMETHOD.
ENDCLASS.
