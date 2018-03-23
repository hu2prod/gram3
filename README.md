# gram3
Next breaking change over gram2

# improvements over gram1/2
  * Standalone compile
    * mx, strict rules uses own grammar
    * token sequence also uses own grammar
  * Coverage
  * No gram1 dependency
  * (need check) even more performance with new algo (GLR-like)

# Breaking changes
  * `rule('r', '*')` `rule('r', '+')` is now not valid. Use `rule('r', '\\*')` or `rule('r', '"*"')` or `rule('r', "'*'")`
  * `rule('r', '"+"').strict('$1.hash_key==tok_bin_op')` will not work anymore because when you access via const you get from const node list, not tok_bin_op or tok_un_op, or somewhere else

# Coverage bomb warning
  * gram3 generate .coffee after instrumenting iced-coffee-script could die with Max call stack error. compile to js first then use coverage tools over .js file

# WIP
  * token sequence quality of life
    * quantificators + ? *
  * solid coverage
