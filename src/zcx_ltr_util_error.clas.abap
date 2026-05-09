CLASS zcx_ltr_util_error DEFINITION
  PUBLIC
  FINAL
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.

    DATA mv_text TYPE string READ-ONLY.

    METHODS constructor
      IMPORTING
        !previous LIKE previous OPTIONAL
        !iv_text  TYPE string   OPTIONAL.

ENDCLASS.

CLASS zcx_ltr_util_error IMPLEMENTATION.

  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    mv_text = iv_text.
  ENDMETHOD.

ENDCLASS.
