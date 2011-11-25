require File.dirname(__FILE__) + '/../lib/pathfinding'

module Weewar

  # only for old shortest_path method
  class Game
    attr_accessor :map
    def initialize(map)
      @map = map
    end
  end

  class Unit

    INFINITY = 999999

    attr_accessor :map, :value, :hex, :x, :y, :cost

    def initialize(map, x, y, value, cost)
      @x, @y = x, y
      @map    = map
      @value  = value
      @hex = self
      @game = Game.new(@map)
      @cost = cost
    end

    def neighbours
      rv = []

      rv << @map.get(@x-1, @y-1) if @x>0 and @y>0
      rv << @map.get(@x-1, @y) if @x>0
      rv << @map.get(@x, @y-1) if @y>0

      rv << @map.get(@x+1, @y+1) if @x<19 and @y<19
      rv << @map.get(@x+1, @y) if @x<19
      rv << @map.get(@x, @y+1) if @y<19

      rv << @map.get(@x-1, @y+1) if @x>0 and @y<19
      rv << @map.get(@x+1, @y-1) if @x<19 and @y>0

      rv
    end

    def entrance_cost(hex)
      raise "hex is nil" if hex.nil?
      hex.cost
    end

    def to_s
      "[#{@x},#{@y}]"
    end

    # Math distance (not path related)
    def dist_between(a,b)
      dx = b.x - a.x
      dy = b.y - a.y
      Math.sqrt(dx*dx+dy*dy)
    end

  end
end

class Map

  def initialize
    @map = Array.new
    for i in (0..19)
      @map[i] = Array.new
      for j in (0..19)
        @map[i][j] = Weewar::Unit.new(self, i, j, "1 ", 1)
      end
    end
  end

  def print_map
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

  def clear
    for j in (0..19)
      for i in (0..19)
        @map[i][j].value = "1 "
        @map[i][j].cost  = 1
      end
    end
  end

  def random
    for j in (0..19)
      for i in (0..19)
        a = ((Math.sin(i.to_f/6.3)*6).round - (Math.sin(j.to_f/3)*2).round)
        a = 0 if a < 0
        @map[i][j].value = a.to_s+" "
        @map[i][j].cost  = a
      end
    end
  end


end


describe "Pathfinding" do

  before(:all) do
    @map = Map.new
  end

  it "basic" do
    @map.clear
    @map.set(0,0,"+",1)
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
      #@map.print_map
    end
    path.map{|u| [u.x,u.y]}.should eq([[1,1],[1,2],[1,3],[2,4],[2,5],[3,6],[4,5],[4,4]])
  end

  it "random" do
    @map.random

    path = @map.get(0,0).shortest_path(@map.get(19,19), [@map.get(3,3)])
    if !path
      puts "no path"
    else
      path.each { |u|
        @map.set(u.x,u.y," ",0)
        print "#{u.to_s}=>"
        }
      puts "goal"
      @map.print_map
    end
  end

end

