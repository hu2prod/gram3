module = @

token_connector_parser = require './token_connector_parser'
strict_parser = require './strict_parser'

# NOTE plain sequence only. No quantificators
@translate_group = (group)->
  can_recursive = false
  for rule in group.list
    can_recursive = can_recursive or rule.can_recursive
  # ###################################################################################################
  code_jl = []
  code_new_jl = []
  for rule in group.list
    rule_fn_name = "rule_#{rule.name_get()}"
    code_jl.push """
      node_list.append @#{rule_fn_name} start_pos
      """
    code_new_jl.push """
      node_list.append @#{rule_fn_name} start_pos, true
      """
  
  drop_aux =""
  aux_recursive = ""
  if can_recursive
    drop_aux = """
    @drop[start_pos][#{group.hash_key_idx}]++
    return [] if @drop[start_pos][#{group.hash_key_idx}]
    
    """
    aux_recursive = """
    if @drop[start_pos][#{group.hash_key_idx}]
      # recursive case
      for node in node_list
        node._is_new = true
      loop
        old_node_list = node_list
        node_list = []
        #{join_list code_new_jl, '    '}
        break if node_list.length == 0
        
        for node in old_node_list
          node._is_new = false
        for node in node_list
          node._is_new = true
        
        FAcache.append node_list
    """
  
  """
  token_#{group.hash_key} : (start_pos)->
    if start_pos >= @cache.length
      ### !pragma coverage-skip-block ###
      return []
    return ret if ret = @cache[start_pos][#{group.hash_key_idx}]
    #{make_tab drop_aux, '  '}
    node_list = []
    #{join_list code_jl, '  '}
    
    FAcache = @cache[start_pos][#{group.hash_key_idx}] = node_list
    #{make_tab aux_recursive, '  '}
    return FAcache
  """

@or_flatten = (pos)->
  ret = []
  walk = (ast)->
    if ast.mx_hash.ult == 'or'
      walk ast.value_array[0]
      walk ast.value_array[2]
    else
      ret.push ast
    return
  
  walk pos
  ret

@pos_translate = (scope, rule, pos, pp_idx, code)->
  b = "b_#{pp_idx - 1}"
  b_n = "b_#{pp_idx}"

  # for * ? quantificators need some workaround
  # DO NOT change push/pop bacause you can't always estimate position (variable length with quantificators)
  aux_skip = ""
  if pp_idx != 1
    aux_skip = "continue if #{b} >= @length"
  
  aux_const_check = ""
  casual_wrap = (prev_code, access)->
    # if pp_idx == 1 and scope.can_recursive
    if pp_idx == 1
      aux_const_check = """
        if only_new
          continue if !tok._is_new
        #{aux_const_check}
        """
    """
    #{aux_skip}
    for tok in #{access}
      #{make_tab aux_const_check, '  '}
      #{b_n} = tok.b
      node.value_array.push tok
      
      #{make_tab prev_code, '  '}
      
      node.value_array.pop()
    """
  switch pos.mx_hash.ult
    when 'pass'
      if pos.value_array.length != 1
        throw new Error "can't pass with pos.value_array.length != 1"
      return module.pos_translate scope, rule, pos.value_array[0], pp_idx, code
    when 'const'
      value = pos.value_array[0].value
      value = value.substr 1 if value[0] == "\\"
      value = JSON.stringify(value) if value[0] != "'"
      aux_const_check = """
        continue if tok.value != #{value}
        """
      access = "@cache[#{b}][0]"
      code = casual_wrap code, access
    when  'ref'
      value = pos.value_array[0].value
      name = value.substr(1)
      access = "@cache[#{b}][#{scope.hash_key_list.idx name}] or @token_#{name} #{b}"
      code = casual_wrap code, access
    when 'or'
      sub_jl = []
      payload = """
        hyp_list_#{pp_idx}.push node.value_array.clone()
        """
      or_list = module.or_flatten pos
      for sub_pos in or_list
        # 1 что б не сработал aux_skip
        sub_jl.push """
          #{module.pos_translate scope, rule, sub_pos, 1, payload}
          """
      code = """
      #{aux_skip}
      hyp_list_#{pp_idx} = []
      old_node = node
      node = @proxy
      #{join_list sub_jl}
      node = old_node
      
      for tok_list in hyp_list_#{pp_idx}
        node.value_array.append tok_list
        
        #{make_tab code, '  '}
        
        node.value_array.length -= tok_list.length
      """
  
  code

@translate_rule = (rule, group, scope)->
  parse_position_list = []
  walk = (ast)->
    switch ast.mx_hash.ult
      when "const", "ref", "or"
        parse_position_list.push ast
      when "pass", "join"
        for v in ast.value_array
          walk v
      else
        throw new Error "unknown ult #{ast.mx_hash.ult}"
    return
  walk rule.token_connector.ast
  # ###################################################################################################
  # TODO asap strict check
  rule_fn_name = "rule_#{rule.name_get()}"
  
  mx_hash_setup_jl = []
  mx_hash_setup_jl.push "mx_hash_stub.hash_key = #{JSON.stringify group.hash_key}"
  mx_hash_setup_jl.push "mx_hash_stub.hash_key_idx = #{group.hash_key_idx}"
  for mx_rule in rule.mx_list
    if mx_rule.autoassign
      mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = node.value_array[0].mx_hash[#{JSON.stringify mx_rule.key}]"
    else
      mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = #{strict_parser.translate mx_rule.value.ast, rule}"
  
  strict_jl = []
  for strict_rule in rule.strict_list
    strict_jl.push "continue if !(#{strict_parser.translate strict_rule.ast, rule})"
  
  code = """
  arg_list = node.value_array
  #{join_list strict_jl}
  
  vv_list = []
  for obj in node.value_array
    vv_list.push obj.value_view or obj.value
  node.value_view = vv_list.join ' '
  
  mx_hash_stub = node.mx_hash = {}
  mx_hash_stub.rule = #{JSON.stringify rule_fn_name}
  
  #{join_list mx_hash_setup_jl}
  
  node.b = node.value_array.last().b
  
  ret_list.push node.clone()
  
  """
  while pp_idx = parse_position_list.length
    pos = parse_position_list.pop()
    code = module.pos_translate scope, rule, pos, pp_idx, code
  
  """
  #{rule_fn_name} : (start_pos, only_new = false)->
    ret_list = []
    b_0 = start_pos
    node = new @Node
    node.a = start_pos
    #{make_tab code, '  '}
    ret_list
  """

@translate_token = (rule)->

@translate = (scope)->
  rule_jl = []
  token_jl = []
  
  for group in scope.group_rule_list
    for rule in group.list
      rule_jl.push @translate_rule rule, group, scope
    token_jl.push @translate_group group, scope
  """
  require 'fy'
  drop_stub = []
  for i in [0 ... #{scope.hash_key_list.length}]
    drop_stub.push -1
  cache_stub = new Array #{scope.hash_key_list.length}
  
  hash_key_list = #{JSON.stringify scope.hash_key_list, null, 2}
  
  class @Parser
    length: 0
    cache : []
    drop  : []
    Node  : null
    proxy : null
    
    go : (token_list_list)->
      @cache= []
      @drop = []
      @length = token_list_list.length
      @Node = token_list_list[0]?[0]?.constructor
      @proxy= new @Node
      for token_list,idx in token_list_list
        stub = cache_stub.slice()
        for token in token_list
          token.a = idx
          token.b = idx+1
          if -1 != idx = hash_key_list.idx token.mx_hash.hash_key
            stub[idx] = [token]
          stub[0] = [token]
        @cache.push stub
        @drop.push drop_stub.slice()
      
      list = @token_#{scope.expected_token}(0)
      max_token = token_list_list.length
      
      filter_list = []
      for v in list
        filter_list.push v if v.b == max_token
      # Прим. А все ошибки, почему не прошло ... смотрим и анализируем @cache и @drop
      filter_list
    #{join_list token_jl, '  '}
    #{join_list rule_jl, '  '}
  """