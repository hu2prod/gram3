module = @
require 'fy'
{Node} = require './node'
strict_parser = require './strict_parser'
token_connector_parser = require './token_connector_parser'
rule_translator = require './rule_translator'

# ###################################################################################################
#    Gram_rule
# ###################################################################################################

escape = (t)->
  t = t.replace /\#/g, 'H' # Hash
  t = t.replace /\?/g, 'O' # Option
  t = t.replace /\*/g, 'S' # Star
  t = t.replace /\+/g, 'P' # Plus
  t = t.replace /\=/g, 'E' # Equal
  t = t.replace /[^_a-z0-9\s]/ig, 'X'
  t = t.replace /\s/g, '_'

class @Gram_rule
  uid             : 0
  ret_hash_key    : ''
  ret_hash_key_idx: 0
  hash_to_pos     : {}
  
  _first_token_hash_key : ''
  can_only_new_call: false
  can_recursive   : false
  
  token_connector : null
  mx_list         : []
  strict_list     : []
  
  origin_tc       : ''
  origin_mx       : ''
  origin_strict   : ''
  
  constructor : ()->
    @hash_to_pos= {}
    
    @sequence   = []
    @mx_list    = []
    @strict_list= []
  
  name_get : ()->
    "#{escape @origin_tc}_#{escape @origin_mx}_#{escape @origin_strict}_u#{@uid}"
  
  descr_get : ()->
    aux_mx = ""
    aux_mx = ".mx(#{JSON.stringify @origin_mx})" if @origin_mx
    aux_strict = ""
    aux_strict = ".strict(#{JSON.stringify @origin_strict})" if @origin_strict
    ret = "rule(#{JSON.stringify @ret_hash_key}, #{JSON.stringify @origin_tc})"
    ret = "#{ret.ljust 50}#{aux_mx}"
    ret = "#{ret.ljust 100}#{aux_strict}"
    ret.trim()
  
  # ###################################################################################################
  #    mx
  # ###################################################################################################
  mx : (str)->
    @origin_mx = str
    pos_list= str.split /\s+/g
    @mx_list= []
    for pos in pos_list
      continue if !pos
      [key, rest...] = pos.split '='
      value = rest.join '='
      if !value
        @mx_list.push {
          autoassign: true
          key
          value     : null
        }
        continue
      @mx_list.push {
        autoassign: false
        key
        value     : strict_parser.parse value
      }
    @
  
  # ###################################################################################################
  #    strict
  # ###################################################################################################
  strict : (str)->
    @origin_strict = str
    pos_list = str.split /\s+/g
    @strict_list = []
    for pos in pos_list
      continue if !pos
      @strict_list.push rule = strict_parser.parse pos
      # verify
      strict_parser.translate rule.ast, @
    
    @
  

# ###################################################################################################
#    Gram_scope
# ###################################################################################################

class @Gram_scope
  initial_rule_list   : []
  group_rule_list     : []
  extra_hash_key_list : []
  hash_key_list       : []
  expected_token      : 'stmt'
  
  constructor : ()->
    @initial_rule_list  = []
    @extra_hash_key_list= []
    @hash_key_list      = []
  
  rule : (_ret, str_list)->
    @initial_rule_list.push ret = new module.Gram_rule
    ret.uid = @initial_rule_list.length
    ret.ret_hash_key = _ret
    ret.origin_tc = str_list
    ret.token_connector = token_connector_parser.parse str_list
    pos = 0
    walk = (ast)->
      switch ast.mx_hash.ult
        when "const"
          'just skip'
        when "ref"
          name = ast.value_array[0].value.substr 1
          if pos == 0
            ret._first_token_hash_key = name
          ret.hash_to_pos[name] ?= []
          ret.hash_to_pos[name].push pos++
        else
          for v in ast.value_array
            walk v
      return
    walk ret.token_connector.ast
    
    
    ret
  
  compile : (opt={})->
    opt.gram_module ?= 'gram3'
    if opt.expected_token # old API
      @expected_token = opt.expected_token
    # prepare
    # _hash_key_list_init
    @hash_key_list.clear()
    @hash_key_list.push '_' # special position for string constants
    @hash_key_list.uappend @extra_hash_key_list
    
    for rule in @initial_rule_list
      rule.can_recursive = false
      rule.can_only_new_call = false
      @hash_key_list.upush rule.ret_hash_key
      rule.ret_hash_key_idx = @hash_key_list.idx rule.ret_hash_key
      for k,_v of rule.hash_to_pos
        @hash_key_list.upush k
    
    # can_recursive
    hk_call_hash = {}
    for rule in @initial_rule_list
      hk_call_hash[rule.ret_hash_key] ?= []
      continue if !rule._first_token_hash_key
      hk_call_hash[rule.ret_hash_key].upush rule._first_token_hash_key
    
    # замыкание
    found = true
    while found
      found = false
      for k,list of hk_call_hash
        for v in list
          new_k_list = hk_call_hash[v]
          continue if !new_k_list?
          for new_k in new_k_list
            continue if list.has new_k
            list.push new_k
            found = true
    
    recursive_token_hash = {}
    
    for rule in @initial_rule_list
      continue if !possible_call_list = hk_call_hash[rule._first_token_hash_key]
      rule.can_recursive = possible_call_list.has rule.ret_hash_key
      if rule.can_recursive
        recursive_token_hash[rule.ret_hash_key] = true
    
    for rule in @initial_rule_list
      rule.can_only_new_call = recursive_token_hash[rule.ret_hash_key]?
    
    # group rules
    @group_rule_list = []
    for hash_key in @hash_key_list
      @group_rule_list.push {
        hash_key
        hash_key_idx : @hash_key_list.idx hash_key
        list : []
      }
    
    for rule in @initial_rule_list
      @group_rule_list[rule.ret_hash_key_idx].list.push rule
    
    # 
    rule_translator.translate @, opt
  
  