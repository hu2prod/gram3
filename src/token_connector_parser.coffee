{parse} = require './token_connector_gen'

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

