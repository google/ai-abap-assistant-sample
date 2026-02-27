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
FUNCTION Z_CA_ABAPASSIST_UI.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IV_FULLSCREEN) TYPE  BOOLEAN OPTIONAL
*"----------------------------------------------------------------------

  IF iv_fullscreen = abap_true.
    CALL SCREEN 100.
  ELSE.
    CALL SCREEN 100 STARTING AT 20 2 ENDING AT 206 31.
*    CALL SCREEN 100 STARTING AT 1 1 ENDING AT 125 17.
  ENDIF.

ENDFUNCTION.
