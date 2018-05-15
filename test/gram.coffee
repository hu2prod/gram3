assert = require 'assert'
util = require 'fy/test_util'

{
  Gram_scope
} = require '../src/rule'
{
  Tokenizer
  Token_parser
} = require '../src/tokenizer'
_iced = require 'iced-coffee-script'

t = new Tokenizer
t.parser_list.push (new Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
t.parser_list.push (new Token_parser 'op', /^!/i)
t.parser_list.push (new Token_parser 'bin_op', /^[+*]/i)

describe 'gram section', ()->
  full_test = (base_opt)->
    it "simple pass compiles", ()->
      gs = new Gram_scope
      gs.rule 't', 'hello'
      gs.compile(base_opt)
      return
    
    it "simple pass compiles", ()->
      gs = new Gram_scope
      gs.rule 't', 'hello'
      code = gs.compile(base_opt)
      _iced.compile code
      return
    
    it "simple pass evaluates", ()->
      gs = new Gram_scope
      gs.rule 't', 'hello'
      code = gs.compile obj_set clone(base_opt),
        gram_module : '../src/index'
      compiled = _iced.compile code
      eval compiled
      return
    
    it "simple pass runs", ()->
      gs = new Gram_scope
      gs.rule 'stmt', 'hello'
      code = gs.compile obj_set clone(base_opt),
        gram_module : '../src/index'
      
      compiled = _iced.compile code
      
      code = """
        __ret = {};
        fn = function() {
        #{compiled}
        };
        fn.call(__ret);
        __ret
        """
      
      mod = eval code
      prsr = new mod.Parser
      tok_list = t.go 'hello'
      
      res_list = prsr.go tok_list
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 1
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[0].value, 'hello'
      
      return
    
    it "simple pass runs expected_token", ()->
      gs = new Gram_scope
      gs.rule 't', 'hello'
      code = gs.compile obj_set clone(base_opt),
        gram_module : '../src/index'
        expected_token : 't'
      
      compiled = _iced.compile code
      
      code = """
        __ret = {};
        fn = function() {
        #{compiled}
        };
        fn.call(__ret);
        __ret
        """
      
      mod = eval code
      prsr = new mod.Parser
      tok_list = t.go 'hello'
      
      res_list = prsr.go tok_list
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 't'
      assert.equal res_list[0].value_array.length, 1
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[0].value, 'hello'
      
      return
    # ###################################################################################################
    #    for heavier tests
    # ###################################################################################################
    gs_prsr = (cb)->
      gs = new Gram_scope
      cb gs
      code = gs.compile obj_set clone(base_opt),
        gram_module : '../src/index'
      
      compiled = _iced.compile code
      
      code = """
        __ret = {};
        fn = function() {
        #{compiled}
        };
        fn.call(__ret);
        __ret
        """
      
      mod = eval code
      prsr = new mod.Parser
      (str)->
        tok_list = t.go str
        
        res_list = prsr.go tok_list
    
    gs_run = (str, cb)->
      gs = new Gram_scope
      cb gs
      code = gs.compile obj_set clone(base_opt),
        gram_module : '../src/index'
      
      compiled = _iced.compile code
      
      code = """
        __ret = {};
        fn = function() {
        #{compiled}
        };
        fn.call(__ret);
        __ret
        """
      
      mod = eval code
      prsr = new mod.Parser
      tok_list = t.go str
      
      res_list = prsr.go tok_list
    
    it "1 token runs", ()->
      res_list = gs_run 'hello', (gs)->
        gs.rule 'stmt', 'hello'
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 1
      assert.equal res_list[0].value_view, 'hello'
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[0].value, 'hello'
      
      return
    
    it "2 token runs", ()->
      res_list = gs_run 'hello world', (gs)->
        gs.rule 'stmt', 'hello world'
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 2
      assert.equal res_list[0].value_view, 'hello world'
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[0].value, 'hello'
      assert.equal res_list[0].value_array[1].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[1].value, 'world'
      
      return
    
    it "proxy rule runs", ()->
      res_list = gs_run 'hello', (gs)->
        gs.rule 'proxy', 'hello'
        gs.rule 'stmt', '#proxy'
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 1
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'proxy'
      assert.equal res_list[0].value_array[0].value_array.length, 1
      assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'id'
      assert.equal res_list[0].value_array[0].value_array[0].value, 'hello'
      
      return
    
    it "can't find runs", ()->
      res_list = gs_run 'wtf', (gs)->
        gs.rule 'stmt', 'hello'
      
      assert.equal res_list.length, 0
      
      return
    
    it "multi match runs", ()->
      res_list = gs_run 'hello', (gs)->
        gs.rule('stmt', 'hello').mx('v=0')
        gs.rule('stmt', 'hello').mx('v=1')
      
      assert.equal res_list.length, 2
      assert.equal res_list[0].mx_hash.v, 0
      assert.equal res_list[1].mx_hash.v, 1
      
      return
    
    it "char match", ()->
      res_list = gs_run '!', (gs)->
        gs.rule 'stmt', '\'!\''
      
      assert.equal res_list.length, 1
      
      return
    
    it "or match 2", ()->
      res_list = gs_run 'a', (gs)->
        gs.rule 'stmt', 'a|b'
      
      assert.equal res_list.length, 1
      
      res_list = gs_run 'b', (gs)->
        gs.rule 'stmt', 'a|b'
      
      assert.equal res_list.length, 1
      
      return
    
    it "or match 3", ()->
      res_list = gs_run 'a', (gs)->
        gs.rule 'stmt', 'a|b|c'
      
      assert.equal res_list.length, 1
      
      res_list = gs_run 'b', (gs)->
        gs.rule 'stmt', 'a|b|c'
      
      assert.equal res_list.length, 1
      
      res_list = gs_run 'c', (gs)->
        gs.rule 'stmt', 'a|b|c'
      
      assert.equal res_list.length, 1
      
      return
    
    it "prefix or match 2", ()->
      res_list = gs_run 'p a', (gs)->
        gs.rule 'stmt', 'p a|b'
      
      assert.equal res_list.length, 1
      
      res_list = gs_run 'p b', (gs)->
        gs.rule 'stmt', 'p a|b'
      
      assert.equal res_list.length, 1
      return
    
    it "or match 2 non terminal", ()->
      res_list = gs_run 'a', (gs)->
        gs.rule 'proxy', 'b'
        gs.rule 'stmt', 'a|#proxy'
      
      assert.equal res_list.length, 1
      
      res_list = gs_run 'b', (gs)->
        gs.rule 'proxy', 'b'
        gs.rule 'stmt', 'a|#proxy'
      
      assert.equal res_list.length, 1
      
      return
    
    describe "mx", ()->
      it "mx_hash compiles properly", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=pass')
      
      it "mx_hash runs properly const string", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=pass')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'pass'
        
        return
      
      it "mx_hash 1", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=1')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 1
        
        return
      
      it "mx_hash $1", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=$1')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'hello'
        
        return
      
      it "mx_hash $1.hash_key", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=$1.hash_key')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'id'
        
        return
      
      it "mx_hash 1+1", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=1+1')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 2
        
        return
      
      it "mx_hash a+b", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('stmt', 'hello').mx('ult=a+b')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'ab'
        
        return
      
      it "mx_hash proxy access", ()->
        res_list = gs_run 'hello', (gs)->
          gs.rule('proxy', 'hello')
          gs.rule('stmt', '#proxy').mx('ult=#proxy.hash_key')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'proxy'
        
        return
      
      it "mx_hash proxy access 2 position hash", ()->
        res_list = gs_run 'a hello', (gs)->
          gs.rule('proxy', 'hello')
          gs.rule('stmt', 'a #proxy').mx('ult=#proxy.hash_key')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'proxy'
        
        return
      
      it "mx_hash proxy access 2 position dollar", ()->
        res_list = gs_run 'a hello', (gs)->
          gs.rule('proxy', 'hello')
          gs.rule('stmt', 'a #proxy').mx('ult=$2.hash_key')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].mx_hash.ult, 'proxy'
        
        return
    
    describe "recursive rules", ()->
      it "a+b as non recursive", ()->
        res_list = gs_run 'a+b', (gs)->
          gs.rule('stmt', '#id \\+ #id')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array.length, 3
        
        return
      
      it "a+b as non recursive + id rule", ()->
        res_list = gs_run 'a+b', (gs)->
          gs.rule('stmt', '#id')
          gs.rule('stmt', '#id \\+ #id')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array.length, 3
        
        return
      it "a+b as non recursive + deep id rule", ()->
        res_list = gs_run 'a+b', (gs)->
          gs.rule('proxy', '#id')
          gs.rule('stmt', '#proxy \\+ #proxy')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array.length, 3
        
        return
      
      it "a+b", ()->
        res_list = gs_run 'a+b', (gs)->
          gs.rule('stmt', '#id')
          gs.rule('stmt', '#stmt \\+ #stmt')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array.length, 3
        
        return
      
      it "a+b+c 2", ()->
        res_list = gs_run 'a+b+c', (gs)->
          gs.rule('stmt', '#id')
          gs.rule('stmt', '#stmt \\+ #stmt')
        
        assert.equal res_list.length, 2
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[1].mx_hash.hash_key, 'stmt'
        
        return
      
      it "a+b+c 1", ()->
        res_list = gs_run 'a+b+c', (gs)->
          gs.rule('stmt', '#id')
          gs.rule('stmt', '#stmt \\+ #stmt') .mx('pr=1'). strict('!$1.pr')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        
        return
      
      it "a+b+c priority", ()->
        res_list = gs_run 'a+b+c', (gs)->
          gs.rule('stmt', '#id')              .mx("priority=-9000")
          gs.rule('_bin_op', '\\+')           .mx('priority=6')
          gs.rule('stmt', '#stmt #_bin_op #stmt').mx("priority=#_bin_op.priority") .strict('#stmt[1].priority<=#_bin_op.priority #stmt[2].priority<#_bin_op.priority')
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        
        return
      hash = {
        "a"   : "a"
      }
      eval_list = """
        1
        !1
        '1'
        +'1'
        -1
        2+3
        2*3
        4/2
        2+2*2
        2*2+2
        2+2+2
        2+2-2
        2-2+2
        (1)
        (2+2)*2
        2*(2+2)
        2+2+2*2
        1+2+3*4+5
        2+2+2*2+2
        """.split /\n/g
      
      for v in eval_list
        hash[v] = eval v
        
      
      pair_list = [
        [1,2]
        [2,2]
        [3,2]
      ]
      map_op =
        "<>" : "!="
        "&"  : "&&"
        "|"  : "||"
      for op in "< <= > >= <> !=".split /\s/g
        for pair in pair_list
          [a, b] = pair
          ev_op = map_op[op] or op
          hash["#{a}#{op}#{b}"] = eval "#{a}#{ev_op}#{b}"
      
      for op in "& && | ||".split /\s/g
        for a in [0,1,2]
          for b in [0,1,2]
            ev_op = map_op[op] or op
            hash["#{a}#{op}#{b}"] = eval "#{a}#{ev_op}#{b}"
      
      for k,v of hash
        do (k, v)->
          it "mx value check #{k} => #{v}", ()->
            res_list = gs_run 'a', (gs)->
              gs.rule('stmt', '#id').mx("val=#{k}")
            
            assert.equal res_list.length, 1
            assert.equal res_list[0].mx_hash.hash_key, 'stmt'
            assert.equal res_list[0].mx_hash.val, v
      
      list = """
        1==1==1
        #id[0
        #id[0:
        #id[0:0
        #id[0 a
        #id[0: a
        #id[0:0 a
        (
        (a
        """.split /\n/g
      for op in "< <= > >= <> != + - * / .".split /\s/g
        list.push "a#{op}"
      for v in list
        do (v)->
          it 'mx value throws', ()->
            util.throws ()->
              gs_run 'a', (gs)->
                gs.rule('stmt', '#id').mx("val=#{v}")
      
    
    describe "strict", ()->
      list = """
        1
        a
        #id
        $1
        1==1
        #id.hash_key
        !0
        +1
        -1
        """.split /\n/g
      for v in list
        do (v)->
          it "trivial strict #{v}", ()->
            res_list = gs_run 'a', (gs)->
              gs.rule('stmt', '#id').strict(v)
            
            assert.equal res_list.length, 1
            assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      
    
    describe "quantificators", ()->
      describe "option", ()->
        it 'a?', ()->
          assert.throws ()->
            gs_run 'a', (gs)->
              gs.rule 'stmt', 'a?'
        
        it 'a b?', ()->
          res_list = gs_run 'a b', (gs)->
            gs.rule 'stmt', 'a b?'
          
          assert.equal res_list.length, 1
          
          res_list = gs_run 'a', (gs)->
            gs.rule 'stmt', 'a b?'
          
          assert.equal res_list.length, 1
        
        it 'a b? c', ()->
          res_list = gs_run 'a b c', (gs)->
            gs.rule 'stmt', 'a b? c'
          
          assert.equal res_list.length, 1
          
          res_list = gs_run 'a c', (gs)->
            gs.rule 'stmt', 'a b? c'
          
          assert.equal res_list.length, 1
        
        it 'a b? c?', ()->
          res_list = gs_run 'a b c', (gs)->
            gs.rule 'stmt', 'a b? c?'
          
          assert.equal res_list.length, 1
          
          res_list = gs_run 'a c', (gs)->
            gs.rule 'stmt', 'a b? c?'
          
          assert.equal res_list.length, 1
          
          res_list = gs_run 'a b', (gs)->
            gs.rule 'stmt', 'a b? c?'
          
          assert.equal res_list.length, 1
          
          res_list = gs_run 'a', (gs)->
            gs.rule 'stmt', 'a b? c?'
          
          assert.equal res_list.length, 1
        
      it "some star"
      it "some plus"
    
    describe "double recursive", ()->
      it 'a->b->a 2 pos opt', ()->
        fn = gs_prsr (gs)->
          gs.rule 'b', 'b #stmt?'
          gs.rule 'stmt', 'a #b?'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a b').length, 1
        assert.equal fn('a b a').length, 1
        assert.equal fn('a b a b').length, 1
        assert.equal fn('a b a b a').length, 1
        assert.equal fn('a b a b a b').length, 1
      
      it 'a->b->c->a 2 pos opt', ()->
        fn = gs_prsr (gs)->
          gs.rule 'c', 'c #stmt?'
          gs.rule 'b', 'b #c?'
          gs.rule 'stmt', 'a #b?'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a b').length, 1
        assert.equal fn('a b c a').length, 1
        assert.equal fn('a b c a b').length, 1
        assert.equal fn('a b c a b c').length, 1
        assert.equal fn('a b c a b c a').length, 1
        assert.equal fn('a b c a b c a b').length, 1
        assert.equal fn('a b c a b c a b c').length, 1
      
      it 'stmt + case', ()->
        fn = gs_prsr (gs)->
          gs.rule 'stmt', '#id'
          gs.rule 'stmt', '#stmt "+"'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a +').length, 1
        assert.equal fn('a + +').length, 1
      
      it 'stmt + proxy case', ()->
        fn = gs_prsr (gs)->
          gs.rule 'stmt', '#id'
          gs.rule 'proxy', '#stmt "+"'
          gs.rule 'stmt', '#proxy'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a +').length, 1
        assert.equal fn('a + +').length, 1
      
      it 'stmt lvalue a->b->a case', ()->
        fn = gs_prsr (gs)->
          gs.rule 'lvalue', 'a'
          gs.rule 'lvalue', '#stmt "+" #id'
          gs.rule 'stmt', '#lvalue'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a + b').length, 1
        assert.equal fn('a + b + c').length, 1
      
      it 'rvalue lvalue c->a->b->a case', ()->
        fn = gs_prsr (gs)->
          gs.rule 'lvalue', 'a'
          gs.rule 'lvalue', '#rvalue "+" #id'
          gs.rule 'rvalue', '#lvalue'
          gs.rule 'stmt', '#rvalue'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a + b').length, 1
        assert.equal fn('a + b + c').length, 1
      
      it 'rvalue lvalue c->a->b->a overreset case', ()->
        fn = gs_prsr (gs)->
          gs.rule 'lvalue', 'a'
          gs.rule 'lvalue', '#rvalue "+" #id'
          gs.rule 'rvalue', '#lvalue'
          gs.rule 'rvalue', '#lvalue wtf'
          gs.rule 'stmt', '#rvalue'
          gs.rule 'stmt', '#rvalue wtf'
        
        assert.equal fn('a').length, 1
        assert.equal fn('a + b').length, 1
        assert.equal fn('a + b + c').length, 1
      
    describe "one_const_opt case", ()->
      it 'a or b', ()->
        fn = gs_prsr (gs)->
          gs.rule 'stmt', 'a'
          gs.rule 'stmt', 'b'
        
        assert.equal fn('a').length, 1
        assert.equal fn('b').length, 1
      it 'a or b proxy', ()->
        fn = gs_prsr (gs)->
          gs.rule 'proxy', 'b'
          gs.rule 'stmt', 'a'
          gs.rule 'stmt', '#proxy'
        
        assert.equal fn('a').length, 1
        assert.equal fn('b').length, 1
      
    it "multiple token hypothesis"
    describe "extra", ()->
      it 'proper token clear on out of bounds read', ()->
        fn = gs_prsr (gs)->
          gs.rule 'proxy2', 'a' # deopt
          gs.rule 'proxy', '#proxy2 b'
          gs.rule 'proxy', '#proxy2'
          gs.rule 'stmt', '#proxy b'
        
        ret = fn('a b')
        
        assert.equal ret.length, 1
        assert.equal ret[0].value_view, "a b"
    
  describe 'no one_const_opt', ()->
    full_test one_const_opt:false
  
  describe 'one_const_opt', ()->
    full_test one_const_opt:true
  