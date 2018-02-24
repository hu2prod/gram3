require 'fy'
module = @
class @Node
  mx_hash       : {}
  hash_key_idx  : 0
  value         : ''
  value_view    : ''
  value_array   : []
  line          : -1
  pos           : -1
  a             : 0
  b             : 0
  _is_new       : false # private for parsing stage
  
  constructor   : (value = '', mx_hash = {})->
    @mx_hash    = mx_hash
    @value      = value
    @value_array  = []
  
  cmp       : (t) ->
    for k,v of @mx_hash
      return false if v != t.mx_hash[k]
    for k,v of t.mx_hash
      return false if v != @mx_hash[k]
    return false if @value != t.value
    true
  
  name : (name)->
    ret = []
    for v in @value_array
      ret.push v if v.mx_hash.hash_key == name
    ret
  
  str_uid : ()->
    "#{@value} #{JSON.stringify @mx_hash}"
  
  clone : ()->
    ret = new module.Node
    ret.mx_hash       = clone @mx_hash
    ret.hash_key_idx  = @hash_key_idx
    ret.value         = @value       
    ret.value_view    = @value_view  
    ret.value_array   = @value_array.clone()
    ret.line          = @line        
    ret.pos           = @pos         
    ret.a             = @a           
    ret.b             = @b           
    ret._is_new       = @_is_new     
    
    ret
