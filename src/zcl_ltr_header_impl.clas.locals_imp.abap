CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES:
      tt_head_create TYPE TABLE OF zltr_head WITH DEFAULT KEY,
      tt_head_update TYPE TABLE OF zltr_head WITH DEFAULT KEY,
      tt_head_delete TYPE TABLE OF zltr_head WITH DEFAULT KEY,
      tt_content_create TYPE TABLE OF zltr_content WITH DEFAULT KEY,
      tt_content_update TYPE TABLE OF zltr_content WITH DEFAULT KEY,
      tt_content_delete TYPE TABLE OF zltr_content WITH DEFAULT KEY.

    CLASS-DATA:
      mt_head_create   TYPE tt_head_create,
      mt_head_update   TYPE tt_head_update,
      mt_head_delete   TYPE tt_head_delete,
      mt_content_create TYPE tt_content_create,
      mt_content_update TYPE tt_content_update,
      mt_content_delete TYPE tt_content_delete.
ENDCLASS.

CLASS lcl_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lhc_ZLTR_I_Head DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR ZLTR_I_Head RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE ZLTR_I_Head.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE ZLTR_I_Head.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE ZLTR_I_Head.

    METHODS read FOR READ
      IMPORTING keys FOR READ ZLTR_I_Head RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK ZLTR_I_Head.

    METHODS rba_Content FOR READ
      IMPORTING keys_rba FOR READ ZLTR_I_Head\_Content FULL result_requested RESULT result LINK association_links.

    METHODS cba_Content FOR MODIFY
      IMPORTING entities_cba FOR CREATE ZLTR_I_Head\_Content.

ENDCLASS.

CLASS lhc_ZLTR_I_Head IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
        "Generate UUID
        TRY.
          DATA(lv_uuid) = cl_system_uuid=>create_uuid_x16_static(  ).
          CATCH CX_UUID_ERROR INTO DATA(lv_uuid_msg).
           APPEND VALUE #(
                             %cid    = <entity>-%cid
                             %msg    = new_message_with_text(
                             severity = if_abap_behv_message=>severity-error
                             text     = lv_uuid_msg->get_text( ) )
                             %element-uuid = if_abap_behv=>mk-on
                        ) TO reported-zltr_i_head.
    CONTINUE. " skip this entity
        ENDTRY
        .
        "Get current time stamp and user
        GET TIME STAMP FIELD DATA(lv_timestamp).

        lcl_buffer=>mt_head_create = VALUE #(
                                     BASE lcl_buffer=>mt_head_create (
                                          client      = sy-mandt
                                          uuid        = lv_uuid
                                          object_type = <entity>-ObjectType
                                          object_key  = <entity>-ObjectKey
                                          text_type   = <entity>-TextType
                                          language    = <entity>-Language
                                          created_by  = sy-uname
                                          created_at  = lv_timestamp
                                          changed_by  = sy-uname
                                          changed_at  = lv_timestamp  ) ).

        APPEND VALUE #(
            %cid = <entity>-%cid
            uuid = lv_uuid ) TO mapped-zltr_i_head.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
        " Read existing record from DB first
        SELECT SINGLE uuid,
                      object_type,
                      object_key,
                      text_type,
                      language,
                      created_by,
                      created_at,
                      changed_by,
                      changed_at FROM zltr_head
                                 WHERE uuid   = @<entity>-uuid
                                 INTO @DATA(ls_head).
        IF sy-subrc <> 0.
            APPEND VALUE #( %tky = <entity>-%tky
                            %msg = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Record not found for update' ) ) TO reported-zltr_i_head.
            CONTINUE.
        ENDIF.

    " Only update fields that were actually changed
    " %control tells us which fields the user actually touched
    IF <entity>-%control-objecttype = if_abap_behv=>mk-on.
      ls_head-object_type = <entity>-objecttype.
    ENDIF.
    IF <entity>-%control-objectkey = if_abap_behv=>mk-on.
      ls_head-object_key = <entity>-objectkey.
    ENDIF.
    IF <entity>-%control-texttype = if_abap_behv=>mk-on.
      ls_head-text_type = <entity>-texttype.
    ENDIF.
    IF <entity>-%control-language = if_abap_behv=>mk-on.
      ls_head-language = <entity>-language.
    ENDIF.

    " Update changed by and changed at
    GET TIME STAMP FIELD DATA(lv_timestamp).
    ls_head-changed_by = sy-uname.
    ls_head-changed_at = lv_timestamp.

    " Buffer the update
    lcl_buffer=>mt_head_update = VALUE #(
                                 BASE lcl_buffer=>mt_head_update (
                                 client      = sy-mandt
                                 uuid        = ls_head-uuid
                                 object_type = ls_head-object_type
                                 object_key  = ls_head-object_key
                                 text_type   = ls_head-text_type
                                 language    = ls_head-language
                                 created_by  = ls_head-created_by
                                 created_at  = ls_head-created_at
                                 changed_by  = ls_head-changed_by
                                 changed_at  = ls_head-changed_at  ) ).

    APPEND VALUE #(  %tky = <entity>-%tky ) TO mapped-zltr_i_head.
  ENDLOOP.
  ENDMETHOD.

  METHOD delete.
  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
    " Check record exists
    SELECT SINGLE uuid
      FROM zltr_head
      WHERE uuid   = @<key>-uuid
      INTO @DATA(lv_uuid).
    IF sy-subrc <> 0.
      APPEND VALUE #(
        %tky = <key>-%tky
        %msg = new_message_with_text(
                 severity = if_abap_behv_message=>severity-error
                 text     = 'Record not found for delete' )
      ) TO reported-zltr_i_head.
      CONTINUE.
    ENDIF.

    " Buffer for delete
    lcl_buffer=>mt_head_delete = VALUE #(
                                 BASE lcl_buffer=>mt_head_delete (
                                 client = sy-mandt
                                 uuid   = lv_uuid ) ).

    APPEND VALUE #( %tky = <key>-%tky ) TO mapped-zltr_i_head.
  ENDLOOP.
ENDMETHOD.

  METHOD read.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
        SELECT SINGLE uuid,
                      object_type,
                      object_key,
                      text_type,
                      language,
                      created_by,
                      created_at,
                      changed_by,
                      changed_at FROM zltr_head
                                 WHERE uuid = @<key>-uuid
                                 INTO @DATA(ls_head).
        IF sy-subrc = 0.
            APPEND VALUE #(
                   uuid = ls_head-uuid
                   ObjectType = ls_head-object_type
                   ObjectKey  = ls_head-object_key
                   TextType   = ls_head-text_type
                   Language   = ls_head-language
                   CreatedBy  = ls_head-created_by
                   CreatedAt  = ls_head-created_at
                   ChangedBy  = ls_head-changed_by
                   ChangedAt  = ls_head-changed_at
                   %tky       = <key>-%tky ) TO result.
        ELSE.
            APPEND VALUE #( %tky     = <key>-%tky
                            %msg     = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = 'Record not found' ) ) TO reported-zltr_i_head.

        ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Content.
  ENDMETHOD.

  METHOD cba_Content.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ZLTR_I_Content DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE ZLTR_I_Content.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE ZLTR_I_Content.

    METHODS read FOR READ
      IMPORTING keys FOR READ ZLTR_I_Content RESULT result.

    METHODS rba_Header FOR READ
      IMPORTING keys_rba FOR READ ZLTR_I_Content\_Header FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_ZLTR_I_Content IMPLEMENTATION.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD rba_Header.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZLTR_I_HEAD DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZLTR_I_HEAD IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
  ENDMETHOD.

  METHOD cleanup.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
