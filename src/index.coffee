g       = (require './rule')
@Gram               = g.Gram_scope
@Gram_scope         = g.Gram_scope

g       = (require './node')
@Node               = g.Node

g       = (require './tokenizer')
@Token_parser       = g.Token_parser
@Tokenizer          = g.Tokenizer

g       = (require './translator')
@bin_op_translator_framework= g.bin_op_translator_framework
@bin_op_translator_holder   = g.bin_op_translator_holder
@un_op_translator_framework = g.un_op_translator_framework
@un_op_translator_holder    = g.un_op_translator_holder
@Translator                 = g.Translator

@gram_escape = (t)->JSON.stringify t