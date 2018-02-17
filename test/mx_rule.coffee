assert = require 'assert'
util = require 'fy/test_util'

{
  Gram_rule
} = require '../src/rule'
{Node} = require '../src/node'
strict_parser = require '../src/strict_parser'

mx_rule_fn = (rule, token_list)->
  ret = {}
  for mx in rule.mx_list
    continue if mx.autoassign
    ret[mx.key] = strict_parser.ast_eval mx.value.ast, rule, token_list
  ret

describe 'mx_rule section', ()->
  list = """
    
    r
    r=1
    r=#a
    r=#a[1]
    r=#a[1][1:2]
    r=$1==1
  """.split /\n/g
  for v in list
    do (v)->
      it "'#{v}' works with 1", ()->
        rule = new Gram_rule
        # rule.sequence = ["#a"]
        rule.hash_to_pos =
          a : [0]
        rule.mx v
        
        node_a = new Node '1'
        node_a.mx_hash.mx = 1
        
        mx_rule_fn rule, [node_a]
        
        return
  list = """
    r=1
    r=#a
    r=#a[1]
    r=#a[1][1:2]
    r=$1==1
    r=$1==$2
    r=$1+$2
    r=$1|$2
    a=1 b=2
    a=1  b=2
    a=1 b=2 
     a=1 b=2 
  """.split /\n/g
  for v in list
    do (v)->
      it "'#{v}' works with 2", ()->
        rule = new Gram_rule
        # rule.sequence = ["#a", "#b"]
        rule.hash_to_pos =
          a : [0]
          b : [1]
        rule.mx v
        
        node_a = new Node '1'
        node_a.mx_hash.mx = 1
        
        node_b = new Node '2'
        node_b.mx_hash.mx = 1
        
        mx_rule_fn rule, [node_a, node_b]
        return
  
  ###
  # autoassign is not implemented
  list = """
    r
  """.split /\n/g
  for v in list
    do (v)->
      it "'#{v}' fail with 2", ()->
        rule = new Gram_rule
        rule.sequence = ["#a", "#b"]
        rule.hash_to_pos =
          a : [0]
          b : [1]
        util.throws ()->
          rule.mx v
        
        return
  ###
  
  hash_kv =
    # "mx"        : {mx:1}
    "mx=2"      : {mx:2}
    "mx mx=2"   : {mx:2}
    # "mx=2 mx"   : {mx:1}
    "a=2"       : {a:2}
    "a=$1.mx"   : {a:1}
    "a=$1.mx+1" : {a:2}
    "a=$1"      : {a:'1'}
  for k,v of hash_kv
    do (k,v)->
      it "'#{k}' works properly with 1", ()->
        rule = new Gram_rule
        # rule.sequence = ["#a"]
        rule.hash_to_pos =
          a : [0]
        rule.mx k
        
        node_a = new Node '1'
        node_a.mx_hash.mx = 1
        
        res = mx_rule_fn rule, [node_a]
        util.json_eq res, v
        return
  
