#!/usr/bin/env ruby
# @markup markdown
# @title Weewar Bot
# @author Mickael Faivre-Maçon

require 'bot'

# = Manage Weewar gameswith some utilities
# Each game is a WeewarBot taking care of the game logic.<br>
# As it is a no real-time game, no threding is used at all.
# Each game is played each after another.
class Weewar

  def initialize
    @bots = []
  end

  # @return [Array] an array of user game ids
  def my_games
    user_games(Utils.credentials[:login])
  end

  # will play a game
  # @param [String] id: the game id
  # @param [Hash]   options: See Bot class
  def start_game(id, options={})
    (find(id) || add_bot(id)).start_game(options)
  end

  def add_bot(id)
    tag(Bot.new(id)) { |b| @bots << b }
  end

  def find(id)
    @bots.each { |b|
      return b if b.game_id == id
      }
    nil
  end

  # @return [Array] an array of user game ids
  def user_games(name)
    r = user(name)
    return if r.code!="200"
    Utils.xmls(r.body)['games']
  end

  # @return [HTTPResponse] a response with the user full xml
  def game_state(game_id)
    tag(Utils.get("gamestate/#{game_id}")) { |r|
      puts r.message if r.code!="200"
      }
  end

  # @return [HTTPResponse] a response with the user full xml
  def user(name)
    tag(Utils.get("user/#{name}")) { |r|
      puts r.message if r.code!="200"
      }
  end

  # get open games (not started yet games)
  # @return [HTTPResponse] xml
  def get_open_games
    r = Utils.get("games/open")
    raise r.message if r.code!="200"
    Utils.xmls(r.body, { 'GroupTags' => { 'game' => 'id' }})
  end

end


if __FILE__ == $0
  puts "standalone mode not implemented yet"
  puts "run ruby main.rb for an interactive prompt"
end

