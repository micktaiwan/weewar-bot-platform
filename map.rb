require 'utils'

# = Weewar map
class Map < XmlData

   def initialize(game_id, options={})
    @method = "map"
    @id     = game_id
    # TODO: cache maps (there is a revision tag!) and check if map has been saved on disk, reload it if it is the case
    super(options)
  end

end

