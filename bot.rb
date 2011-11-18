require 'net/http'
require 'utils'
require 'game'
require 'map'

module Weewar

  # = Weevar Bot
  # Play a game
  class Bot

    def initialize(game_id)
      @game_id  = game_id
      @map      = nil
      @states   = []
    end

    # @param [Hash]   options: analyse=>true: will not send any command to the server
    def start_game(options)
      s = add_state
      @map      = Map.new(s[:map], {:get=>true}) if !@map
      play
    end

    # @return a state, newly created and initialized with data
    def add_state
      # TODO: check if getting a new state is necessary
      tag(Game.new(@game_id, {:get=>true})) { |s|
        @states << s
        }
    end

    def play
      # find he we can play
      s = @states.last
      puts "Game #{@game_id} (map #{@map[:id]}: #{@map[:name]}) is #{s[:state]}"
      return if s[:state].to_s != 'running'
      puts "Players:"
      p s[:players]['player']
    end

  end
end
