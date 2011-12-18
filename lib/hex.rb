require 'open-uri'
require 'hpricot'
require File.dirname(__FILE__) + '/traits'

module Weewar

  # The Hex class represents one hex in a Map.  You issue the build command
  # through a Hex instance.  You can also query whether a Hex is occupied
  # or capturable.
  class Hex
    attr_reader :x, :y, :type
    attr_accessor :faction, :unit

    SYMBOL_FOR_NAME = {
      'Airfield' => :airfield,
      'Base' => :base,
      'Desert' => :desert,
      'Harbor' => :harbour,
      'Mountains' => :mountains,
      'Plains' => :plains,
      'Swamp' => :swamp,
      'Water' => :water,
      'Woods' => :woods,
      'Bridge' => :bridge,
      'Repair patch' => :repairshop,
      'Repairshop' => :repairshop,
    }


    TERRAIN_VALUE = {
      :plains     => 0,
      :water      => 1,
      :mountains  => 3,
      :desert     => 2,
      :woods      => 2,
      :swamp      => 2,
      :base       => 1,
      :harbour    => 1,
      :repairshop => 1,
      :airfield   => 1
      }


    # No need to call this yourself.  Hexes are parsed and built
    # by the Map class.
    def initialize(game, type, x, y)
      @game, @type, @x, @y = game, type, x, y
    end

    # Downloads the terrain specifications from weewar.com.
    # No need to call this yourself.
    def Hex.initialize_specs
      trait[:terrain_specs] = Hash.new
      #doc = Hpricot( open( 'http://weewar.com/specifications' ) )
      doc = Hpricot(File.new(File.dirname(__FILE__) + '/res/unit_specifications.html', 'r').read)
      h2 = doc.at('#Terrains')
      table = h2.next_sibling
      table.search( 'tr' ).each do |tr|
        name = tr.at( 'b' ).inner_text
        type = SYMBOL_FOR_NAME[name]
        #puts type
        if !type
          raise "Unknown terrain type: #{name}"
        else
          #puts type
          h = trait[:terrain_specs][type] = {
            :attack => parse_numbers( tr.search( 'td' )[2].inner_text),
            :defense => parse_numbers( tr.search( 'td' )[3].inner_text),
            :movement => parse_numbers( tr.search( 'td' )[4].inner_text),
          }
        end
      end
      #p trait[:terrain_specs][:base][:defense]
      #exit
    end

    # An internal method used by initialize_specs.
    def Hex.parse_numbers( text )
      retval = Hash.new
      text.scan( /(\w+):([-]{0,1}\d+)/ ) do |data|
        retval[data[0].to_sym] = data[1].to_i
      end
      retval
    end

    # The terrain_specs Hash.
    def Hex.terrain_specs
      trait[:terrain_specs]
    end

    def to_s
      "#{@type}[#{@x},#{@y}] with "+ (@unit.nil? ? 'no unit' : @unit.type.to_s)
    end

    def hex
      self
    end

    # Comparison for equality with another Hex.
    # A Hex equals another Hex if it has the same coordinates and is
    # of the same type.
    #   if one_hex == another_hex
    #     puts "The hexes are the same."
    #   end
    def ==( other )
      @x == other.x and @y == other.y and @type == other.type
    end

    # Issues a command to build the given Unit type on this Hex.
    #   base.build :linf
    # TODO: do not send command directly
    def build( unit_type )
      raise "faction is nil" if self.faction == nil
      @game.send "<build x='#{@x}' y='#{@y}' type='#{Unit::TYPE_FOR_SYMBOL[unit_type]}'/>"

      # TODO: I set finished=true, but if I don't refresh the game at next round
      # it could still be at true. I don't know the rules of bulding a unit
      unit = Unit.new(@game, self, self.faction, unit_type, 10, true, false)
      @game.units << unit
      self.faction.credits -= Unit::UNIT_COSTS[unit_type]

      # @game.refresh # Mick
    end

    # Whether or not this Hex is occupied (by a Unit).
    #   if not hex.occupied?
    #     my_unit.move_to hex
    #   end
    def occupied?
      not @unit.nil?
    end

    # Whether or not this Hex is capturable by Unit s that can capture.
    #   if hex.capturable?
    #     my_trooper.move_to hex
    #   end
    def capturable?
      @faction != @game.my_faction and [:base, :harbour, :airfield].include?( @type )
    end

    def surrounded_nb(units=nil)
      units ||= @game.all_units(@game.other_factions)
      return @game.map.hex_neighbours(self).inject(0) { |sum, h|
        sum += (units.include?(h.unit) or (hex.unit and hex.unit.speed(1) < h.entrance_cost(hex.unit)))? 1 : 0
        }
    end

    def surrounded_by?(n, units=nil)
      return true if surrounded_nb(units) >= n
      false
    end

    def entrance_cost(unit)
      raise "type is nil" if @type.nil?

      specs_for_type = Hex.terrain_specs[@type]
      raise "**  No spec for type '#{hex.type}' hex: #{hex}" if specs_for_type.nil?
      tag(specs_for_type[:movement][unit.unit_class]) { |rv|
        raise "no movement spec for #{unit.unit_class}" if !rv
        }
    end

    def neighbours(n=1)
      return @game.map.hex_neighbours(self) if n == 1
      return recursive_neighbours(n)
    end

    def recursive_neighbours(number, rv=[])
      new_nb = []
      neighbours.each { |n|
        if not rv.include?(n)
          new_nb << n
          rv << n
        end
        }
      new_nb.each { |n| n.recursive_neighbours(number-1, rv) } if number > 0
      rv
    end

    def value
      raise "no terrain_value for #@type" if !TERRAIN_VALUE[@type]
      return TERRAIN_VALUE[@type] + (@unit ? 5 : -1)
    end

    def coords
      [@x,@y]
    end

    def dist_between(b)
      # R0d => D6
      x0, y0, x1, y1 = @x, @y, b.x, b.y
      x0 += (y0+1)/2
      x1 += (y1+1)/2
      # translation of (X1,Y1) by (-X0,-Y0)
      dx = x1-x0
      dy = y1-y0
      # distance from origin in D6
      (dx.abs+dy.abs+(dx-dy).abs)/2
    end

private

    def sign(a)
      return :minus if a < 0
      return :plus
    end

  end
end

