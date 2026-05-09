@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'LTR - Content Consumption View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZLTR_C_Content
  as projection on ZLTR_I_Content
{
  key UUID,
      HeadUUID, 
      ShortText,
      LongText,
      Length,
      _Header : redirected to parent ZLTR_C_Head
}
