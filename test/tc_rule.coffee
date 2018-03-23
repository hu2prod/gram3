assert = require 'assert'
util = require 'fy/test_util'

{
  Gram_scope
} = require '../src/rule'
gs = new Gram_scope


describe 'tc_rule section', ()->
  list = """
    a
    ab
    0
    01
    #a
    #ab
    a b
    \\?
    \\+
    \\*
    'a'
    \"a\"
  """.split /\n/g
  for v in list
    do (v)->
      it "'#{v}' compiles", ()->
        rule = gs.rule 'ret', v
        return
  
  list = """
    
    \
    ?
    +
    *
    '
    \"
  """.split /\n/g
  for v in list
    do (v)->
      it "'#{v}' not compiles", ()->
        util.throws ()->
          rule = gs.rule 'ret', v
        return
  