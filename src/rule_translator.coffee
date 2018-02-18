module = @

token_connector_parser = require './token_connector_parser'
strict_parser = require './strict_parser'

@translate = (scope, opt = {})->
  opt.gram_module ?= 'gram3'
  
  wrap_hk = (t)->"token_#{t}"
  rule_jl = []
  token_jl = []
  for group in scope.group_rule_list
    ret_hash = group.hash_key
    ret_hash_idx = group.hash_key_idx
    
    code_jl = []
    code_new_jl = []
    can_recursive = false
    for rule in group.list
      can_recursive = can_recursive or rule.can_recursive
      rule_fn_name = "rule_#{rule.name_get()}"
      code_jl.push """
        node_list.append @#{rule_fn_name} start_pos
        """
      code_new_jl.push """
        node_list.append @#{rule_fn_name} start_pos, true
        """
      
      mx_hash_setup_jl = []
      mx_hash_setup_jl.push "mx_hash_stub.hash_key = #{JSON.stringify ret_hash}"
      mx_hash_setup_jl.push "mx_hash_stub.hash_key_idx = #{ret_hash_idx}"
      for mx_rule in rule.mx_list
        if mx_rule.autoassign
          mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = node.value_array[0].mx_hash[#{JSON.stringify mx_rule.key}]"
        else
          mx_hash_setup_jl.push "mx_hash_stub[#{JSON.stringify mx_rule.key}] = #{strict_parser.translate mx_rule.value.ast, rule}"
      
      rule_code = token_connector_parser.translate rule.token_connector.ast
      
      aux_new_check = ""
      if rule.can_only_new_call
        aux_new_check = """
        if only_new
          continue if !hyp._is_new
        """
      
      strict_jl = []
      for strict_rule in rule.strict_list
        strict_jl.push "continue if !(#{strict_parser.translate strict_rule.ast, rule})"
      
      rule_jl.push """
        # #{rule.descr_get()}
        #{rule_fn_name} : (start_pos, only_new = false)->
          group_idx = 1
          
          zero_hyp = new Hypothesis
          zero_hyp.a = start_pos
          zero_hyp.b = start_pos
          hyp_list = [zero_hyp.clone()]
          
          #{make_tab rule_code, '  '}
          
          node_list = []
          for hyp in hyp_list
            #{make_tab aux_new_check, '    '}
            node = new Node
            node.mx_hash.rule = #{JSON.stringify rule_fn_name}
            vv_list = []
            for obj in hyp.list
              # TODO obj.label -> hash_pos_idx
              node.value_array.push obj.token
              vv_list.push obj.token.value_view or obj.token.value
            node.value_view = vv_list.join ' '
            
            arg_list = node.value_array
            #{join_list strict_jl, '    '}
            
            mx_hash_stub = node.mx_hash
            #{join_list mx_hash_setup_jl, '    '}
            
            node.a = node.value_array[0].a
            node.b = node.value_array.last().b
            
            node_list.push node
          
          return node_list
        
        """
    
    token_fn_name = wrap_hk group.hash_key
    
    drop_aux =""
    aux_recursive = ""
    if can_recursive
      drop_aux = """
      @drop[start_pos][#{ret_hash_idx}]++
      return [] if @drop[start_pos][#{ret_hash_idx}]
      
      """
      aux_recursive = """
      if @drop[start_pos][#{ret_hash_idx}]
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
      
    
    token_jl.push """
      #{token_fn_name} : (start_pos)->
        if start_pos >= @cache.length
          ### !pragma coverage-skip-block ###
          return []
        return ret if ret = @cache[start_pos][#{ret_hash_idx}]
        #{make_tab drop_aux, '  '}
        node_list = []
        #{join_list code_jl, '  '}
        
        FAcache = @cache[start_pos][#{ret_hash_idx}] = node_list
        #{make_tab aux_recursive, '  '}
        return FAcache
      
      """
  
  start_hash_key = scope.expected_token
  
  """
  require 'fy'
  {Node} = require #{JSON.stringify opt.gram_module}
  class Hypothesis
    a : 0
    b : 0
    list : []
    _is_new : false
    constructor : ()->
      @list = []
    
    clone : ()->
      ret = new Hypothesis
      ret.a = @a
      ret.b = @b
      ret.list = @list.clone()
      ret._is_new = @_is_new
      ret
    
    push   : (proxy_node)->
      @list.push proxy_node
      @b = proxy_node.token.b
      if @list.length == 1
        @_is_new = proxy_node.token._is_new
      return
    
  drop_stub = []
  for i in [0 ... #{scope.hash_key_list.length}]
    drop_stub.push -1
  cache_stub = new Array #{scope.hash_key_list.length}
  
  hash_key_list = #{JSON.stringify scope.hash_key_list, null, 2}
  
  class @Parser
    cache     : []
    drop      : []
    constructor : ()->
    
    go : (token_list_list)->
      @cache = []
      @drop  = []
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
      
      list = @#{wrap_hk start_hash_key}(0)
      max_token = token_list_list.length
      
      filter_list = []
      for v in list
        filter_list.push v if v.b == max_token
      # Прим. А все ошибки, почему не прошло ... смотрим и анализируем @cache и @drop
      filter_list
    
    #{join_list token_jl, '  '}
    #{join_list rule_jl, '  '}
  """
