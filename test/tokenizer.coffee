assert = require 'assert'
util = require 'fy/test_util'

g = require '../src/index.coffee'

describe 'tokenizer section', ()->
  # ###################################################################################################
  #    Node
  # ###################################################################################################
  it 'Node clone + cmp', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    n2 = n1.clone()
    # util.json_eq n1, n2
    util.json_eq n1.mx_hash, n2.mx_hash
    assert.equal n1.value, n2.value
    util.json_eq n1.value_array, n2.value_array
    assert n1.cmp n2
    return
   
  it 'Node cmp missing mx_hash', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    
    n2 = new g.Node
    # n2.mx_hash.a = '123' # missing mx_hash
    n2.value = '123'
    n2.value_array = ['123']
    
    assert !n1.cmp n2
   
  it 'Node cmp wrong value', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    
    n2 = new g.Node
    n2.mx_hash.a = '123' # missing mx_hash
    n2.value = '1234'
    n2.value_array = ['123']
    
    assert !n1.cmp n2
  
  it 'Node str_uid', ()->
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = ['123']
    assert.equal n1.str_uid(), '123 {"a":"123"}'
    return
  
  it 'Node name', ()->
    in_n1 = new g.Node
    in_n1.mx_hash.hash_key = 'k1'
    in_n2 = new g.Node
    in_n2.mx_hash.hash_key = 'k2'
    
    n1 = new g.Node
    n1.mx_hash.a = '123'
    n1.value = '123'
    n1.value_array = [
      in_n1
      in_n2
    ]
    ret = n1.name('k1')
    assert.equal ret.length, 1
    assert.equal ret[0], in_n1
    return
  
  # ###################################################################################################
  #    Tokenizer
  # ###################################################################################################
  it 'regex id', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    assert.equal list[0].length, 1
    return
  
  it 'regex id space', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
    list = t.go 'a  '
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    assert.equal list[0][0].mx_hash.tail_space, '2'
    assert.equal list[0].length, 1
    return
  
  describe 'atparse', ()->
    it 'regex id atparse pass', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch'
        ret_proxy.push [n]
        return
      )
      list = t.go 'a'
      assert.equal list[0][0].mx_hash.hash_key, 'id_patch'
      return
    
    it 'regex id atparse noadd', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        return
      )
      list = t.go 'a'
      assert.equal list.length, 0
      return
    
    it 'regex id atparse 2 noadd', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        return
      )
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        return
      )
      list = t.go 'a'
      assert.equal list.length, 0
      return
  
    it 'single parse with atparse_unique_check but no atparse', ()->
      t = new g.Tokenizer
      t.atparse_unique_check = true
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
      t.go 'abc'
      return
  
    it 'multiple parse with atparse_unique_check but no atparse', ()->
      t = new g.Tokenizer
      t.atparse_unique_check = true
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
      t.parser_list.push (new g.Token_parser 'id2', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
      util.throws ()->
        t.go 'abc'
      return
    
    it 'regex id atparse pass 2 united_length=1', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch'
        ret_proxy.push [n]
        return
      )
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch2'
        ret_proxy.push [n]
        return
      )
      list = t.go 'a'
      assert.equal list[0][0].mx_hash.hash_key, 'id_patch'
      assert.equal list[0][1].mx_hash.hash_key, 'id_patch2'
      return
    
    it 'regex id atparse pass 2 no united_length real=1,0', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch'
        ret_proxy.push [n]
        return
      )
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        return
      )
      util.throws ()->
        t.go 'a'
      return
    
    it 'regex id atparse pass 2 united_length=2', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch'
        ret_proxy.push [n]
        ret_proxy.push [n]
        return
      )
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        n = new g.Node
        n.mx_hash.hash_key = 'id_patch2'
        ret_proxy.push [n]
        ret_proxy.push [n]
        return
      )
      util.throws ()->
        t.go 'a'
      return
    
    it 'regex id atparse drop token_sequence_hypothesis_list', ()->
      t = new g.Tokenizer
      t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i, (_this, ret_proxy, v)->
        _this.token_sequence_hypothesis_list.clear()
        return
      )
      util.throws ()->
        t.go 'a'
      return
  
  it 'regex id repeat letters', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
    list = t.go 'aa'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id with unused regex', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'if', /^if/)
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id fll', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'if', /^if/)
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex id/num discard_fll', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-zA-Z0-9]+/).fll_discard('0123456789')
    t.parser_list.push (new g.Token_parser 'num', /^[0-9]+/)
    list = t.go '123'
    assert.equal list[0][0].mx_hash.hash_key, 'num'
    return
  
  it 'multiple call regex id', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    list = t.go 'a'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'regex identifier bin_op', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'identifier', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.parser_list.push  new g.Token_parser 'bin_op',   /^[\+\-\*\/]/
    token_list = t.go "a+b"
    assert.equal token_list[0][0].mx_hash.hash_key, 'identifier'
    assert.equal token_list[1][0].mx_hash.hash_key, 'bin_op'
    assert.equal token_list[2][0].mx_hash.hash_key, 'identifier'
    return
  
  it 'fll reject test', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'a', /^a/).fll_add('a')
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    list = t.go 'ab'
    assert.equal list[0][0].mx_hash.hash_key, 'id'
    return
  
  it 'can\'t parse no rules', ()->
    t = new g.Tokenizer
    util.throws ()->
      t.go '123'
    return
  
  it 'can\'t parse no proper rule', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    util.throws ()->
      t.go '123'
    return
  
  it 'multiple parse', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    t.parser_list.push (new g.Token_parser 'id2', /^[_a-z][_a-z0-9]*/i).fll_add('qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM_')
    token_list = t.go 'abc'
    assert.equal token_list[0][0].mx_hash.hash_key, 'id'
    assert.equal token_list[0][1].mx_hash.hash_key, 'id2'
    return
  
  it 'has pos and line', ()->
    t = new g.Tokenizer
    t.parser_list.push (new g.Token_parser 'id', /^[_a-z][_a-z0-9]*/i)
    t.parser_list.push (new g.Token_parser 'space', /^\s+/i)
    list = t.go """
      a b
      c
      """
    assert.equal list[0][0].pos,  1
    assert.equal list[0][0].line, 1
    
    assert.equal list[1][0].pos,  3
    assert.equal list[1][0].line, 1
    
    # \n stays on prev line
    assert.equal list[2][0].pos,  4
    assert.equal list[2][0].line, 1
    
    assert.equal list[3][0].pos,  1
    assert.equal list[3][0].line, 2
  
  it 'eol', ()->
    t = new g.Tokenizer
    
    t.parser_list.push (new g.Token_parser 'Xdent', /^\n/, (_this, ret_value, q)->
      _this.text = _this.text.substr 1 # \n
      node = new g.Node
      node.mx_hash.hash_key = 'eol'
      ret_value.push [node]
    )
    list = t.go '\n'
    assert.equal list[0].length, 1
    assert.equal list[0][0].mx_hash.hash_key, 'eol'
    return
  