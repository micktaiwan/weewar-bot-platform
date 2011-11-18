require 'net/http'
require 'utils'

# = Weevar Bot
# Manage a game.
class Bot

  def initialize
  end

  def start_game(game_id)
    @game_id  = game_id
    @map      = Map.new(game_id)
  end

  # get the current game state
  # @return [string] xml
  def get_game_state
    Utils.get("gamestate/#{@game_id}")
  end

  # @private does not work
  #def get_game_status(game_id=@game_id)
  #  get("game/#{game_id}")
  #end

end

