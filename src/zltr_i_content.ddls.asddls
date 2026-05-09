@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'LTR - Content Base View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZLTR_I_Content
  as select from zltr_content
     association to parent ZLTR_I_Head as _Header 
     on $projection.HeadUUID = _Header.UUID
{
  key uuid            as UUID,
      head_uuid       as HeadUUID, 
      short_text      as ShortText,
      long_text       as LongText, 
      length          as Length, 
      _Header   
}
