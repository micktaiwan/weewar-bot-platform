require File.dirname(__FILE__) + '/xml_data'
require File.dirname(__FILE__) + '/utils'
require File.dirname(__FILE__) + '/hex'

module Weewar

  # Instances of the Map class provide access to the Hex es of a Map,
  # either individually, or by means of iterators or filters.
  class Map < XmlData
    attr_reader :width, :height, :cols, :units

    include Enumerable

    SYMBOL_FOR_TERRAIN = {
      'Plains' => :plains,
      'Water' => :water,
      'Mountains' => :mountains,
      'Desert' => :desert,
      'Woods' => :woods,
      'Swamp' => :swamp,
      'Base' => :base,
      'Harbor' => :harbour,
      'repairshop' => :repairshop,
      'Airfield' => :airfield,
      'red_city' => :red_base,
      'blue_city' => :blue_base,
      'purple_city' => :purple_base,
      'yellow_city' => :yellow_base,
      'green_city' => :green_base,
      'white_city' => :white_base,
      'red_harbor' => :red_harbour,
      'blue_harbor' => :blue_harbour,
      'purple_harbor' => :purple_harbour,
      'yellow_harbor' => :yellow_harbour,
      'green_harbor' => :green_harbour,
      'white_harbor' => :white_harbour,
      'red_airfield' => :red_airfield,
      'blue_airfield' => :blue_airfield,
      'purple_airfield' => :purple_airfield,
      'yellow_airfield' => :yellow_airfield,
      'green_airfield' => :green_airfield,
      'white_airfield' => :white_airfield,
    }

    # Creates a new Map instance, based on the given Game and map ID number.
    # You normally do not need to call this yourself.
    def initialize(game, map_id, options={})
    #def initialize( game, map_id )
      @game         = game
      @account      = game.account
      @id           = map_id
      @method       = "map"
      super({ 'ForceArray' => ['terrain'] })
      # load cached map
      # TODO: there is a revision tag, use it
      map_path      = File.dirname(__FILE__) + "/maps/map_#{@id}.xml"
      begin
        xml = File.open(map_path,'r').read
      rescue Errno::ENOENT
        # map does not exist, save map locally
        xml = get(@xml_options)
        File.open(map_path,'w').write(xml)
      end
      set_data(xml)
      @width  = self['width'].to_i
      @height = self['height'].to_i
      @cols   = Hash.new
      self['terrains']['terrain'].each do |t|
        x = t['x'].to_i
        @cols[x] ||= Hash.new
        y = t['y'].to_i
        symb = SYMBOL_FOR_TERRAIN[t['type']]
        raise "no symbols for #{t['type']}" if !symb
        @cols[x][y] = Hex.new(@game,symb,x,y)
      end
    end

    # The Hex at the given coordinates.
    #   the_hex = map.hex( 2, 8 )
    def hex(x, y)
      x = x.to_i
      y = y.to_i
      c = @cols[x]
      if c
        c[y]
      end
    end
    alias xy hex

    # conflict with XmlData[]
    # A convenience method for obtaining the Hex for a given coordinate pair.
    #   hex = my_map[3, 7]
    #def [](*xy)
    #  hex(xy[0], xy[1])
    #end

    # The Hex at the given coordinates, with the coordinates given in row-column
    # order (y, x).
    #   the_hex = map.rc( 8, 2 )
    def rc( y, x )
      hex(x, y)
    end

    # An Array of the given Hex's neighbouring Hex es.
    # The Array will not contain any nil elements.
    #   surrounding_hexes = map.hex_neighbours( some_hex )
    def hex_neighbours( h )
      if h.y % 2 == 0
        # Even row (not shifted)
        [
          hex( h.x    , h.y - 1 ), # NE
          hex( h.x + 1, h.y     ), # E
          hex( h.x    , h.y + 1 ), # SE
          hex( h.x - 1, h.y + 1 ), # SW
          hex( h.x - 1, h.y     ), # W
          hex( h.x - 1, h.y - 1 ), # NW
        ].compact
      else
        # Odd row (shifted right)
        [
          hex( h.x + 1, h.y - 1 ), # NE
          hex( h.x + 1, h.y     ), # E
          hex( h.x + 1, h.y + 1 ), # SE
          hex( h.x    , h.y + 1 ), # SW
          hex( h.x - 1, h.y     ), # W
          hex( h.x    , h.y - 1 ), # NW
        ].compact
      end
    end

    # Iterates over every Hex in the map.
    # Takes a block argument, as per the usual Ruby each method.
    #   map.each do |hex|
    #     puts hex
    #   end
    def each( &block )
      @cols.values.map { |col| col.values }.flatten.compact.each &block
    end

    # All base Hex es.
    #   only_bases = map.bases
    def bases
      find_all { |hex| hex.type == :base }
    end

  end
end

