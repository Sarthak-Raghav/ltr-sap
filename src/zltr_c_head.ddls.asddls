@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'LTR - Header Consumption View'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZLTR_C_Head
      provider contract transactional_query
       as projection on ZLTR_I_Head
{
  key UUID,
      ObjectType,
      ObjectKey,
      TextType,
      Language,
      CreatedBy,
      CreatedAt,
      ChangedBy,
      ChangedAt,
      _Content : redirected to composition child ZLTR_C_Content
}
