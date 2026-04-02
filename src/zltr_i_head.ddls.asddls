@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'LTR - Header Interface View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZLTR_I_Head
  as select from zltr_head
     composition [0..1] of ZLTR_I_Content as _Content
{
  key uuid          as UUID,
  object_type       as ObjectType,
  object_key        as ObjectKey,
  text_type         as TextType,
  language          as Language,
  created_by        as CreatedBy,
  created_at        as CreatedAt,
  changed_by        as ChangedBy,
  changed_at        as ChangedAt, 
  _Content
}
