require File.dirname(__FILE__) + '/utils'
require File.dirname(__FILE__) + '/game'
require File.dirname(__FILE__) + '/map'
require File.dirname(__FILE__) + '/analyse'

module Weewar

  # = Weevar Bot
  # Play a given game
  class Bot

    attr_reader :game_id, :game

    def initialize(game_id)
      @game_id  = game_id
      @game     = Game.new(@game_id, {:local_game=>$local_game})
      #@states   = []
    end

    # @param [Hash] options
    # Options:
    # *  :analyse_only=>true: will not send any command to the server
    def play(options)
      @game.refresh
      #s = add_state
      # find he we can play
      #s = @states.last
      s = @game
      puts "  Game #{@game_id} (map #{s.map[:id]}: #{s[:name]}) is #{s[:state]}"
      return if s[:state].to_s != 'running'
      puts "  Players: #{s[:players]['player'].map{|h| h['content']}.join(', ')}"
      if(options[:analyse_only])
        puts 'analyse only'
        analyse(s)
      else
        if !s.me_to_play?
          puts "  not my turn yet (game: #{s[:name]} / ##{@game_id})"
        else
          basic(s)
        end
      end
    end

    def basic(game)
      puts "  Taking turn for game #{game.id}"

      i = me = my = game.my_faction
      units = my.units.find_all { |u| not u.finished? }

      if(need_to_surrender?)
        surrender
        return
      end

      enemies     = game.enemy_units
      # Move units
      units.each do |unit|
        # Find a place to go, things to shoot
        destination = unit.nearest(game.neutral_bases.find_all { |b| !b.occupied?})
        destination = unit.nearest(game.enemy_bases) if !destination
        destination = unit.nearest(enemies) if !destination
        unit.move_to(destination,:also_attack => enemies) if destination
        # TODO: if can't move, repair
      end
      # Build
      game.my_bases.each do |base|
        next if base.occupied?
        [:tank, :raider, :linf].each { |unit|
          if i.can_afford?( unit )
            base.build :linf
            break
          end
          }
      end


      # End
      puts "  Ending turn for game #{game.id}"
      game.finish_turn
    end

    # check if we need to surrender
    def need_to_surrender?
      # FIXME: finished means the unit turn (not the game) is over so surrending if there is no available unit is dumb
      #if(units.size==0)
      #  puts "  Surrending"
      #  p game.surrender # can't not surrender
      #  return
      #end

      # TODO: we check the eval function points instead
      false
    end

protected

    # @return a state, newly created and initialized with data
    def add_state
      # TODO: check if getting a new state is necessary
      tag(Game.new(@game_id, {:local_game=>$local_game, :get=>!$local_game})) { |s|
        @states << s
        }
    end

  end
end
