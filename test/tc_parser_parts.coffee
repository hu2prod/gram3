assert = require 'assert'
util = require 'fy/test_util'
fs = require 'fs'

{
  Gram_scope
} = require '../src/rule'
{
  Tokenizer
  Token_parser
} = require '../src/tokenizer'
_iced = require 'iced-coffee-script'


# ###################################################################################################
#    tokenizer
# ###################################################################################################

tokenizer = new Tokenizer
tokenizer.parser_list.push (new Token_parser 'hash_id', /^\#[_a-z0-9]+/i )
tokenizer.parser_list.push (new Token_parser 'option',  /^\?/ )
tokenizer.parser_list.push (new Token_parser 'plus',    /^\+/ )
tokenizer.parser_list.push (new Token_parser 'star',    /^\*/ )
tokenizer.parser_list.push (new Token_parser 'bra_op',  /^\(/ )
tokenizer.parser_list.push (new Token_parser 'bra_cl',  /^\)/ )
tokenizer.parser_list.push (new Token_parser 'or',      /^\|/ )
tokenizer.parser_list.push (new Token_parser 'q_token', /^\'[^']*\'/ )
tokenizer.parser_list.push (new Token_parser 'token',   /^[_a-z0-9]+/ )
tokenizer.parser_list.push (new Token_parser 'escape_token', /^\\\S/ )

# ###################################################################################################
#    gram
# ###################################################################################################
base_priority = -9000
gs = new Gram_scope
q = (a, b)->gs.rule a,b

q('atom',  '#q_token')              .mx('ult=const')
q('atom',  '#token')                .mx('ult=const')
q('atom',  '#escape_token')         .mx('ult=const')
q('atom',  '#hash_id')              .mx('ult=ref')

q('expr',  '#atom')                 .mx('ult=pass')
q('expr',  '#atom #or #expr')       .mx('ult=or')

q('stmt',  '#atom #option')         .mx('ult=option')
q('stmt',  '#atom #plus')           .mx('ult=plus')
q('stmt',  '#atom #star')           .mx('ult=star')
q('atom',  '#bra_op #stmt #bra_cl') .mx('ult=bra')

q('stmt',  '#expr')                 .mx('ult=pass')
q('stmt',  '#expr #stmt')           .mx('ult=join')

code = gs.compile
  gram_module : '../src/index'
compiled = _iced.compile code

# no fs.writeFileSync + require
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


describe 'tc parser parts section', ()->
  parse = (str)->
    tok_list = tokenizer.go str
    res_list = prsr.go tok_list
  
  it "token a", ()->
    res_list = parse 'a'
    
    assert.equal res_list.length, 1
    assert.equal res_list[0].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
  
  it "q_token a", ()->
    res_list = parse "'a'"
    
    assert.equal res_list.length, 1
    assert.equal res_list[0].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'q_token'
  
  it "escape_token \\+", ()->
    res_list = parse "\\+"
    
    assert.equal res_list.length, 1
    assert.equal res_list[0].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'escape_token'
  
  it "hash_id #a", ()->
    res_list = parse "#a"
    
    assert.equal res_list.length, 1
    assert.equal res_list[0].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'hash_id'
  
  describe "or", ()->
    describe "same mix", ()->
      it "a|b", ()->
        res_list = parse "a|b"
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array.length, 3
        assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
        assert.equal res_list[0].value_array[0].value_array[2].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].value_array[0].mx_hash.hash_key, 'token'
      
      it "\\+|\\*", ()->
        res_list = parse "\\+|\\*"
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array.length, 3
        assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'escape_token'
        assert.equal res_list[0].value_array[0].value_array[2].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].value_array[0].mx_hash.hash_key, 'escape_token'
      
      it "'a'|'b'", ()->
        res_list = parse "'a'|'b'"
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array.length, 3
        assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'q_token'
        assert.equal res_list[0].value_array[0].value_array[2].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].value_array[0].mx_hash.hash_key, 'q_token'
      
      it "a|b|c", ()->
        res_list = parse "a|b|c"
        
        assert.equal res_list.length, 1
    
    it "diff mix", ()->
      it "a|\\+", ()->
        res_list = parse "a|\\+"
        
        assert.equal res_list.length, 1
        assert.equal res_list[0].mx_hash.hash_key, 'stmt'
        assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array.length, 3
        assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
        assert.equal res_list[0].value_array[0].value_array[2].mx_hash.hash_key, 'expr'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].mx_hash.hash_key, 'atom'
        assert.equal res_list[0].value_array[0].value_array[2].value_array[0].value_array[0].mx_hash.hash_key, 'escape_token'
  
  describe "quantificators", ()->
    it "option", ()->
      res_list = parse "a?"
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 2
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'atom'
      assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
    
    it "plus", ()->
      res_list = parse "a+"
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 2
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'atom'
      assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
    
    it "star", ()->
      res_list = parse "a*"
      
      assert.equal res_list.length, 1
      assert.equal res_list[0].mx_hash.hash_key, 'stmt'
      assert.equal res_list[0].value_array.length, 2
      assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'atom'
      assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
    
  it "bracket", ()->
    res_list = parse "(a)"
    
    assert.equal res_list.length, 1
    assert.equal res_list[0].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array.length, 3
    assert.equal res_list[0].value_array[0].value_array[0].value_array[1].mx_hash.hash_key, 'stmt'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[1].value_array[0].mx_hash.hash_key, 'expr'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[1].value_array[0].value_array[0].mx_hash.hash_key, 'atom'
    assert.equal res_list[0].value_array[0].value_array[0].value_array[1].value_array[0].value_array[0].value_array[0].mx_hash.hash_key, 'token'
