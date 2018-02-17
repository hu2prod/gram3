# this is stub, copypasted from gram2. Will be replaced

require 'fy/lib/codegen'
# ###################################################################################################
#    trans
# ###################################################################################################

{
  Translator
  bin_op_translator_framework
  bin_op_translator_holder
  un_op_translator_framework
  un_op_translator_holder
} = require './translator'

trans = new Translator
trans.trans_skip = {}
trans.trans_token = {}

deep = (ctx, node)->
  list = []
  # if node.mx_hash.deep?
  #   node.mx_hash.deep = '0' if node.mx_hash.deep == false # special case for deep=0
  #   value_array = (node.value_array[pos] for pos in node.mx_hash.deep.split ',')
  # else
  #   value_array = node.value_array
  
  
  value_array = node.value_array
  for v,k in value_array
    list.push ctx.translate v
  list
# ###################################################################################################
do ()->
  holder = new bin_op_translator_holder
  for v in bin_op_list = "+ - * / && ||".split ' '
    holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"
  
  # SPECIAL
  holder.op_list["&"]  = new bin_op_translator_framework "($1&&$2)"
  holder.op_list["|"]  = new bin_op_translator_framework "($1||$2)"
  holder.op_list["<>"]  = new bin_op_translator_framework "($1!=$2)"

  for v in bin_op_list = "== != < <= > >=".split ' '
    holder.op_list[v]  = new bin_op_translator_framework "($1$op$2)"
  trans.translator_hash['bin_op'] = holder

do ()->
  holder = new un_op_translator_holder
  holder.mode_pre()
  for v in un_op_list = "+ - !".split ' '
    holder.op_list[v]  = new un_op_translator_framework "$op$1"

  trans.translator_hash['pre_op'] = holder
# ###################################################################################################


trans.translator_hash['deep']   = translate:(ctx, node)->
  list = deep ctx, node
  list.join('')

trans.translator_hash['bra']   = translate:(ctx, node)->
  val = ctx.translate node.value_array[1]
  "(#{val})"

trans.translator_hash['value']  = translate:(ctx, node)->node.value_array[0].value
trans.translator_hash['wrap_string']  = translate:(ctx, node)->JSON.stringify node.value_array[0].value

trans.translator_hash['dollar_id'] = translate:(ctx, node)->
  idx = (node.value_array[0].value.substr 1)-1
  
  max_idx = 0
  for k,v of ctx.rule.hash_to_pos
    max_idx = Math.max max_idx, v...
  
  max_idx++
  
  if idx < 0 or idx >= max_idx
    throw new Error "strict_rule access out of bounds [0, #{max_idx}] idx=#{idx} (note real value are +1)"
  node.mx_hash.idx = idx
  ctx.id_touch_list.upush idx
  "arg_list[#{idx}]"

trans.translator_hash['hash_id'] = translate:(ctx, node)->
  name = node.value_array[0].value.substr 1
  if !idx_list = ctx.rule.hash_to_pos[name]
    throw new Error "unknown hash_key '#{name}' allowed key list #{JSON.stringify Object.keys(ctx.rule.hash_to_pos)}"
  node.mx_hash.idx = idx = idx_list[0]
  ctx.id_touch_list.upush idx
  "arg_list[#{idx}]"

trans.translator_hash['access_rvalue'] = translate:(ctx, node)->
  code = ctx.translate node.value_array[0]
  "#{code}.value"

trans.translator_hash['hash_array_access'] = translate:(ctx, node)->
  [id_node, _s, idx_node] = node.value_array
  name = id_node.value.substr 1
  if !idx_list = ctx.rule.hash_to_pos[name]
    throw new Error "unknown hash_key '#{name}' allowed key list #{JSON.stringify Object.keys(ctx.rule.hash_to_pos)}"
  
  idx = idx_node.value-1
  if idx < 0 or idx >= idx_list.length
    throw new Error "hash_array_access out of bounds [0, #{idx_list.length}] idx=#{idx} (note real value are +1)"
  node.mx_hash.idx = idx = idx_list[idx]
  ctx.id_touch_list.upush idx
  "arg_list[#{idx}]"

trans.translator_hash['slice_access'] = translate:(ctx, node)->
  [rvalue_node, _s, start_node, _s, end_node] = node.value_array
  rvalue = ctx.translate rvalue_node
  start  = +start_node.value
  end    = +end_node.value
  if end < start
    throw new Error "end < start at #{node.value}"
  
  "#{rvalue}.value.substr(#{start},#{end-start+1})"

trans.translator_hash['field_access'] = translate:(ctx, node)->
  [root_node, _s, field_node] = node.value_array
  root = ctx.translate root_node
  field = field_node.value
  "#{root}.mx_hash.#{field}"

# ###################################################################################################
#    interface with future autogeenrated
# ###################################################################################################
{parse} = require './strict_gen'
@parse = (str)->
  ast = parse str
  
  if ast.length == 0
    throw new Error "Parsing error. No proper combination found"
  if ast.length != 1
    ### !pragma coverage-skip-block ###
    throw new Error "Parsing error. More than one proper combination found #{ast.length}"
  
  {
    ast : ast[0]
  }

# TEMP
# for verify purposes
@translate = (ast, rule)->
  trans.rule = rule
  trans.id_touch_list = []
  trans.go ast

@ast_eval = (ast, rule, node_list)->
  trans.rule = rule
  trans.id_touch_list = []
  code = trans.go ast
  fn = eval """
    __ret = (function(arg_list, mx_hash_stub){
      return #{code};
    })
    """
  fn node_list, {}