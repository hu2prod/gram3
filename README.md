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
  * `rule('r', '*')` `rule('r', '+')` is now not valid. Use `rule('r', '\\*')` `rule('r', '\\+')`

# WIP
  * token sequence quality of life
    * quantificators + ? *
  * solid coverage
