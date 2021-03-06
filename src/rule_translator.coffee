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
  
  extra_reset_jl = []
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
      if rule._first_token_hash_key
        extra_reset_jl.upush """
        request_make #{scope._extended_hash_key_list.idx rule._first_token_hash_key}, start_pos, 1
        """
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
  
  code_queue_recursive_jl.append extra_reset_jl
  
  aux_recursive = """
    FAstate[start_pos][#{group.hash_key_idx}] = STATE_FL
    FAcache[start_pos][#{group.hash_key_idx}].uappend node_list
    """
  if can_recursive
    aux_recursive = """
    append_list = FAcache[start_pos][#{group.hash_key_idx}]
    has_new = false
    for node in node_list
      if append_list.has node
        node._is_new = false
      else
        node._is_new = true
        append_list.push node
        has_new = true
    
    state = FAstate[start_pos][#{group.hash_key_idx}]
    FAstate[start_pos][#{group.hash_key_idx}] = STATE_FL
    if state == STATE_IG
      if has_new
        # recursive case
        FAstate[start_pos][#{group.hash_key_idx}] = STATE_RQ
        stack.push [
          #{group.hash_key_idx}
          start_pos
          1
        ]
        #{join_list extra_reset_jl, '    '}
    
    """
  
  """
  when #{group.hash_key_idx}
    ### #{group_name} queue ###
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

@_const_ast_to_string = (pos)->
  while pos.mx_hash.ult == 'pass'
    pos = pos.value_array[0]
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
  value

@_counter_idx = 0
@pos_translate = (scope, rule, pos, pp_idx, code, is_collect)->
  b = "b_#{pp_idx - 1}"
  b_n = "b_#{pp_idx}"

  # for * ? quantificators need some workaround
  # DO NOT change push/pop bacause you can't always estimate position (variable length with quantificators)
  aux_skip = ""
  if pp_idx != 1
    # aux_skip = "continue if #{b} >= length"
    aux_skip = """
      if #{b} >= length
        node.value_array.pop()
        continue
      """
  
  
  
  aux_const_check = ""
  casual_wrap = (prev_code, access_idx)->
    return "" if prev_code == "" and access_idx == 0
    access_str = "FAcache[#{b}][#{access_idx}]"
    iterator = if is_collect or access_idx == 0
      "list_#{pp_idx} = #{access_str}"
    else
      """
      state_#{pp_idx} = FAstate[#{b}][#{access_idx}]
      if state_#{pp_idx} != STATE_FL
        if request_make #{access_idx}, #{b}, 0
          continue
      list_#{pp_idx} = #{access_str}
      """
    
    # if pp_idx == 1
    #   aux_const_check = """
    #     if only_new
    #       continue if !tok._is_new
    #     #{aux_const_check}
    #     """
    aux_loop = ""
    if prev_code
      # for tok in list_#{pp_idx} produces 2 extra variables
      # for idx_#{pp_idx} in [0 ... len_#{pp_idx}] by 1 produces extra variable
      ###
      disabled var opt
      len_#{pp_idx} = list_#{pp_idx}.length
      idx_#{pp_idx} = 0
      while idx_#{pp_idx} < len_#{pp_idx}
        tok = list_#{pp_idx}[idx_#{pp_idx}++]
      ###
      counter_idx = module._counter_idx++
      if pp_idx == 1
        aux_loop = """
        for idx_#{pp_idx} in [FAcounter[#{b}][#{counter_idx}] ... list_#{pp_idx}.length] by 1
          tok = list_#{pp_idx}[idx_#{pp_idx}]
          #{make_tab aux_const_check, '  '}
          #{b_n} = tok.b
          node.value_array.push tok
          
          #{make_tab prev_code, '  '}
          
          node.value_array.pop()
        """
        if is_collect
          aux_loop += """
            
            FAcounter[#{b}][#{counter_idx}] = list_#{pp_idx}.length
            """
      else
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
      value = module._const_ast_to_string pos
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
    node = @proxy2
    node.value_array.clear()
    #{make_tab code_queue, '  '}
    if chk_len == stack.length
      stack[chk_len-1][0] = #{ext_rule_idx}
  when #{ext_rule_idx}
    ### #{rule_fn_name} collect ###
    ret_list = []
    b_0 = start_pos
    node = @proxy2
    node.value_array.clear()
    node.a = start_pos
    #{make_tab code_collect, '  '}
    
    FAcache[start_pos][#{rule_idx}].append ret_list
    #safe_collect FAcache[start_pos][#{rule_idx}], ret_list
  """

@translate = (scope)->
  module._counter_idx = 0
  rule_jl = []
  token_jl = []
  bak_hash_key_list = scope.hash_key_list.clone()
  
  for group in scope.group_rule_list
    for rule in group.list
      rule_jl.push @translate_rule rule, group, scope
    token_jl.push @translate_group group, scope
  
  aux_one_const_jl = []
  if scope._one_const_rule_list.length > 0
    for rule in scope._one_const_rule_list
      value = module._const_ast_to_string rule.token_connector.ast
      
      rule_fn_name = "rule_#{rule.name_get()}"
      
      mx_hash_setup_jl = []
      mx_hash_setup_jl.push "mx_hash_stub.hash_key = #{JSON.stringify rule.ret_hash_key}"
      mx_hash_setup_jl.push "mx_hash_stub.hash_key_idx = #{rule.ret_hash_key_idx}"
      for mx_rule in rule.mx_list
        if mx_rule.autoassign
          mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = node.value_array[0].mx_hash[#{JSON.stringify mx_rule.key}]"
        else
          mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = #{strict_parser.translate mx_rule.value.ast, rule}"
      
      strict_jl = []
      for strict_rule in rule.strict_list
        strict_jl.push """
          if !(#{strict_parser.translate strict_rule.ast, rule})
            node.value_array.pop()
            continue
          """
      
      hki = rule.ret_hash_key_idx
      aux_one_const_jl.push """
        for token_list,idx in token_list_list
          token = token_list[0]
          continue if token.value != #{value}
          
          node = new @Node
          node.value_array.push token
          # COPYPASTE
          arg_list = node.value_array
          #{join_list strict_jl, '  '}
          
          mx_hash_stub = node.mx_hash = {}
          mx_hash_stub.rule = #{JSON.stringify rule_fn_name}
          
          #{join_list mx_hash_setup_jl, '  '}
          
          node.a = node.value_array[0].a
          node.b = node.value_array.last().b
          
          # TODO у ret могут быть и другие правила, потому не надо сразу засырать cache
          _pos_list = @cache[idx]
          if !_pos_list[#{hki}]?
            _pos_list[#{hki}] = []
          _pos_list[#{hki}].push node
        
        """
    
  
  hash_key_list = scope._extended_hash_key_list
  """
  require 'fy'
  STATE_NA = 0
  STATE_RQ = 1 # REQ
  STATE_IG = 2 # REQ_IGNORE
  STATE_FL = 3 # REQ_FILL
  state_stub = []
  for i in [0 ... #{scope.hash_key_list.length}]
    state_stub.push STATE_NA
  counter_stub = []
  for i in [0 ... #{module._counter_idx}]
    counter_stub.push 0
  
  hash_key_list = #{JSON.stringify bak_hash_key_list, null, 2}
  
  class @Parser
    length: 0
    cache : []
    state : []
    counter: []
    Node  : null
    proxy : null
    proxy2: null
    
    go : (token_list_list)->
      @cache= []
      @state= []
      @counter= []
      @length = token_list_list.length
      return [] if @length == 0
      @Node = token_list_list[0]?[0]?.constructor
      @proxy= new @Node
      @proxy2= new @Node
      for token_list,idx in token_list_list
        stub = new Array #{hash_key_list.length}
        for k in [0 ... #{hash_key_list.length}]
          stub[k] = []
        for token in token_list
          token.a = idx
          token.b = idx+1
          if -1 != stub_idx = hash_key_list.idx token.mx_hash.hash_key
            stub[stub_idx].push token
          stub[0].upush token
        @cache.push stub
        @state.push state_stub.slice()
        @counter.push counter_stub.slice()
      
      # one const rule opt
      #{join_list aux_one_const_jl, '    '}
      
      @fsm()
      list = @cache[0][#{hash_key_list.idx scope.expected_token}]
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
        max_depth = -1
        for v in node.value_array
          walk v
          max_depth = Math.max max_depth, v.depth
        node.depth = max_depth + 1
        if node.depth < 10 # HARDCODE !!!
          for v in node.value_array
            vv_list.push v.value_view or v.value
          node.value_view = vv_list.join ' '
        return
      walk node
      return
  
    fsm : ()->
      FAcache = @cache
      FAstate = @state
      FAcounter = @counter
      stack = [
        [
          #{hash_key_list.idx scope.expected_token}
          0
          0
        ]
      ]
      FAstate[0][#{hash_key_list.idx scope.expected_token}] = STATE_RQ
      length = @length
      request_make = (token_hki, pos, is_new)->
        state = FAstate[pos][token_hki]
        switch state
          when 0 # STATE_NA
            if is_new
              ### !pragma coverage-skip-block ###
              throw new Error 'invalid call. STATE_NA + is_new'
            stack.push [token_hki, pos, is_new]
            FAstate[pos][token_hki] = STATE_RQ
            return true
          when 1 # STATE_RQ
            FAstate[pos][token_hki] = STATE_IG
            return false
          when 2 # STATE_IG
            # stack.push [token_hki, pos, is_new]
            return false
          when 3 # STATE_FL
            FAstate[pos][token_hki] = STATE_RQ
            stack.push [token_hki, pos, is_new]
            return true
        return
      # TODO remove
      safe_collect = (dst, src)->
        # TODO hash[candidate.b] optimization
        # Вместо того, чтобы проходить всегда можно спросить а есть ли такой длинны уже найденый токен
        # И хранить можно hash или массив b и быстро спрашивать по надобности
        # В случае хэша, там же можно хранить только токены такой длинны
        for candidate in src
          found = false
          for chk in dst
            # continue if chk.b != candidate.b
            c_varr = candidate.value_array
            continue if chk.value_array.length != c_varr.length
            match = true
            for chk_v,idx in chk.value_array
              if chk_v != c_varr[idx]
                match = false
                break
            if match
              found = true
              break
          if !found
            dst.push candidate
        return
      
      while cur = stack.pop()
        [
          hki
          start_pos
          only_new
        ] = cur
        continue if start_pos >= length
        
        switch hki
          #{join_list token_jl, '        '}
          #{join_list rule_jl, '        '}
      
      return
  """