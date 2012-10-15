define ->
  class RegexUtil

    @singleCommand = (keywords...) ->
      new RegExp "^\\s*(#{keywords.join('|')})\\b\\s*"

    @paramCommand = (keyword) ->
      new RegExp "^\\s*#{keyword}\\s(?:(?:(?:(.*)\\\\)|(\\w+)\\b))\\s*"

    @param = (match) ->
      return match[1] ? match[2]