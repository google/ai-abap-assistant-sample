INTERFACE zifca_llm_content_mod
  PUBLIC .


  INTERFACES if_badi_interface .

  METHODS modify_content
    IMPORTING
      !iv_prompt  TYPE string
      !iv_option  TYPE char20
    CHANGING
      !ct_content TYPE /goog/cl_aiplatform_v1=>ty_t_695 .
ENDINTERFACE.
