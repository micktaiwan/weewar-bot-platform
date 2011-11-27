require File.dirname(__FILE__) + '/../lib/pathfinding'

class Array
  def to_hex

  end
end

module Weewar

  # only for old shortest_path method
  class Game
    attr_accessor :map, :enemy_units
    def initialize(map)
      @map = map
      @enemy_units = []
    end
    def clear_enemies
      @enemy_units.clear
    end
  end

  class Unit

    require File.dirname(__FILE__) + '/../lib/unit_constants'

    attr_accessor :map, :value, :hex, :x, :y, :cost, :unit

    def initialize(game, map, x, y, value, cost)
      @game   = game
      @map    = map
      @x, @y  = x, y
      #@map.set(x,y,value,cost)
      @value  = value
      @cost   = cost
      @hex    = self
      @unit   = self
    end

    def neighbours
      rv = []
      rv << @map.get(@x-1, @y-1) if @x>0  and @y>0
      rv << @map.get(@x-1, @y)   if @x>0
      rv << @map.get(@x-1, @y+1) if @x>0  and @y<19
      rv << @map.get(@x,   @y-1) if           @y>0
      rv << @map.get(@x,   @y+1) if           @y<19
      rv << @map.get(@x+1, @y-1) if @x<19 and @y>0
      rv << @map.get(@x+1, @y)   if @x<19
      rv << @map.get(@x+1, @y+1) if @x<19 and @y<19
      rv
    end

    def entrance_cost(hex, from, zoc_hash)
      raise "hex is nil" if hex.nil?
      zc = zoc_cost(hex, from, zoc_hash)
      hex.cost + zoc_cost(hex, from, zoc_hash)
    end

    def to_s
      "[#{@x},#{@y}]"
    end

    # Math distance (not path related)
    def dist_between(b)
      dx = (b.x - @x).abs
      dy = (b.y - @y).abs
      if b.x != @x and b.y != @y
        [dx,dy].max+1-[dx,dy].min
      else
        return [dx,dy].max
      end
    end

    def mobility(dummy)
      8
    end

    def occupied?
      @map.get(@x,@y).value[0].chr == '+'
    end

  end

  class Map

    def initialize(game)
      @game = game
      @map = Array.new
      for i in (0..19)
        @map[i] = Array.new
        for j in (0..19)
          @map[i][j] = Weewar::Unit.new(@game, self, i, j, "1 ", 1)
        end
      end
    end

    def print_map
      puts
      for j in (0..19)
        for i in (0..19)
          print @map[i][j].value
        end
        puts
      end
      puts
    end

    def set(i,j, value, cost)
      @map[i][j].value = value+" "
      @map[i][j].cost  = cost
      @map[i][j]
    end

    def get(i,j)
      @map[i][j]
    end

    # only for old shortest_path method
    def each
      for j in (0..19)
        for i in (0..19)
          raise "nil" if @map[i][j].nil?
          yield @map[i][j]
        end
      end
    end

    # only for old shortest_path method
    def hex_neighbours(unit)
      unit.neighbours
    end

    def clear(char=nil, cost=1)
      for j in (0..19)
        for i in (0..19)
          if !char
            @map[i][j].value = "1 "
          else
            @map[i][j].value = char+" "
          end
          @map[i][j].cost  = cost
        end
      end
    end

    def random
      for j in (0..19)
        for i in (0..19)
          a = ((Math.sin(i.to_f/4)*5).round - (Math.cos(j.to_f/4)*4).round)
          a = 0 if a < 0
          @map[i][j].value = a.to_s+" "
          @map[i][j].cost  = a*4
        end
      end
    end

  end
end


describe "Pathfinding" do

  before(:all) do
    @game = Weewar::Game.new(@map)
    @map  = Weewar::Map.new(@game)
  end
  it "basic" do
    @map.clear
    @map.set(2,2,"5",5)
    @map.set(2,1,"5",5)
    @map.set(2,3,"5",5)
    @map.set(3,3,"5",15)
    @map.set(4,3,"5",5)
    @map.set(3,4,"5",5)
    @map.set(5,3,"5",5)
    @map.set(3,5,"5",5)

    path = @map.get(0,0).shortest_path(@map.get(4,4))
    if !path
      puts "no path"
    else
      path.each { |u|
        @map.set(u.x,u.y," ",0)
        #print "#{u.to_s}=>"
        }
      #puts "goal"
      @map.print_map
    end
    path.size.should eq(8)
  end

  it "some map" do
    @map.random

    path = @map.get(0,0).shortest_path(@map.get(19,19))
    if !path
      puts "no path"
    else
      path.each { |u|
        @map.set(u.x,u.y," ",0)
        #print "#{u.to_s}=>"
        }
      @map.print_map
    end
    path.size.should eq(26)
  end

  it "my_destinations 1" do
    @map.clear(" ")
    exclusions = [
      @map.set(8,4,"+",1),
      @map.set(9,4,"+",1),
      @map.set(10,4,"+",1),

      @map.set(8,7,"+",1),
      @map.set(9,7,"+",1),
      @map.set(10,7,"+",1),
      @map.set(10,8,"+",1),
      @map.set(10,9,"+",1),
      @map.set(10,10,"+",1),
      @map.set(10,11,"+",1),
      @map.set(10,12,"+",1),
      @map.set(10,13,"+",1),
      @map.set(11,13,"+",1),
      @map.set(12,13,"+",1)
      ]
    @game.clear_enemies
    exclusions.each { |e|
      @game.enemy_units << e
      }
    u = Weewar::Unit.new(@game, @map,9,10,"O",1)
    @map.set(9,10,"O",1)
    dests = @map.get(u.x,u.y).my_destinations(exclusions)
    dests.each { |d|
      @map.set(d.x,d.y,"X",1)
      }
    @map.print_map
    dests.size.should eq(193)
  end

  it "near an enemy" do
    @map.clear(" ",2)
    @map.set(9,10,"O",0)

    u     = @map.get(9,10)
    goal  = @map.get(13,8)
    goal.value = "O "
    @game.clear_enemies
    @game.enemy_units << @map.set(11,8,"+",1)
    @game.enemy_units << @map.set(11,9,"+",1)

    #dests = @map.get(u.x,u.y).my_destinations
    #dests.each { |d|
    #  @map.set(d.x,d.y,"X",1)
    #  }
    zh = Weewar::Unit.init_zoc_hash(@game)
    path = u.shortest_path(goal, @game.enemy_units)
    #path.each { |d|
    #  @map.set(d.x,d.y,"X",1)
    #  }
    @map.print_map
    #puts path.join('=>')
    #dests.size.should eq(193)
  end

end

