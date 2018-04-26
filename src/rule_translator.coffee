module = @

token_connector_parser = require './token_connector_parser'
strict_parser = require './strict_parser'
{Node} = require './node'

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
    only_new
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
        only_new
      ]
      """
    if rule.can_recursive
      extra_reset = ""
      if rule._first_token_hash_key
        extra_reset = """
        stack.push [
          #{scope._extended_hash_key_list.idx rule._first_token_hash_key}
          start_pos
          1
        ]
        """
      code_queue_recursive_jl.push """
        ### #{rule_fn_name} ###
        stack.push [
          #{rule_idx}
          start_pos
          1
        ]
        #{extra_reset}
        """
    code_collect_jl.push """
      ### #{rule_fn_name} ###
      node_list.append FAcache[start_pos][#{rule_idx}]
      """
  
  drop_aux_queue = ""
  aux_recursive = "FAcache[start_pos][#{group.hash_key_idx}] = node_list"
  if can_recursive
    reset_jl = []
    idx_list = [group.hash_key_idx]
    for rule in group.list
      continue if !rule._first_token_hash_key
      idx_list.upush scope._extended_hash_key_list.idx rule._first_token_hash_key
    for idx in idx_list
      reset_jl.push """
        FAdrop[start_pos][#{idx}] = 0
        """
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
        #{join_list reset_jl, '    '}
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
    when 'nope'
      code = """
        ### NOPE ###
        #{code}
        """
    when 'pass'
      if pos.value_array.length != 1
        throw new Error "can't pass with pos.value_array.length != 1"
      return module.pos_translate scope, rule, pos.value_array[0], pp_idx, code, is_collect
    when 'const'
      value = pos.value_array[0].value
      value = value.substr 1 if value[0] == "\\"
      
      need_escape = true
      first = value[0]
      last  = value[value.length-1]
      if value.length >= 2
        if first == last
          if first in ["'", "\""]
            need_escape = false
      value = JSON.stringify(value) if need_escape
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
        sub_payload = module.pos_translate scope, rule, sub_pos, pp_idx, payload, is_collect
        if pos.mx_hash.synthetic
          # synthetic wrapper for continue
          # loop = forever
          # for _i_#{pp_idx} in [0 ... 1] - once
          sub_jl.push """
            for _i_#{pp_idx} in [0 ... 1]
              #{make_tab sub_payload, '  '}
            """
        else
          sub_jl.push sub_payload
      
      aux_synthetic = ""
      if pos.mx_hash.synthetic
        aux_skip = ""
        aux_synthetic = """
          #{b_n} = node.value_array.last().b
          """
      
      if code or !is_collect
        code = """
        #{aux_skip}
        hyp_list_#{pp_idx} = []
        old_node = node
        node = @proxy
        #{join_list sub_jl}
        node = old_node
        
        for tok_list in hyp_list_#{pp_idx}
          node.value_array.append tok_list
          #{aux_synthetic}
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
      when "option"
        if parse_position_list.length == 0
          throw new Error "option can't be at first position"
        
        nope = new Node
        nope.mx_hash.ult = 'nope'
        
        proxy = new Node
        proxy.mx_hash.ult = 'or'
        proxy.mx_hash.synthetic = '1'
        proxy.value_array.push nope
        proxy.value_array.push new Node # separator
        proxy.value_array.push ast.value_array[0]
        parse_position_list.push proxy
      when "plus"
        # need proxy rule
        # return ref on rule
        throw new Error "plus not implemented"
      when "star"
        # NOTE star == plus or nope
        throw new Error "star not implemented"
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
  
  # TODO DRY node.value_array.pop()
  strict_jl = []
  for strict_rule in rule.strict_list
    strict_jl.push """
      if !(#{strict_parser.translate strict_rule.ast, rule})
        node.value_array.pop()
        continue
      """
  
  backup_parse_position_list = parse_position_list.clone()
  
  code_queue = ""
  while pp_idx = parse_position_list.length
    pos = parse_position_list.pop()
    code_queue = module.pos_translate scope, rule, pos, pp_idx, code_queue, false
  # OPT
  # code_queue = code_queue.replace /(\n\s+)node\./g, '$1# node.'
  # ###################################################################################################
  
  parse_position_list = backup_parse_position_list
  
  code_collect = """
  arg_list = node.value_array
  #{join_list strict_jl}
  
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
    chk_len = stack.push [
      #{rule_idx}
      start_pos
      only_new
    ]
    ret_list = []
    b_0 = start_pos
    node = new @Node
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
    # FAcache[start_pos][#{rule_idx}] ?= []
    # FAcache[start_pos][#{rule_idx}].append ret_list
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
      return [] if @length == 0
      @Node = token_list_list[0]?[0]?.constructor
      @proxy= new @Node
      for token_list,idx in token_list_list
        stub = cache_stub.slice()
        for token in token_list
          token.a = idx
          token.b = idx+1
          if -1 != stub_idx = hash_key_list.idx token.mx_hash.hash_key
            stub[stub_idx] = [token]
          stub[0] = [token]
        @cache.push stub
        @drop.push drop_stub.slice()
      
      list = @fsm()
      max_token = token_list_list.length
      
      filter_list = []
      for v in list
        if v.b == max_token
          @node_fix v
          filter_list.push v
      # Прим. А все ошибки, почему не прошло ... смотрим и анализируем @cache
      filter_list
    
    node_fix : (node)->
      walk = (node)->
        vv_list = []
        for v in node.value_array
          walk v
          vv_list.push v.value_view or v.value
        node.value_view = vv_list.join ' '
        return
      walk node
      return
  
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