define view entity ZLTR_I_Content
  as select from zltr_content
     association to parent ZLTR_I_Head as _Header 
     on $projection.UUID = _Header.UUID
{
  key uuid            as UUID,
      short_text      as ShortText,
      long_text       as LongText, 
      length          as Length, 
      _Header   
}
