{parse} = require './token_connector_gen'

# ###################################################################################################
#    trans pure
# ###################################################################################################

{
  Translator
} = require './translator'

trans = new Translator

deep = (ctx, node)->
  list = []
  value_array = node.value_array
  for v,k in value_array
    list.push ctx.translate v
  list

trans.translator_hash['pass']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('\n')

trans.translator_hash['join']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('\n')

trans.translator_hash['const']   = translate:(ctx, node)->
  value = node.value_array[0].value
  value = value.substr 1 if value[0] == "\\"
  value = JSON.stringify(value) if value[0] != "'"
  
  label = node.mx_hash.label
  """
  prev_hyp_list = hyp_list
  hyp_list = []
  for hyp_base in prev_hyp_list
    loop
      break if !token_list = @cache[hyp_base.b]?['*']
      for token in token_list
        break if token.value != #{value}
        hyp = hyp_base.clone()
        hyp.push {
          token
          label : #{JSON.stringify label}
        }
        hyp_list.push hyp
      break
  
  """
wrap_collide = (loc_res)->
  """
  prev_hyp_list = hyp_list
  hyp_list = []
  for hyp in prev_hyp_list
    for append_me in #{loc_res}
      hyp_add = hyp.clone()
      hyp_add.push {
        token : append_me
        label : 'TODO_tok_pos'
      }
      hyp_list.push hyp_add
  
  """

trans.translator_hash['ref']   = translate:(ctx, node)->
  value = node.value_array[0].value
  name = value.substr(1)
  label = node.mx_hash.label
  wrap_collide "@token_#{name} hyp.b"

wrap_inner = (inner, variation)->
  aux_option = ""
  if variation in ['option', 'star']
    aux_option = """
    node = new Node
    node.mx_hash.group = loc_group_idx
    ext_hyp_list.push node
    
    """
  """
  store = hyp_list
  ext_hyp_list = []
  loc_group_idx = group_idx++
  #{aux_option}
  hyp_list = [zero_hyp.clone()]
  loop
    #{make_tab inner, '  '}
    
    break if hyp_list.length == 0
    for hyp in hyp_list
      node = new Node
      node.mx_hash.group = loc_group_idx
      for obj in hyp.list
        node.value_array.push obj.token
      
      node.a = node.value_array[0].a
      node.b = node.value_array.last().b
      
      wrap_hyp = zero_hyp.clone()
      wrap_hyp.a = node.a
      wrap_hyp.b = node.b
      wrap_hyp.list = [{
        token : node
        label : 'group_'+loc_group_idx
      }]
      ext_hyp_list.push wrap_hyp
    #{if variation == 'option' then 'break' else ''}
  hyp_list = store
  #{wrap_collide 'ext_hyp_list'}
  """
  
trans.translator_hash['plus']   = translate:(ctx, node)->
  inner = ctx.translate node.value_array[0]
  wrap_inner inner, 'plus'

trans.translator_hash['star']   = translate:(ctx, node)->
  xxx
  api_gen.star node.value_array[0]
  wrap_inner inner, 'star'

trans.translator_hash['option']   = translate:(ctx, node)->
  xxx
  api_gen.option node.value_array[0]
  wrap_inner inner, 'option'

trans.translator_hash['or']   = translate:(ctx, node)->
  ctx.tmp_var_idx ?= 0
  bak_hyp_list = "bak_hyp_list_#{ctx.tmp_var_idx}"
  a_hyp_list = "a_hyp_list_#{ctx.tmp_var_idx}"
  ctx.tmp_var_idx++
  """
  #{bak_hyp_list} = hyp_list
  #{ctx.translate node.value_array[0]}
  #{a_hyp_list} = hyp_list
  hyp_list = #{bak_hyp_list}
  #{ctx.translate node.value_array[2]}
  hyp_list = arr_merge #{a_hyp_list}, hyp_list
  
  """

@parse = (str)->
  ast = parse str
  
  if ast.length == 0
    throw new Error "Parsing error. No proper combination found"
  if ast.length != 1
    ### !pragma coverage-skip-block ###
    throw new Error "Parsing error. More than one proper combination found #{ast.length}"
  
  {
    ast : ast[0]
  }

@translate = (ast)->
  trans.go ast




