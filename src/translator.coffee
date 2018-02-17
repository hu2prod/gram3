class @bin_op_translator_framework
  template  : ''
  
  constructor : (template)->
    @template     = template
  
  apply_template : (template, ctx, array)->
    list = template.split /(\$(?:1|2|op))/
    for v,k in list
      switch v
        when "$1"
          list[k] = array[0]
        when "$2"
          list[k] = array[2]
        when "$op"
          list[k] = array[1]
    list.join ""
  
  translate   : (ctx, array)->
    @apply_template @template, ctx, array
  

class @bin_op_translator_holder
  op_list     : {}
  
  constructor : ()->
    @op_list = {}
  
  translate   : (ctx, node)->
    tok = node.value_array[1]
    key = tok.value or tok.value_array[0]?.value
    throw new Error "unknown bin_op '#{key}' known bin_ops #{Object.keys(@op_list).join(' ')}" if !@op_list[key]?
    left  = ctx.translate node.value_array[0]
    right = ctx.translate node.value_array[2]
    @op_list[key].translate ctx, [ left , key , right ]
  
# ###################################################################################################
class @un_op_translator_framework
  template    : ''
  
  constructor : (template)->
    @template     = template
  
  apply_template : (template, ctx, array)->
    list = template.split /(\$(?:1|2|op))/
    for v,k in list
      switch v
        when "$1"
          list[k] = array[1]
        when "$op"
          list[k] = array[0]
    list.join ""
  
  translate   : (ctx, array)->
    @apply_template @template, ctx, array
  

class @un_op_translator_holder
  op_list       : {}
  op_position   : 0 # default pre
  left_position : 1
  
  constructor : ()->
    @op_list      = {}
  
  translate   : (ctx, node)->
    tok = node.value_array[@op_position]
    key = tok.value or tok.value_array[0]?.value
    throw new Error "unknown un_op '#{key}' known un_ops #{Object.keys(@op_list).join(' ')}" if !@op_list[key]?
    left  = ctx.translate node.value_array[@left_position]
    @op_list[key].translate ctx, [ key , left ]
  
  mode_pre  : ()->
    @op_position  = 0
    @left_position= 1
  
  mode_post   : ()->
    @op_position  = 1
    @left_position= 0
  
# ###################################################################################################
class @Translator
  translator_hash : {}
  key : 'ult'
  
  constructor : ()->
    @translator_hash  = {}
  
  translate   : (node)->
    key = node.mx_hash[@key]
    throw new Error "unknown node type '#{key}' mx='#{JSON.stringify node.mx_hash}' required key '#{@key}' value='#{node.value}'" if !@translator_hash[key]?
    @translator_hash[key].translate @, node
  # really public
  trans   : (node)->
    @translate node
  
  go    : (node)->
    @trans node

