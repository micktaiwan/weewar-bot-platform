require 'utils'

# = Weewar map
class Map

  def initialize(game_id)
    @game_id = game_id
    get(game_id)
  end

  # @return [string] xml representing the game map
  def get
    response = Utils.get("api1/map/#{@game_id}")
    raise "Could not get map. See logs." if(response.code!=200)
    puts response.body
    @width = @height = 0
  end

end

