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
        long_text   TYPE xstring,
      END OF ty_text_entry.

    METHODS create_text
      IMPORTING
        iv_object_type TYPE zltr_object_type
        iv_object_key  TYPE zltr_object_key
        iv_text_type   TYPE zltr_text_type
        iv_language    TYPE spras
        iv_short_text  TYPE zltr_short_text OPTIONAL
        iv_long_text   TYPE xstring         OPTIONAL
      RETURNING
        VALUE(rv_uuid) TYPE sysuuid_x16.

    METHODS read_text
      IMPORTING
        iv_uuid        TYPE sysuuid_x16
      RETURNING
        VALUE(rs_text) TYPE ty_text_entry.

    METHODS update_text
      IMPORTING
        iv_uuid       TYPE sysuuid_x16
        iv_short_text TYPE zltr_short_text OPTIONAL
        iv_long_text  TYPE xstring         OPTIONAL.

    METHODS delete_text
      IMPORTING
        iv_uuid TYPE sysuuid_x16.

  PRIVATE SECTION.

ENDCLASS.

CLASS zcl_ltr_util IMPLEMENTATION.

  METHOD create_text.

    MODIFY ENTITIES OF zltr_i_head
      ENTITY ZLTR_I_Head
      CREATE FIELDS ( objecttype objectkey texttype language )
      WITH VALUE #( (
        %cid       = 'CID_HEAD'
        objecttype = iv_object_type
        objectkey  = iv_object_key
        texttype   = iv_text_type
        language   = iv_language
      ) )
      MAPPED DATA(ls_mapped)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL.
      RETURN.
    ENDIF.

    rv_uuid = ls_mapped-zltr_i_head[ 1 ]-uuid.

    MODIFY ENTITIES OF zltr_i_head
      ENTITY ZLTR_I_Head
      CREATE BY \_content
      FIELDS ( shorttext longtext length )
      WITH VALUE #( (
        %cid_ref = 'CID_HEAD'
        %target  = VALUE #( (
          %cid      = 'CID_CONTENT'
          shorttext = iv_short_text
          longtext  = iv_long_text
          length    = xstrlen( iv_long_text )
        ) )
      ) )
      FAILED DATA(ls_failed2)
      REPORTED DATA(ls_reported2).

    IF ls_failed2-zltr_i_content IS NOT INITIAL.
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

  ENDMETHOD.

  METHOD read_text.

    READ ENTITIES OF zltr_i_head
      ENTITY ZLTR_I_Head
      FIELDS ( objecttype objectkey texttype language createdby createdat changedby changedat )
      WITH VALUE #( ( uuid = iv_uuid ) )
      RESULT DATA(lt_head)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL OR lt_head IS INITIAL.
      RETURN.
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
      ENTITY ZLTR_I_Head
      BY \_content
      FIELDS ( shorttext longtext length )
      WITH VALUE #( ( uuid = iv_uuid ) )
      RESULT DATA(lt_content)
      FAILED DATA(ls_failed2)
      REPORTED DATA(ls_reported2).

    IF lt_content IS NOT INITIAL.
      rs_text-short_text = lt_content[ 1 ]-shorttext.
      rs_text-long_text  = lt_content[ 1 ]-longtext.

      IF rs_text-long_text IS NOT INITIAL.
        TRY.
            cl_abap_gzip=>decompress_binary(
              EXPORTING gzip_in = rs_text-long_text
              IMPORTING raw_out = rs_text-long_text ).
          CATCH cx_parameter_invalid_range
                cx_sy_buffer_overflow
                cx_sy_compression_error.
        ENDTRY.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD update_text.

    MODIFY ENTITIES OF zltr_i_head
      ENTITY ZLTR_I_Content
      UPDATE FIELDS ( shorttext longtext length )
      WITH VALUE #( (
        %tky      = VALUE #( uuid = iv_uuid )
        shorttext = iv_short_text
        longtext  = iv_long_text
        length    = xstrlen( iv_long_text )
      ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_content IS NOT INITIAL.
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

  ENDMETHOD.

  METHOD delete_text.

    MODIFY ENTITIES OF zltr_i_head
      ENTITY ZLTR_I_Head
      DELETE FROM VALUE #( (
        %tky = VALUE #( uuid = iv_uuid )
      ) )
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    IF ls_failed-zltr_i_head IS NOT INITIAL.
      RETURN.
    ENDIF.

    COMMIT ENTITIES
      RESPONSE OF zltr_i_head
      FAILED DATA(ls_commit_failed)
      REPORTED DATA(ls_commit_reported).

  ENDMETHOD.

ENDCLASS.
