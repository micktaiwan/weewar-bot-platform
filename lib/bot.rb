require File.dirname(__FILE__) + '/utils'
require File.dirname(__FILE__) + '/game'
require File.dirname(__FILE__) + '/map'
require File.dirname(__FILE__) + '/analyse'

module Weewar

  # = Weevar Bot
  # Play a given game
  class Bot

    attr_reader :game_id, :game, :account

    def initialize(account, game_id)
      @account  = account
      @game_id  = game_id
      @game     = Game.new(self, @game_id, {:local_game=>$local_game})
      #@states   = []
    end

    # @param [Hash] options
    # Options:
    # *  :analyse_only=>true: will not send any command to the server
    def play(options)
      @game.refresh
      puts "  Game #{@game['name']} #@game_id (map #{@game.map[:id]}: #{@game[:name]}) is #{@game[:state]}"
      return if @game[:state].to_s != 'running'
      puts "  Players: #{@game[:players]['player'].map{|h| h['content']}.join(', ')}"
      if(options[:analyse_only])
        puts 'analyse only'
        analyse(@game)
      else
        if !@game.me_to_play?
          puts "  not my turn yet (game: #{@game[:name]} / ##{@game_id})"
        else
          take_turn
        end
      end
    end

    # check if we need to surrender
    def need_to_surrender?
      # FIXME: finished means the unit turn (not the game) is over so surrending if there is no available unit is dumb
      #if(units.size==0)
      #  puts "  Surrending"
      #  p game.surrender # can't surrender
      #  return
      #end

      # TODO: we check the eval function points instead

      # if we are in the process of taking a base
      return false if @game.my_units.find_all{ |u| u.capturing?}.size > 0
      return true if (@game.my_units.size*3 < @game.enemy_units.size) and
        @game.my_bases.size < @game.enemy_bases.size
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
