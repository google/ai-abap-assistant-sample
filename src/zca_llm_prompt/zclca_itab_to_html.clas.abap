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
CLASS zclca_itab_to_html DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    TYPES:
      BEGIN OF gty_s_table_description,
        name        TYPE string,
        title       TYPE string,
        description TYPE string,
      END OF gty_s_table_description .
    TYPES:
      gt_table_description TYPE STANDARD TABLE OF gty_s_table_description WITH KEY name .

    METHODS constructor
      IMPORTING
        !iv_table_id    TYPE string OPTIONAL
        !iv_table_class TYPE string OPTIONAL
        !iv_table_style TYPE string
          DEFAULT 'WIDTH: 80%; BORDER: #999 1PX SOLID; BORDER-COLLAPSE: COLLAPSE;'
        !iv_tr_class    TYPE string OPTIONAL
        !iv_tr_style    TYPE string OPTIONAL
        !iv_th_class    TYPE string OPTIONAL
        !iv_th_style    TYPE string
          DEFAULT 'FONT-WEIGHT: BOLD; BORDER: #999 1PX SOLID; BACKGROUND: #EEE;'
        !iv_td_class    TYPE string OPTIONAL
        !iv_td_style    TYPE string DEFAULT 'BORDER: #999 1PX SOLID;' .
    METHODS convert
      IMPORTING
        !it_table        TYPE ANY TABLE
      RETURNING
        VALUE(rv_result) TYPE string .
PROTECTED SECTION.

  DATA gv_cellpadding TYPE i VALUE 0 ##NO_TEXT.
  DATA gv_cellspacing TYPE i VALUE 0 ##NO_TEXT.
  DATA gv_table_class TYPE string VALUE '' ##NO_TEXT.
  DATA gv_table_id TYPE string VALUE '' ##NO_TEXT.
  DATA gv_table_style TYPE string VALUE '' ##NO_TEXT.
  DATA gv_tr_class TYPE string VALUE '' ##NO_TEXT.
  DATA gv_tr_style TYPE string VALUE '' ##NO_TEXT.
  DATA gv_th_class TYPE string VALUE '' ##NO_TEXT.
  DATA gv_th_style TYPE string VALUE '' ##NO_TEXT.
  DATA gv_td_class TYPE string VALUE '' ##NO_TEXT.
  DATA gv_td_style TYPE string VALUE '' ##NO_TEXT.

  METHODS get_description
    IMPORTING
      !it_table        TYPE ANY TABLE
    RETURNING
      VALUE(rt_result) TYPE gt_table_description .
  METHODS title
    IMPORTING
      !it_desc         TYPE gt_table_description
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS table_params
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS tr_params
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS th_params
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS td_params
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS value_to_string
    IMPORTING
      !iv_field        TYPE string
      !iv_val          TYPE any
    RETURNING
      VALUE(rv_result) TYPE string .
  METHODS footer
    IMPORTING
      !it_desc         TYPE gt_table_description
    RETURNING
      VALUE(rv_result) TYPE string .
PRIVATE SECTION.
ENDCLASS.



CLASS ZCLCA_ITAB_TO_HTML IMPLEMENTATION.


  METHOD constructor.
    IF iv_table_id IS SUPPLIED.
      me->gv_table_id = iv_table_id.
    ENDIF.
    IF iv_table_class IS SUPPLIED.
      me->gv_table_class = iv_table_class.
    ENDIF.

    me->gv_table_style = iv_table_style.

    IF iv_tr_class IS SUPPLIED.
      me->gv_tr_class = iv_tr_class.
    ENDIF.
    IF iv_tr_style IS SUPPLIED.
      me->gv_tr_style = iv_tr_style.
    ENDIF.

    IF iv_th_class IS SUPPLIED.
      me->gv_th_class = iv_th_class.
    ENDIF.

    me->gv_th_style = iv_th_style.

    IF iv_td_class IS SUPPLIED.
      me->gv_td_class = iv_td_class.
    ENDIF.

    me->gv_td_style = iv_td_style.

  ENDMETHOD.


  METHOD convert.

    DATA lv_row TYPE string VALUE ''.

    DATA(lt_descr) = get_description( it_table ).
    DATA(lv_tr) = tr_params( ).
    DATA(lv_td) = td_params( ).

    LOOP AT it_table ASSIGNING FIELD-SYMBOL(<row>).
      CLEAR lv_row.
      LOOP AT lt_descr ASSIGNING FIELD-SYMBOL(<ls_descr>).
        ASSIGN COMPONENT <ls_descr>-name OF STRUCTURE <row> TO FIELD-SYMBOL(<value>).
        lv_row = |{ lv_row }  <TD{ lv_td }>| &
                 |{ value_to_string( iv_field = <ls_descr>-name iv_val = <value> ) }</TD>|.
      ENDLOOP.

      rv_result = |{ rv_result } <TR{ lv_tr }>{ lv_row } </TR>|.
    ENDLOOP.


    rv_result = |{ title( lt_descr ) }{ rv_result }{ footer( lt_descr ) }|.
  ENDMETHOD.


  METHOD footer.
    rv_result = |</TABLE>|.
  ENDMETHOD.


  METHOD get_description.
    DATA(lo_description) = CAST cl_abap_tabledescr(
                                   cl_abap_tabledescr=>describe_by_data( it_table ) ).
    DATA(lt_components)  = CAST cl_abap_structdescr(
                                   lo_description->get_table_line_type( ) )->get_components( ).

    LOOP AT lt_components ASSIGNING FIELD-SYMBOL(<ls_component>).
      DATA(elemdescr) = CAST cl_abap_elemdescr( <ls_component>-type ).

      elemdescr->get_ddic_field(
        RECEIVING
          p_flddescr   = DATA(elem)
        EXCEPTIONS
          not_found    = 1
          no_ddic_type = 2
          OTHERS       = 3 ).
      IF sy-subrc <> 0.
        APPEND VALUE #( name = <ls_component>-name
                        title = <ls_component>-name
                        description = <ls_component>-name ) TO rt_result.
      ELSE.
        APPEND VALUE #( name = <ls_component>-name
                        title = elem-reptext
                        description = elem-fieldtext ) TO rt_result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


  METHOD table_params.
    IF gv_table_id <> ''.
      rv_result = |{ rv_result } ID="{ gv_table_id }"|.
    ENDIF.

    IF gv_table_class <> ''.
      rv_result = |{ rv_result } CLASS="{ gv_table_class }"|.
    ENDIF.

    IF gv_table_style <> ''.
      rv_result = |{ rv_result } STYLE="{ gv_table_style }"|.
    ENDIF.
  ENDMETHOD.


  METHOD td_params.
    IF gv_td_class <> ''.
      rv_result = |{ rv_result } CLASS="{ gv_td_class }"|.
    ENDIF.

    IF gv_td_style <> ''.
      rv_result = |{ rv_result } STYLE="{ gv_td_style }"|.
    ENDIF.
  ENDMETHOD.


  METHOD th_params.
    IF gv_th_class <> ''.
      rv_result = |{ rv_result } CLASS="{ gv_th_class }"|.
    ENDIF.

    IF gv_th_style <> ''.
      rv_result = |{ rv_result } STYLE="{ gv_th_style }"|.
    ENDIF.
  ENDMETHOD.


  METHOD title.
    DATA(th) = th_params( ).

    LOOP AT it_desc ASSIGNING FIELD-SYMBOL(<item>).
      rv_result = |{ rv_result }  <TH{ th }>{ <item>-title }</TH>|.
    ENDLOOP.

    rv_result = |<TABLE{ table_params( ) }> <TR{ tr_params( ) }>{ rv_result } </TR>|.
  ENDMETHOD.


  METHOD tr_params.
    IF gv_tr_class <> ''.
      rv_result = |{ rv_result } CLASS="{ gv_tr_class }"|.
    ENDIF.

    IF gv_tr_style <> ''.
      rv_result = |{ rv_result } STYLE="{ gv_tr_style }"|.
    ENDIF.
  ENDMETHOD.


  METHOD value_to_string.
    rv_result = CONV string( iv_val ).
  ENDMETHOD.
ENDCLASS.
