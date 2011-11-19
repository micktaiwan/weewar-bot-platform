#!/usr/bin/env ruby
# @markup markdown
# @title Weewar Bot
# @author Mickael Faivre-Maçon

require 'bot'

# comment out to play online
# $local_game = true

module Weewar

  # = Manage Weewar gameswith some utilities
  # Each game is a WeewarBot taking care of the game logic.<br>
  # As it is a no real-time game, no threding is used at all.
  # Each game is played each after another.
  class Weewar

    def initialize
      Utils.init
      @bots = []
    end

    def do_loop
      loop do
        begin
          just_played = false
          puts '================= loop begin'
          # get HQ
          r = Utils.get("headquarters")
          raise r.body if r.code!="200"
          data = Utils.xmls(r.body, {'ForceArray' => ['game']})
          puts "got HQ"
          data['game'].each { |g|
            puts "game: #{g['name']}: #{g['state']} #{g['factionState']}"
            #next if g['inNeedOfAttention'] != "true"
            # invites
            case g['state']
            when 'lobby'
              case
              when g['factionState'] != 'accepted'
                if g['rated']=='false'
                  accept_invitation(g['id'])
                  puts '  accepted'
                else
                  decline_invitation(g['id'])
                  puts '  declined'
                end
              end
            when 'running'
              if g['inNeedOfAttention'] == "true"
                puts '  will play'
                play(g['id'])
                just_played = true
              else
                puts '  not my turn'
              end
            when 'finished'
              puts '  removing'
              remove_game(g['id'])
            else
              puts "don't know how to handle this state: #{g['state']}"
            end
            }
        rescue Exception=>e
          puts "ERROR: #{e.message}"
        end
        secs = 60
        puts "Sleeping #{secs}s..."
        sleep(secs)
      end
    end

    # Accepts an invitation to a game.
    def accept_invitation( game_id )
      Utils.raw_send "<weewar game='#{game_id}'><acceptInvitation/></weewar>"
    end

    # Declines an invitation to a game.
    def decline_invitation( game_id )
      Utils.raw_send "<weewar game='#{game_id}'><declineInvitation/></weewar>"
    end

    # Removes a game from headquarters.
    def remove_game( game_id )
      p Utils.raw_send "<weewar game='#{game_id}'><removeGame/></weewar>"
    end

    # @return [Array] an array of user game ids
    def my_games
      user_games(Utils.credentials[:login])
    end

    # will play all bot games
    # @param [Hash]   options: See Bot class
    def play_all(options)
      @bots.each { |b|
        b.play(options)
        }
    end

    # will play a game
    # @param [String] id: the game id
    # @param [Hash]   options: See Bot class
    def play(id, options={})
      (find(id) || add_bot(id)).play(options)
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

    # Download a map
    def dl_map(id)
      r = Utils.get("map/#{id}")
      raise r.message if r.code!="200"
      File.open(File.dirname(__FILE__) + "/maps/map_#{id}.xml","w").write(r.body)
    end

  end
end

if __FILE__ == $0
  puts "standalone mode not implemented yet"
  puts "run ruby main.rb for an interactive prompt"
  w = Weewar::Weewar.new
  #w.play(338663, {:analyse_only=>true})
  w.do_loop
end

