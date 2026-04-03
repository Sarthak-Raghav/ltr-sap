@AbapCatalog.viewEnhancementCategory: [#NONE]
@EndUserText.label: 'LTR - Content Consumption View'
@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
define view entity ZLTR_C_Content
  as projection on ZLTR_I_Content
{
  key UUID,
      ShortText,
      LongText,
      Length,
      _Header : redirected to parent ZLTR_C_Head
}
