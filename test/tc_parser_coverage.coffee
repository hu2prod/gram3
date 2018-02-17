assert = require 'assert'
util = require 'fy/test_util'
{parse} = require '../src/token_connector_gen_for_coverage'

describe 'tc parser coverage section', ()->
  list = """
  a
  #a
  'a'
  \\\\+
  a b
  a b c
  a|b
  a|b|c
  a|b c
  a|b c|d
  a?
  a+
  a*
  (a)
  ( a       )
  ( #a      )
  ( 'a'     )
  ( \\\\+   )
  ( a b     )
  ( a b c   )
  ( a|b     )
  ( a|b|c   )
  ( a|b c   )
  ( a|b c|d )
  ( a?      )
  ( a+      )
  ( a*      )
  """.split /\n/g
  for v in list
    do (v)->
      it "parses #{v}", ()->
        list = parse v
        assert.equal list.length, 1
  
  list = """
  |
  +
  *
  ?
  ,
  
  """.split /\n/g
  for v in list
    it "not parses #{v}", ()->
      util.throws ()->
        list = parse v
        assert.equal list.length, 1
  