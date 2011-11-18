require 'utils'
require 'game'
require 'map'

module Weewar

  # = Weevar Bot
  # Play a game
  class Bot

    attr_reader :game_id

    def initialize(game_id)
      @game_id  = game_id
      @states   = []
    end

    # @param [Hash] options
    # Options:
    # *  :analyse_only=>true: will not send any command to the server
    def play(options)
      s = add_state
      # find he we can play
      s = @states.last
      puts "Game #{@game_id} (map #{s.map[:id]}: #{s.map[:name]}) is #{s[:state]}"
      return if s[:state].to_s != 'running'
      puts "Players:"
      p s[:players]['player']
      if s.me_to_play?
        basic(s)
      else
        puts 'not my turn'
      end
    end

    def basic(game)
      puts "Taking turn for game #{@game_id}"
      i = me = my = game.my_faction

      # Find a place to go, things to shoot
      destination = game.enemy_bases.first
      enemies     = game.enemy_units

      # Move units
      my.units.find_all { |u| not u.finished? }.each do |unit|
        unit.move_to(
          destination,
          :also_attack => enemies
        )
      end

      # Build
      game.my_bases.each do |base|
        next if base.occupied?

        if i.can_afford?( :linf )
          base.build :linf
        end
      end

      puts "Ending turn for game #{game.id}"
      game.finish_turn
    end

protected

    # @return a state, newly created and initialized with data
    def add_state
      # TODO: check if getting a new state is necessary
      tag(Game.new(@game_id, {:local_game=>$local_game, :get=>false})) { |s|
        @states << s
        }
    end

  end
end
