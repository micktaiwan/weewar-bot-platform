require 'utils'

class GameState < XmlData

  def initialize(game_id, options)
    @method = 'gamestate'
    @id     = game_id
    super(options)
  end

  def which_side
    @data[:state]
  end

end

