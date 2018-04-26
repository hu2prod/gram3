# WARNING!!! AUTOGENERATED with gen_tc.coffee
module = @
{
  Tokenizer
  Token_parser
} = require './tokenizer'
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
tokenizer.parser_list.push (new Token_parser 'dq_token',/^\"[^"]*\"/ )
tokenizer.parser_list.push (new Token_parser 'token',   /^[_a-z0-9]+/ )
tokenizer.parser_list.push (new Token_parser 'escape_token', /^\\\S/ )

# ###################################################################################################
#    gram
# ###################################################################################################

require 'fy'
drop_stub = []
for i in [0 ... 15]
  drop_stub.push 0
cache_stub = new Array 56

hash_key_list = [
  "_",
  "atom",
  "q_token",
  "dq_token",
  "token",
  "escape_token",
  "hash_id",
  "expr",
  "or",
  "option",
  "plus",
  "star",
  "bra_op",
  "stmt",
  "bra_cl"
]

class @Parser
  length: 0
  cache : []
  drop  : []
  Node  : null
  proxy : null
  
  go : (token_list_list)->
    @cache= []
    @drop = []
    @length = token_list_list.length
    return [] if @length == 0
    @Node = token_list_list[0]?[0]?.constructor
    @proxy= new @Node
    for token_list,idx in token_list_list
      stub = cache_stub.slice()
      for token in token_list
        token.a = idx
        token.b = idx+1
        if -1 != stub_idx = hash_key_list.idx token.mx_hash.hash_key
          stub[stub_idx] = [token]
        stub[0] = [token]
      @cache.push stub
      @drop.push drop_stub.slice()
    
    list = @fsm()
    max_token = token_list_list.length
    
    filter_list = []
    for v in list
      if v.b == max_token
        @node_fix v
        filter_list.push v
    # Прим. А все ошибки, почему не прошло ... смотрим и анализируем @cache
    filter_list
  
  node_fix : (node)->
    walk = (node)->
      vv_list = []
      for v in node.value_array
        walk v
        vv_list.push v.value_view or v.value
      node.value_view = vv_list.join ' '
      return
    walk node
    return

  fsm : ()->
    FAcache = @cache
    FAdrop = @drop
    stack = [
      [
        13
        0
        0
      ]
    ]
    length = @length
    
    while cur = stack.pop()
      [
        hki
        start_pos
        only_new
      ] = cur
      continue if start_pos >= length
      if !only_new
        continue if list = FAcache[start_pos][hki]
      
      switch hki
        when 0
          ### token__ queue ###
          
          stack.push [
            15
            start_pos
            only_new
          ]
        when 15
          ### token__ collect ###
          node_list = []
          
          FAcache[start_pos][0] = node_list
        
        when 1
          ### token_atom queue ###
          
          stack.push [
            28
            start_pos
            only_new
          ]
          ### rule_Hq_token_ultEconst__u1 ###
          stack.push [
            16
            start_pos
            only_new
          ]
          ### rule_Hdq_token_ultEconst__u2 ###
          stack.push [
            18
            start_pos
            only_new
          ]
          ### rule_Htoken_ultEconst__u3 ###
          stack.push [
            20
            start_pos
            only_new
          ]
          ### rule_Hescape_token_ultEconst__u4 ###
          stack.push [
            22
            start_pos
            only_new
          ]
          ### rule_Hhash_id_ultEref__u5 ###
          stack.push [
            24
            start_pos
            only_new
          ]
          ### rule_Hbra_op_Hstmt_Hbra_cl_ultEbra__u11 ###
          stack.push [
            26
            start_pos
            only_new
          ]
        when 28
          ### token_atom collect ###
          node_list = []
          ### rule_Hq_token_ultEconst__u1 ###
          node_list.append FAcache[start_pos][16]
          ### rule_Hdq_token_ultEconst__u2 ###
          node_list.append FAcache[start_pos][18]
          ### rule_Htoken_ultEconst__u3 ###
          node_list.append FAcache[start_pos][20]
          ### rule_Hescape_token_ultEconst__u4 ###
          node_list.append FAcache[start_pos][22]
          ### rule_Hhash_id_ultEref__u5 ###
          node_list.append FAcache[start_pos][24]
          ### rule_Hbra_op_Hstmt_Hbra_cl_ultEbra__u11 ###
          node_list.append FAcache[start_pos][26]
          FAcache[start_pos][1] = node_list
        
        when 2
          ### token_q_token queue ###
          
          stack.push [
            29
            start_pos
            only_new
          ]
        when 29
          ### token_q_token collect ###
          node_list = []
          
          FAcache[start_pos][2] = node_list
        
        when 3
          ### token_dq_token queue ###
          
          stack.push [
            30
            start_pos
            only_new
          ]
        when 30
          ### token_dq_token collect ###
          node_list = []
          
          FAcache[start_pos][3] = node_list
        
        when 4
          ### token_token queue ###
          
          stack.push [
            31
            start_pos
            only_new
          ]
        when 31
          ### token_token collect ###
          node_list = []
          
          FAcache[start_pos][4] = node_list
        
        when 5
          ### token_escape_token queue ###
          
          stack.push [
            32
            start_pos
            only_new
          ]
        when 32
          ### token_escape_token collect ###
          node_list = []
          
          FAcache[start_pos][5] = node_list
        
        when 6
          ### token_hash_id queue ###
          
          stack.push [
            33
            start_pos
            only_new
          ]
        when 33
          ### token_hash_id collect ###
          node_list = []
          
          FAcache[start_pos][6] = node_list
        
        when 7
          ### token_expr queue ###
          
          stack.push [
            44
            start_pos
            only_new
          ]
          ### rule_Hatom_ultEpass__u6 ###
          stack.push [
            34
            start_pos
            only_new
          ]
          ### rule_Hatom_Hor_Hexpr_ultEor__u7 ###
          stack.push [
            36
            start_pos
            only_new
          ]
          ### rule_Hatom_Hoption_ultEoption__u8 ###
          stack.push [
            38
            start_pos
            only_new
          ]
          ### rule_Hatom_Hplus_ultEplus__u9 ###
          stack.push [
            40
            start_pos
            only_new
          ]
          ### rule_Hatom_Hstar_ultEstar__u10 ###
          stack.push [
            42
            start_pos
            only_new
          ]
        when 44
          ### token_expr collect ###
          node_list = []
          ### rule_Hatom_ultEpass__u6 ###
          node_list.append FAcache[start_pos][34]
          ### rule_Hatom_Hor_Hexpr_ultEor__u7 ###
          node_list.append FAcache[start_pos][36]
          ### rule_Hatom_Hoption_ultEoption__u8 ###
          node_list.append FAcache[start_pos][38]
          ### rule_Hatom_Hplus_ultEplus__u9 ###
          node_list.append FAcache[start_pos][40]
          ### rule_Hatom_Hstar_ultEstar__u10 ###
          node_list.append FAcache[start_pos][42]
          FAcache[start_pos][7] = node_list
        
        when 8
          ### token_or queue ###
          
          stack.push [
            45
            start_pos
            only_new
          ]
        when 45
          ### token_or collect ###
          node_list = []
          
          FAcache[start_pos][8] = node_list
        
        when 9
          ### token_option queue ###
          
          stack.push [
            46
            start_pos
            only_new
          ]
        when 46
          ### token_option collect ###
          node_list = []
          
          FAcache[start_pos][9] = node_list
        
        when 10
          ### token_plus queue ###
          
          stack.push [
            47
            start_pos
            only_new
          ]
        when 47
          ### token_plus collect ###
          node_list = []
          
          FAcache[start_pos][10] = node_list
        
        when 11
          ### token_star queue ###
          
          stack.push [
            48
            start_pos
            only_new
          ]
        when 48
          ### token_star collect ###
          node_list = []
          
          FAcache[start_pos][11] = node_list
        
        when 12
          ### token_bra_op queue ###
          
          stack.push [
            49
            start_pos
            only_new
          ]
        when 49
          ### token_bra_op collect ###
          node_list = []
          
          FAcache[start_pos][12] = node_list
        
        when 13
          ### token_stmt queue ###
          
          stack.push [
            54
            start_pos
            only_new
          ]
          ### rule_Hexpr_ultEpass__u12 ###
          stack.push [
            50
            start_pos
            only_new
          ]
          ### rule_Hexpr_Hstmt_ultEjoin__u13 ###
          stack.push [
            52
            start_pos
            only_new
          ]
        when 54
          ### token_stmt collect ###
          node_list = []
          ### rule_Hexpr_ultEpass__u12 ###
          node_list.append FAcache[start_pos][50]
          ### rule_Hexpr_Hstmt_ultEjoin__u13 ###
          node_list.append FAcache[start_pos][52]
          FAcache[start_pos][13] = node_list
        
        when 14
          ### token_bra_cl queue ###
          
          stack.push [
            55
            start_pos
            only_new
          ]
        when 55
          ### token_bra_cl collect ###
          node_list = []
          
          FAcache[start_pos][14] = node_list
        
        when 16
          ### rule_Hq_token_ultEconst__u1 queue ###
          chk_len = stack.push [
            16
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][2]
          if !list_1
            stack.push [
              2
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 17
        when 17
          ### rule_Hq_token_ultEconst__u1 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][2]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hq_token_ultEconst__u1"
            
            mx_hash_stub.hash_key = "atom"
            mx_hash_stub.hash_key_idx = 1
            mx_hash_stub["ult"] = "const"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][16] ?= []
          FAcache[start_pos][16].append ret_list
        when 18
          ### rule_Hdq_token_ultEconst__u2 queue ###
          chk_len = stack.push [
            18
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][3]
          if !list_1
            stack.push [
              3
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 19
        when 19
          ### rule_Hdq_token_ultEconst__u2 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][3]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hdq_token_ultEconst__u2"
            
            mx_hash_stub.hash_key = "atom"
            mx_hash_stub.hash_key_idx = 1
            mx_hash_stub["ult"] = "const"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][18] ?= []
          FAcache[start_pos][18].append ret_list
        when 20
          ### rule_Htoken_ultEconst__u3 queue ###
          chk_len = stack.push [
            20
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][4]
          if !list_1
            stack.push [
              4
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 21
        when 21
          ### rule_Htoken_ultEconst__u3 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][4]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Htoken_ultEconst__u3"
            
            mx_hash_stub.hash_key = "atom"
            mx_hash_stub.hash_key_idx = 1
            mx_hash_stub["ult"] = "const"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][20] ?= []
          FAcache[start_pos][20].append ret_list
        when 22
          ### rule_Hescape_token_ultEconst__u4 queue ###
          chk_len = stack.push [
            22
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][5]
          if !list_1
            stack.push [
              5
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 23
        when 23
          ### rule_Hescape_token_ultEconst__u4 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][5]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hescape_token_ultEconst__u4"
            
            mx_hash_stub.hash_key = "atom"
            mx_hash_stub.hash_key_idx = 1
            mx_hash_stub["ult"] = "const"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][22] ?= []
          FAcache[start_pos][22].append ret_list
        when 24
          ### rule_Hhash_id_ultEref__u5 queue ###
          chk_len = stack.push [
            24
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][6]
          if !list_1
            stack.push [
              6
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 25
        when 25
          ### rule_Hhash_id_ultEref__u5 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][6]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hhash_id_ultEref__u5"
            
            mx_hash_stub.hash_key = "atom"
            mx_hash_stub.hash_key_idx = 1
            mx_hash_stub["ult"] = "ref"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][24] ?= []
          FAcache[start_pos][24].append ret_list
        when 26
          ### rule_Hbra_op_Hstmt_Hbra_cl_ultEbra__u11 queue ###
          chk_len = stack.push [
            26
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][12]
          if !list_1
            stack.push [
              12
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][13]
            if !list_2
              stack.push [
                13
                b_1
                0
              ]
              continue
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              continue if b_2 >= length
              list_3 = FAcache[b_2][14]
              if !list_3
                stack.push [
                  14
                  b_2
                  0
                ]
                continue
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 27
        when 27
          ### rule_Hbra_op_Hstmt_Hbra_cl_ultEbra__u11 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][12]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][13]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              continue if b_2 >= length
              list_3 = FAcache[b_2][14]
              for tok in list_3
                
                b_3 = tok.b
                node.value_array.push tok
                
                arg_list = node.value_array
                
                
                mx_hash_stub = node.mx_hash = {}
                mx_hash_stub.rule = "rule_Hbra_op_Hstmt_Hbra_cl_ultEbra__u11"
                
                mx_hash_stub.hash_key = "atom"
                mx_hash_stub.hash_key_idx = 1
                mx_hash_stub["ult"] = "bra"
                
                node.b = node.value_array.last().b
                
                ret_list.push node.clone()
                
                
                node.value_array.pop()
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][26] ?= []
          FAcache[start_pos][26].append ret_list
        when 34
          ### rule_Hatom_ultEpass__u6 queue ###
          chk_len = stack.push [
            34
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][1]
          if !list_1
            stack.push [
              1
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 35
        when 35
          ### rule_Hatom_ultEpass__u6 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][1]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hatom_ultEpass__u6"
            
            mx_hash_stub.hash_key = "expr"
            mx_hash_stub.hash_key_idx = 7
            mx_hash_stub["ult"] = "pass"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][34] ?= []
          FAcache[start_pos][34].append ret_list
        when 36
          ### rule_Hatom_Hor_Hexpr_ultEor__u7 queue ###
          chk_len = stack.push [
            36
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][1]
          if !list_1
            stack.push [
              1
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][8]
            if !list_2
              stack.push [
                8
                b_1
                0
              ]
              continue
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              continue if b_2 >= length
              list_3 = FAcache[b_2][7]
              if !list_3
                stack.push [
                  7
                  b_2
                  0
                ]
                continue
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 37
        when 37
          ### rule_Hatom_Hor_Hexpr_ultEor__u7 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][1]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][8]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              continue if b_2 >= length
              list_3 = FAcache[b_2][7]
              for tok in list_3
                
                b_3 = tok.b
                node.value_array.push tok
                
                arg_list = node.value_array
                
                
                mx_hash_stub = node.mx_hash = {}
                mx_hash_stub.rule = "rule_Hatom_Hor_Hexpr_ultEor__u7"
                
                mx_hash_stub.hash_key = "expr"
                mx_hash_stub.hash_key_idx = 7
                mx_hash_stub["ult"] = "or"
                
                node.b = node.value_array.last().b
                
                ret_list.push node.clone()
                
                
                node.value_array.pop()
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][36] ?= []
          FAcache[start_pos][36].append ret_list
        when 38
          ### rule_Hatom_Hoption_ultEoption__u8 queue ###
          chk_len = stack.push [
            38
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][1]
          if !list_1
            stack.push [
              1
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][9]
            if !list_2
              stack.push [
                9
                b_1
                0
              ]
              continue
            
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 39
        when 39
          ### rule_Hatom_Hoption_ultEoption__u8 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][1]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][9]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              arg_list = node.value_array
              
              
              mx_hash_stub = node.mx_hash = {}
              mx_hash_stub.rule = "rule_Hatom_Hoption_ultEoption__u8"
              
              mx_hash_stub.hash_key = "expr"
              mx_hash_stub.hash_key_idx = 7
              mx_hash_stub["ult"] = "option"
              
              node.b = node.value_array.last().b
              
              ret_list.push node.clone()
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][38] ?= []
          FAcache[start_pos][38].append ret_list
        when 40
          ### rule_Hatom_Hplus_ultEplus__u9 queue ###
          chk_len = stack.push [
            40
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][1]
          if !list_1
            stack.push [
              1
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][10]
            if !list_2
              stack.push [
                10
                b_1
                0
              ]
              continue
            
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 41
        when 41
          ### rule_Hatom_Hplus_ultEplus__u9 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][1]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][10]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              arg_list = node.value_array
              
              
              mx_hash_stub = node.mx_hash = {}
              mx_hash_stub.rule = "rule_Hatom_Hplus_ultEplus__u9"
              
              mx_hash_stub.hash_key = "expr"
              mx_hash_stub.hash_key_idx = 7
              mx_hash_stub["ult"] = "plus"
              
              node.b = node.value_array.last().b
              
              ret_list.push node.clone()
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][40] ?= []
          FAcache[start_pos][40].append ret_list
        when 42
          ### rule_Hatom_Hstar_ultEstar__u10 queue ###
          chk_len = stack.push [
            42
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][1]
          if !list_1
            stack.push [
              1
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][11]
            if !list_2
              stack.push [
                11
                b_1
                0
              ]
              continue
            
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 43
        when 43
          ### rule_Hatom_Hstar_ultEstar__u10 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][1]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][11]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              arg_list = node.value_array
              
              
              mx_hash_stub = node.mx_hash = {}
              mx_hash_stub.rule = "rule_Hatom_Hstar_ultEstar__u10"
              
              mx_hash_stub.hash_key = "expr"
              mx_hash_stub.hash_key_idx = 7
              mx_hash_stub["ult"] = "star"
              
              node.b = node.value_array.last().b
              
              ret_list.push node.clone()
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][42] ?= []
          FAcache[start_pos][42].append ret_list
        when 50
          ### rule_Hexpr_ultEpass__u12 queue ###
          chk_len = stack.push [
            50
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][7]
          if !list_1
            stack.push [
              7
              b_0
              0
            ]
            continue
          
          if chk_len == stack.length
            stack[chk_len-1][0] = 51
        when 51
          ### rule_Hexpr_ultEpass__u12 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][7]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            arg_list = node.value_array
            
            
            mx_hash_stub = node.mx_hash = {}
            mx_hash_stub.rule = "rule_Hexpr_ultEpass__u12"
            
            mx_hash_stub.hash_key = "stmt"
            mx_hash_stub.hash_key_idx = 13
            mx_hash_stub["ult"] = "pass"
            
            node.b = node.value_array.last().b
            
            ret_list.push node.clone()
            
            
            node.value_array.pop()
          FAcache[start_pos][50] ?= []
          FAcache[start_pos][50].append ret_list
        when 52
          ### rule_Hexpr_Hstmt_ultEjoin__u13 queue ###
          chk_len = stack.push [
            52
            start_pos
            only_new
          ]
          ret_list = []
          b_0 = start_pos
          node = new @Node
          
          list_1 = FAcache[b_0][7]
          if !list_1
            stack.push [
              7
              b_0
              0
            ]
            continue
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][13]
            if !list_2
              stack.push [
                13
                b_1
                0
              ]
              continue
            
            
            node.value_array.pop()
          if chk_len == stack.length
            stack[chk_len-1][0] = 53
        when 53
          ### rule_Hexpr_Hstmt_ultEjoin__u13 collect ###
          ret_list = []
          b_0 = start_pos
          node = new @Node
          node.a = start_pos
          
          list_1 = FAcache[b_0][7]
          for tok in list_1
            if only_new
              continue if !tok._is_new
            
            b_1 = tok.b
            node.value_array.push tok
            
            continue if b_1 >= length
            list_2 = FAcache[b_1][13]
            for tok in list_2
              
              b_2 = tok.b
              node.value_array.push tok
              
              arg_list = node.value_array
              
              
              mx_hash_stub = node.mx_hash = {}
              mx_hash_stub.rule = "rule_Hexpr_Hstmt_ultEjoin__u13"
              
              mx_hash_stub.hash_key = "stmt"
              mx_hash_stub.hash_key_idx = 13
              mx_hash_stub["ult"] = "join"
              
              node.b = node.value_array.last().b
              
              ret_list.push node.clone()
              
              
              node.value_array.pop()
            
            node.value_array.pop()
          FAcache[start_pos][52] ?= []
          FAcache[start_pos][52].append ret_list
    
    FAcache[start_pos][13]

# ###################################################################################################
parser = new module.Parser

@parse = (str)->
  tok_list = tokenizer.go str
  res_list = parser.go tok_list

# debug
@tokenizer = tokenizer
@parser = parser
