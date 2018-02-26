module = @

token_connector_parser = require './token_connector_parser'
strict_parser = require './strict_parser'

# NOTE plain sequence only. No quantificators
@translate_group = (group, scope)->
  can_recursive = false
  for rule in group.list
    can_recursive = can_recursive or rule.can_recursive
  group_name = "token_#{group.hash_key}"
  scope._extended_hash_key_list.push group_name
  ext_idx = scope._extended_hash_key_list.idx group_name
  # ###################################################################################################
  code_queue_jl = []
  code_queue_recursive_jl = []
  code_collect_jl = []
  
  # self call after all
  code_queue_jl.push """
  stack.push [
    #{ext_idx}
    start_pos
    0
  ]
  """
  
  for rule in group.list
    rule_fn_name = "rule_#{rule.name_get()}"
    rule_idx = scope._extended_hash_key_list.idx rule_fn_name
    code_queue_jl.push """
      ### #{rule_fn_name} ###
      stack.push [
        #{rule_idx}
        start_pos
        0
      ]
      """
    if rule.can_recursive
      code_queue_recursive_jl.push """
        ### #{rule_fn_name} ###
        stack.push [
          #{rule_idx}
          start_pos
          1
        ]
        """
    code_collect_jl.push """
      ### #{rule_fn_name} ###
      node_list.append FAcache[start_pos][#{rule_idx}]
      """
  
  drop_aux_queue = ""
  aux_recursive = "FAcache[start_pos][#{group.hash_key_idx}] = node_list"
  if can_recursive
    drop_aux_queue = """
    if FAdrop[start_pos][#{group.hash_key_idx}]
      FAcache[start_pos][#{group.hash_key_idx}] ?= []
      continue
    FAdrop[start_pos][#{group.hash_key_idx}] = 1
    """
    aux_recursive = """
    for node in node_list
      node._is_new = true
    if append_list = FAcache[start_pos][#{group.hash_key_idx}]
      for node in append_list
        node._is_new = false
      append_list.uappend node_list
    else
      FAcache[start_pos][#{group.hash_key_idx}] = node_list
    if FAdrop[start_pos][#{group.hash_key_idx}]
      if node_list.last()?._is_new
        # recursive case
        stack.push [
          #{ext_idx}
          start_pos
          1
        ]
        #{join_list code_queue_recursive_jl, '    '}
    """
  
  """
  when #{group.hash_key_idx}
    ### #{group_name} queue ###
    #{make_tab drop_aux_queue, '  '}
    #{join_list code_queue_jl, '  '}
  # TODO recursive recheck
  when #{ext_idx}
    ### #{group_name} collect ###
    node_list = []
    #{join_list code_collect_jl, '  '}
    #{make_tab aux_recursive, '  '}
  
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

@pos_translate = (scope, rule, pos, pp_idx, code, is_collect)->
  b = "b_#{pp_idx - 1}"
  b_n = "b_#{pp_idx}"

  # for * ? quantificators need some workaround
  # DO NOT change push/pop bacause you can't always estimate position (variable length with quantificators)
  aux_skip = ""
  if pp_idx != 1
    aux_skip = "continue if #{b} >= length"
  
  
  
  aux_const_check = ""
  casual_wrap = (prev_code, access_idx)->
    return "" if prev_code == "" and access_idx == 0
    access_str = "FAcache[#{b}][#{access_idx}]"
    iterator = if is_collect or access_idx == 0
      "list_#{pp_idx} = #{access_str}"
    else
      """
      list_#{pp_idx} = #{access_str}
      if !list_#{pp_idx}
        stack.push [
          #{access_idx}
          #{b}
          0
        ]
        continue
      """
    # if pp_idx == 1 and scope.can_recursive
    if pp_idx == 1
      aux_const_check = """
        if only_new
          continue if !tok._is_new
        #{aux_const_check}
        """
    aux_loop = ""
    if prev_code
      aux_loop = """
      for tok in list_#{pp_idx}
        #{make_tab aux_const_check, '  '}
        #{b_n} = tok.b
        node.value_array.push tok
        
        #{make_tab prev_code, '  '}
        
        node.value_array.pop()
      """
    """
    #{aux_skip}
    #{iterator}
    #{aux_loop}
    """
  switch pos.mx_hash.ult
    when 'pass'
      if pos.value_array.length != 1
        throw new Error "can't pass with pos.value_array.length != 1"
      return module.pos_translate scope, rule, pos.value_array[0], pp_idx, code, is_collect
    when 'const'
      value = pos.value_array[0].value
      value = value.substr 1 if value[0] == "\\"
      value = JSON.stringify(value) if value[0] != "'"
      aux_const_check = """
        continue if tok.value != #{value}
        """
      code = casual_wrap code, 0
    when  'ref'
      value = pos.value_array[0].value
      name = value.substr(1)
      code = casual_wrap code, scope.hash_key_list.idx name
    when 'or'
      sub_jl = []
      payload = """
        hyp_list_#{pp_idx}.push node.value_array.clone()
        """
      or_list = module.or_flatten pos
      for sub_pos in or_list
        # 1 что б не сработал aux_skip
        sub_jl.push """
          #{module.pos_translate scope, rule, sub_pos, 1, payload, is_collect}
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
  rule_fn_name = "rule_#{rule.name_get()}"
  scope._extended_hash_key_list.push rule_fn_name
  rule_idx = scope._extended_hash_key_list.idx rule_fn_name
  
  ext_rule_fn_name = "_collect_#{rule_fn_name}"
  scope._extended_hash_key_list.push ext_rule_fn_name
  ext_rule_idx = scope._extended_hash_key_list.idx ext_rule_fn_name
  # ###################################################################################################
  
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
  
  backup_parse_position_list = parse_position_list.clone()
  
  code_queue = ""
  while pp_idx = parse_position_list.length
    pos = parse_position_list.pop()
    code_queue = module.pos_translate scope, rule, pos, pp_idx, code_queue, false
  # ###################################################################################################
  
  parse_position_list = backup_parse_position_list
  
  code_collect = """
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
    code_collect = module.pos_translate scope, rule, pos, pp_idx, code_collect, true
  
  # ###################################################################################################
  # TODO perf проблема с queue. Запускается по несколько раз т.к. не может знать все позиции с первого запроса
  
  # chk_len можно было бы обойтись без break, который явно ставит coffeescript
  """
  when #{rule_idx}
    ### #{rule_fn_name} queue ###
    stack.push [
      #{rule_idx}
      start_pos
      only_new
    ]
    chk_len = stack.length
    ret_list = []
    b_0 = start_pos
    node = new @Node
    node.a = start_pos
    #{make_tab code_queue, '  '}
    if chk_len == stack.length
      stack[chk_len-1][0] = #{ext_rule_idx}
  when #{ext_rule_idx}
    ### #{rule_fn_name} collect ###
    ret_list = []
    b_0 = start_pos
    node = new @Node
    node.a = start_pos
    #{make_tab code_collect, '  '}
    FAcache[start_pos][#{rule_idx}] = ret_list
  """

@translate = (scope)->
  rule_jl = []
  token_jl = []
  bak_hash_key_list = scope.hash_key_list.clone()
  
  for group in scope.group_rule_list
    for rule in group.list
      rule_jl.push @translate_rule rule, group, scope
    token_jl.push @translate_group group, scope
  
  hash_key_list = scope._extended_hash_key_list
  """
  require 'fy'
  drop_stub = []
  for i in [0 ... #{scope.hash_key_list.length}]
    drop_stub.push 0
  cache_stub = new Array #{hash_key_list.length}
  
  hash_key_list = #{JSON.stringify bak_hash_key_list, null, 2}
  
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
      
      list = @fsm()
      max_token = token_list_list.length
      
      filter_list = []
      for v in list
        filter_list.push v if v.b == max_token
      # Прим. А все ошибки, почему не прошло ... смотрим и анализируем @cache
      filter_list
  
    fsm : ()->
      FAcache = @cache
      FAdrop = @drop
      stack = [
        [
          #{hash_key_list.idx scope.expected_token}
          0
          0
        ]
      ]
      length = @length
      
      while cur = stack.pop()
        [
          hki
          start_pos
          only_new
        ] = cur
        continue if start_pos >= length
        if !only_new
          continue if list = FAcache[start_pos][hki]
        
        switch hki
          #{join_list token_jl, '        '}
          #{join_list rule_jl, '        '}
      
      FAcache[start_pos][#{hash_key_list.idx scope.expected_token}]
  """