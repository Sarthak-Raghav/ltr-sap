CLASS lhc_ZLTR_I_Head DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZLTR_I_Head RESULT result.
    METHODS check_unique FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZLTR_I_Head~check_unique.

ENDCLASS.

CLASS lhc_ZLTR_I_Head IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD check_unique.
   LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).

    " Read the entity being created
    READ ENTITIES OF zltr_i_head IN LOCAL MODE
      ENTITY ZLTR_I_Head
      FIELDS ( objecttype objectkey texttype language )
      WITH VALUE #( ( %tky = <key>-%tky ) )
      RESULT DATA(lt_head)
      FAILED DATA(ls_failed)
      REPORTED DATA(ls_reported).

    CHECK lt_head IS NOT INITIAL.

    DATA(ls_head) = lt_head[ 1 ].

    " Check for existing record with same combination
    SELECT SINGLE uuid
      FROM zltr_head
      WHERE object_type = @ls_head-objecttype
      AND   object_key  = @ls_head-objectkey
      AND   text_type   = @ls_head-texttype
      AND   language    = @ls_head-language
      AND   uuid        <> @ls_head-uuid
      INTO @DATA(lv_existing).

    IF sy-subrc = 0.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'A text entry for this object type, key, text type and language already exists' )
      ) TO reported-zltr_i_head.

      APPEND VALUE #(
        %tky = <key>-%tky
      ) TO failed-zltr_i_head.
    ENDIF.

  ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZLTR_I_HEAD DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZLTR_I_HEAD IMPLEMENTATION.

METHOD save_modified.

  " ---- HEAD CREATE ----
  IF create-zltr_i_head IS NOT INITIAL.
    LOOP AT create-zltr_i_head ASSIGNING FIELD-SYMBOL(<hc>).
      INSERT zltr_head FROM @( VALUE zltr_head(
        client      = sy-mandt
        uuid        = <hc>-uuid
        object_type = <hc>-objecttype
        object_key  = <hc>-objectkey
        text_type   = <hc>-texttype
        language    = <hc>-language
        created_by  = <hc>-createdby
        created_at  = <hc>-createdat
        changed_by  = <hc>-changedby
        changed_at  = <hc>-changedat
      ) ).
    ENDLOOP.
  ENDIF.

  " ---- HEAD UPDATE ----
  IF update-zltr_i_head IS NOT INITIAL.
    LOOP AT update-zltr_i_head ASSIGNING FIELD-SYMBOL(<hu>).
      UPDATE zltr_head FROM @( VALUE zltr_head(
        client      = sy-mandt
        uuid        = <hu>-uuid
        object_type = <hu>-objecttype
        object_key  = <hu>-objectkey
        text_type   = <hu>-texttype
        language    = <hu>-language
        created_by  = <hu>-createdby
        created_at  = <hu>-createdat
        changed_by  = <hu>-changedby
        changed_at  = <hu>-changedat
      ) ).
    ENDLOOP.
  ENDIF.

  " ---- HEAD DELETE ----
  IF delete-zltr_i_head IS NOT INITIAL.
    LOOP AT delete-zltr_i_head ASSIGNING FIELD-SYMBOL(<hd>).
      DELETE FROM zltr_head WHERE uuid = @<hd>-uuid.
      DELETE FROM zltr_content WHERE uuid = @<hd>-uuid.
    ENDLOOP.
  ENDIF.

  " ---- CONTENT CREATE ----
  IF create-zltr_i_content IS NOT INITIAL.
    LOOP AT create-zltr_i_content ASSIGNING FIELD-SYMBOL(<cc>).
      DATA ls_content TYPE zltr_content.
      ls_content-client   = sy-mandt.
      ls_content-uuid     = <cc>-uuid.
      ls_content-short_text = <cc>-shorttext.
      ls_content-length   = <cc>-length.
      ls_content-long_text = <cc>-longtext.
      IF ls_content-long_text IS NOT INITIAL.
        TRY.
            cl_abap_gzip=>compress_binary(
              EXPORTING raw_in   = ls_content-long_text
              IMPORTING gzip_out = ls_content-long_text ).
          CATCH cx_parameter_invalid_range
                cx_sy_buffer_overflow
                cx_sy_compression_error.
        ENDTRY.
      ENDIF.
      INSERT zltr_content FROM @ls_content.
    ENDLOOP.
  ENDIF.

  " ---- CONTENT UPDATE ----
  IF update-zltr_i_content IS NOT INITIAL.
    LOOP AT update-zltr_i_content ASSIGNING FIELD-SYMBOL(<cu>).
      DATA ls_content_u TYPE zltr_content.
      ls_content_u-client     = sy-mandt.
      ls_content_u-uuid       = <cu>-uuid.
      ls_content_u-short_text = <cu>-shorttext.
      ls_content_u-length     = <cu>-length.
      ls_content_u-long_text  = <cu>-longtext.
      IF ls_content_u-long_text IS NOT INITIAL.
        TRY.
            cl_abap_gzip=>compress_binary(
              EXPORTING raw_in   = ls_content_u-long_text
              IMPORTING gzip_out = ls_content_u-long_text ).
          CATCH cx_parameter_invalid_range
                cx_sy_buffer_overflow
                cx_sy_compression_error.
        ENDTRY.
      ENDIF.
      UPDATE zltr_content FROM @ls_content_u.
    ENDLOOP.
  ENDIF.

  " ---- CONTENT DELETE ----
  IF delete-zltr_i_content IS NOT INITIAL.
    LOOP AT delete-zltr_i_content ASSIGNING FIELD-SYMBOL(<cd>).
      DELETE FROM zltr_content WHERE uuid = @<cd>-uuid.
    ENDLOOP.
  ENDIF.

ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
