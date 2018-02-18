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
  
  aux_drop = ""
  if ctx.catch_first
    ctx.catch_first = false
    aux_drop = """
      if only_new
        hyp_list = []
      """
  
  label = node.mx_hash.label
  """
  #{aux_drop}
  prev_hyp_list = hyp_list
  hyp_list = []
  for hyp_base in prev_hyp_list
    loop
      b = hyp_base.last()?.b ? start_pos
      break if b >= @cache.length
      token_list = @cache[b][0]
      for token in token_list
        break if token.value != #{value}
        hyp = hyp_base.clone()
        hyp.push token
        hyp_list.push hyp
      break
  
  """
wrap_collide = (loc_res, ctx)->
  if ctx.catch_first
    ctx.catch_first = false
    """
    prev_hyp_list = hyp_list
    hyp_list = []
    for hyp in prev_hyp_list
      for append_me in #{loc_res}
        if only_new
          continue if !append_me._is_new
        hyp_add = hyp.clone()
        hyp_add.push append_me
        hyp_list.push hyp_add
    
    """
  else
    """
    prev_hyp_list = hyp_list
    hyp_list = []
    for hyp in prev_hyp_list
      for append_me in #{loc_res}
        hyp_add = hyp.clone()
        hyp_add.push append_me
        hyp_list.push hyp_add
    
    """

trans.translator_hash['ref']   = translate:(ctx, node)->
  value = node.value_array[0].value
  name = value.substr(1)
  label = node.mx_hash.label
  wrap_collide "@token_#{name}(hyp.last()?.b ? start_pos)", ctx

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
      for obj in hyp
        node.value_array.push obj
      
      node.a = node.value_array[0].a
      node.b = node.value_array.last().b
      
      wrap_hyp = zero_hyp.clone()
      wrap_hyp.list = [{
        token : node
        label : 'group_'+loc_group_idx
      }]
      ext_hyp_list.push wrap_hyp
    #{if variation == 'option' then 'break' else ''}
  hyp_list = store
  #{wrap_collide 'ext_hyp_list', ctx}
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
  
  {catch_first} = ctx
  pass1 = ctx.translate node.value_array[0]
  ctx.catch_first = catch_first
  pass2 = ctx.translate node.value_array[2]
  
  """
  #{bak_hyp_list} = hyp_list
  #{pass1}
  #{a_hyp_list} = hyp_list
  hyp_list = #{bak_hyp_list}
  #{pass2}
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
  trans.catch_first = true
  trans.go ast




