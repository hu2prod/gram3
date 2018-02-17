assert = require 'assert'
util = require 'fy/test_util'
{parse} = require '../src/strict_gen_for_coverage'

describe 'strict parser coverage section', ()->
  list = """
    a
    #a
    $1
    'a'
    \"a\"
    1
    (a)
    ( a       )
    ( #a      )
    ( 'a'     )
    #a==#b
    #a+#b
    #a-#b
    #a*#b
    #a/#b
    #a==#b
    #a!=#b
    #a<>#b
    #a<#b
    #a<=#b
    #a>#b
    #a>=#b
    #a&#b
    #a&&#b
    #a|#b
    #a||#b
    #a.b
    !#a
    +#a
    -#a
    #a[0]
    #a[0:0]
    #a+#b+#c
    """.split /\n/g
  for v in list
    do (v)->
      it "parses #{v}", ()->
        loc_list = parse v
        assert.equal loc_list.length, 1
  
  list = """
    ?
    ,
    """.split /\n/g
  for v in list
    do (v)->
      it "not tokenizes #{v}", ()->
        util.throws ()->
          parse v
  
  list = """
    |
    !
    +
    *
    a.b
    #a[#b]
    #a[0
    #a[0:
    #a[0:0
    (#a
    #a[0 a
    #a[0: a
    #a[0:0 a
    (#a a
    #a==
    #a+
    #a-
    #a*
    #a/
    #a==
    #a!=
    #a<>
    #a<
    #a<=
    #a>
    #a>=
    #a&
    #a&&
    #a|
    #a||
    #a.
    
    """.split /\n/g
  for v in list
    do (v)->
      it "not parses #{v}", ()->
        loc_list = parse v
        assert.equal loc_list.length, 0
  