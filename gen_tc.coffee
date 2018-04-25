#!/usr/bin/env iced
### !pragma coverage-skip-block ###
require 'fy'
fs = require 'fs'

{
  Gram_scope
} = require './src/rule'

tokenizer_code = fs.readFileSync './tok_tc.coffee.template'
# ###################################################################################################
#    gram
# ###################################################################################################
gs = new Gram_scope
q = (a, b)->gs.rule a,b

q('atom',  '#q_token')              .mx('ult=const')
q('atom',  '#dq_token')             .mx('ult=const')
q('atom',  '#token')                .mx('ult=const')
q('atom',  '#escape_token')         .mx('ult=const')
q('atom',  '#hash_id')              .mx('ult=ref')

q('expr',  '#atom')                 .mx('ult=pass')
q('expr',  '#atom #or #expr')       .mx('ult=or')

q('expr',  '#atom #option')         .mx('ult=option')
q('expr',  '#atom #plus')           .mx('ult=plus')
q('expr',  '#atom #star')           .mx('ult=star')
q('atom',  '#bra_op #stmt #bra_cl') .mx('ult=bra')

q('stmt',  '#expr')                 .mx('ult=pass')
q('stmt',  '#expr #stmt')           .mx('ult=join')

gram_code = gs.compile
  gram_module : './node'

code = """
# WARNING!!! AUTOGENERATED with gen_tc.coffee
module = @
{
  Tokenizer
  Token_parser
} = require './tokenizer'
# ###################################################################################################
#    tokenizer
# ###################################################################################################
#{tokenizer_code}

# ###################################################################################################
#    gram
# ###################################################################################################

#{gram_code}

# ###################################################################################################
parser = new module.Parser

@parse = (str)->
  tok_list = tokenizer.go str
  res_list = parser.go tok_list

# debug
@tokenizer = tokenizer
@parser = parser

"""

fs.writeFileSync './src/token_connector_gen.coffee', code
fs.writeFileSync './src/token_connector_gen_for_coverage.coffee', code