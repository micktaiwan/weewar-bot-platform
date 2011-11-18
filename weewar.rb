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

  attr_accessor :bot

  def initialize
    @bot = Bot.new
  end

  # @return [Array] an array of user game ids
  def games
    user_games(Utils.credentials[:login])
  end

  # @return [Array] an array of user game ids
  def user_games(name)
    r = user(name)
    return if r.code!="200"
    doc = REXML::Document.new(r.body)
    tag([]) do |games|
      doc.elements.each('user/games/game') { |g| games << g.text.to_i }
    end
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
    tag(Utils.get("games/open")) { |r|
      puts r.message if r.code!="200"
      }
  end

end

