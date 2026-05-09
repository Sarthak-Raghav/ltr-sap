CLASS zcl_ltr_util DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_text_entry,
        uuid        TYPE sysuuid_x16,
        object_type TYPE zltr_object_type,
        object_key  TYPE zltr_object_key,
        text_type   TYPE zltr_text_type,
        language    TYPE spras,
        created_by  TYPE abp_creation_user,
        created_at  TYPE abp_creation_tstmpl,
        changed_by  TYPE abp_lastchange_user,
        changed_at  TYPE abp_lastchange_tstmpl,
        short_text  TYPE zltr_short_text,
        long_text   TYPE string,
      END OF ty_text_entry.

    METHODS create_text
      IMPORTING
        iv_object_type TYPE zltr_object_type
        iv_object_key  TYPE zltr_object_key
        iv_text_type   TYPE zltr_text_type
        iv_language    TYPE spras
        iv_short_text  TYPE zltr_short_text OPTIONAL
        iv_long_text   TYPE string          OPTIONAL
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16
      RAISING
        zcx_ltr_util_error.

    METHODS read_text
      IMPORTING
        iv_uuid        TYPE sysuuid_x16
      RETURNING
        VALUE(rs_text) TYPE ty_text_entry
      RAISING
        zcx_ltr_util_error.

    METHODS update_text
      IMPORTING
        iv_uuid       TYPE sysuuid_x16
        iv_short_text TYPE zltr_short_text OPTIONAL
        iv_long_text  TYPE string          OPTIONAL
      RAISING
        zcx_ltr_util_error.

    METHODS delete_text
      IMPORTING
        iv_uuid TYPE sysuuid_x16
      RAISING
        zcx_ltr_util_error.

  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_ltr_util IMPLEMENTATION.

  METHOD create_text.

    DATA(lv_long_xstring) = cl_abap_conv_codepage=>create_out( )->convert( iv_long_text ).

    MODIFY ENTITIES OF zltr_i_head
      ENTITY zltr_i_head
      CREATE FIELDS ( objecttype objectkey texttype language )
      WITH VALUE #( (
        %cid       = 'CID_HEAD'
        objecttype = iv_object_type
        objectkey  = iv_object_key
        texttype   = iv_text_type
        language   = iv_language
      ) )
      ENTITY zltr_i_head
      CREATE BY \_content
      FIELDS ( shorttext longtext length )
      WITH VALUE #( (
        %cid_ref = 'CID_HEAD'
        %target  = VALUE #( (
          %cid      = 'CID_CONTENT'
          shorttext = iv_short_text
          longtext  = lv_long_xstring
          length    = xstrlen( lv_long_xstring )
        ) )
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Create failed' ).
    ENDIF.

    rv_uuid = ls_mapped-zltr_i_head[ 1 ]-uuid.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Commit failed' ).
    ENDIF.

  ENDMETHOD.

  METHOD read_text.

    READ ENTITIES OF zltr_i_head
      ENTITY zltr_i_head
      FIELDS ( objecttype objectkey texttype language createdby createdat changedby changedat )
      WITH VALUE #( ( uuid = iv_uuid ) )
      RESULT DATA(lt_head)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL OR lt_head IS INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Record not found' ).
    ENDIF.

    rs_text-uuid        = lt_head[ 1 ]-uuid.
    rs_text-object_type = lt_head[ 1 ]-objecttype.
    rs_text-object_key  = lt_head[ 1 ]-objectkey.
    rs_text-text_type   = lt_head[ 1 ]-texttype.
    rs_text-language    = lt_head[ 1 ]-language.
    rs_text-created_by  = lt_head[ 1 ]-createdby.
    rs_text-created_at  = lt_head[ 1 ]-createdat.
    rs_text-changed_by  = lt_head[ 1 ]-changedby.
    rs_text-changed_at  = lt_head[ 1 ]-changedat.

    READ ENTITIES OF zltr_i_head
      ENTITY zltr_i_head
      BY \_content
      FIELDS ( shorttext longtext length )
      WITH VALUE #( ( uuid = iv_uuid ) )
      RESULT DATA(lt_content)
      FAILED DATA(ls_failed2)
      REPORTED DATA(ls_reported2).

    IF lt_content IS NOT INITIAL.
      rs_text-short_text = lt_content[ 1 ]-shorttext.

      IF lt_content[ 1 ]-longtext IS NOT INITIAL.
        TRY.
            DATA lv_decompressed TYPE xstring.
            cl_abap_gzip=>decompress_binary(
              EXPORTING gzip_in = lt_content[ 1 ]-longtext
              IMPORTING raw_out = lv_decompressed ).
            rs_text-long_text = cl_abap_conv_codepage=>create_in( )->convert( lv_decompressed ).
          CATCH cx_parameter_invalid_range
                cx_sy_buffer_overflow
                cx_sy_compression_error
                cx_sy_conversion_codepage.
            RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Decompression failed' ).
        ENDTRY.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD update_text.

    DATA(lv_long_xstring) = cl_abap_conv_codepage=>create_out( )->convert( iv_long_text ).

    MODIFY ENTITIES OF zltr_i_head
      ENTITY zltr_i_content
      UPDATE FIELDS ( shorttext longtext length )
      WITH VALUE #( (
        %tky      = VALUE #( uuid = iv_uuid )
        shorttext = iv_short_text
        longtext  = lv_long_xstring
        length    = xstrlen( lv_long_xstring )
      ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_content IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Update failed' ).
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Commit failed' ).
    ENDIF.

  ENDMETHOD.

  METHOD delete_text.

    MODIFY ENTITIES OF zltr_i_head
      ENTITY zltr_i_head
      DELETE FROM VALUE #( (
        %tky = VALUE #( uuid = iv_uuid )
      ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Delete failed' ).
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

    IF ls_commit_failed IS NOT INITIAL.
      RAISE EXCEPTION NEW zcx_ltr_util_error( iv_text = 'Commit failed' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
