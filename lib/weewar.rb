#!/usr/bin/env ruby
# @markup markdown
# @title Weewar Bot
# @author Mickael Faivre-Maçon

# comment out to play online
# $local_game = true

#require File.dirname(__FILE__) + '/bot'
# require all files in /bots
dir = File.dirname(__FILE__) + '/../bots/*.rb'
Dir.glob(dir).each { |e|
  puts "requiring #{e}"
  require e
  }

module Weewar

  class Account
    include Enumerable

    attr_reader  :type, :name, :shortcut, :login, :key

    def initialize(t, n, s, l, k)
      @type, @name, @shortcut, @login, @key  = t.strip.to_sym, n.strip, s.strip, l.strip, k.strip
      # a bot manage a currently played game
      @bots     = []
    end

    def to_s
      "#@type: \t'#@name' (shortcut: #@shortcut, login: #@login)"
    end

    def get_hq
      r = Utils.get(self,"headquarters")
      raise r.body if r.code!="200"
      Utils.xmls(r.body, {'ForceArray' => ['game']})
    end

    # Accepts an invitation to a game.
    def accept_invitation(game_id)
      Utils.raw_send(self, "<weewar game='#{game_id}'><acceptInvitation/></weewar>")
    end

    # Declines an invitation to a game.
    def decline_invitation(game_id)
      Utils.raw_send(self, "<weewar game='#{game_id}'><declineInvitation/></weewar>")
    end

    # Removes a game from headquarters.
    def remove_game(game_id)
      Utils.raw_send(self, "<weewar game='#{game_id}'><removeGame/></weewar>")
    end

    # @return [Array] an array of user game ids
    def my_games
      user_games(login)
    end

    # will play a game
    # @param [String] id: the game id
    # @param [Hash]   options: See Bot class
    def play(id, options={})
      (find(id) || add_bot(id)).play(options)
    end

    def add_bot(id)
      tag(eval("#{name}.new(self, #{id})")) { |b|
        @bots << b
        b.game.chat("I'm up again!")
        }
    end

    def find(id)
      @bots.each { |b|
        return b if b.game_id == id
        }
      nil
    end

    # process a bot account HQ
    def process_hq_once
      raise "Error: can not process HQ with this function as current account is not a bot: #{login}" if @type!=:bot
      # get HQ
      puts "getting HQ for #{name}"
      data = get_hq
      if data['game']
        data['game'].each { |g|
          puts " game: #{g['name']}: #{g['state']} #{g['factionState']}"
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
            if g['factionState'] == "created"
              accept_invitation(g['id'])
              puts '  accepted'
            end
            if g['inNeedOfAttention'] == "true"
              puts '  will play'
              begin
                play(g['id'])
              rescue Exception=>e
                b = find(g['id'])
                if b
                  b.game.chat("Ooops. Finishing my turn due to this error: #{e.message}")
                  b.game.finish_turn
                end
                puts "While playing: #{e.message}"
                puts e.backtrace
                puts "game data is:"
                p g
              end
            else
              puts '  not my turn'
            end
          when 'finished'
            #puts '  removing'
            #remove_game(g['id'])
          else
            puts "Error: don't know how to handle this state: #{g['state']}"
          end
          }
      end # if data
    end
  end

  # = Manage Weewar Bot Accounts with some utilities
  # Each game is a WeewarBot taking care of the game logic.
  # As it is a no real-time game, no threding is used at all.
  # Each game is played each after another.
  class Weewar

    def initialize
      Utils.init
      # an account manage invitations (not begun game) and finished games
      init_accounts
    end

    def init_accounts
      # set your login / developper key in the file ./accounts.txt
      # Edit a "accounts.txt" file in the weewar directory and write your login and development key in it as "type:name:shortcut:login:key"
      # an account by line. Type can be either "bot" or "human".
      # The name of a bot must be the name of the bot class
      # For an human, the name is not important. I mean in this code :)
      #   for example:
      #   bot:DaydBot:a:ai_Dayd:8f9t6U5Fnkuede23z79iRcmBn
      #   human:Mick:m:MickTaiwan:9d26h9jU5Fnu23z79is8y7T
      # The shortcut will be used to switch account easily using the interactive prompt.
      @accounts = []
      path = File.dirname(__FILE__) + '/../accounts.txt'
      File.open(path,'r').each_line { |line|
        next if line.strip==""
        arr = line.split(':')
        a = Account.new(arr[0],arr[1],arr[2],arr[3],arr[4])
        @accounts << a
        puts a
        }
      @bot_accounts = @accounts.find_all { |a| a.type==:bot }
    end

    def do_loop
      loop do
        begin
          t = Time.now
          puts '================= loop begin'
          @bot_accounts.each { |a| a.process_hq_once }
          secs = 60-(Time.now-t)
          secs = 0 if secs < 0
          puts "Sleeping #{secs}s..."
          sleep(secs)
        rescue Interrupt=>e # Ctrl-C
          puts " again to exit, anything else to loop #{Time.now-t}"
          i = gets.chomp
          break if i == "exit"
        rescue Exception=>e
          puts "ERROR: #{e.message}"
          puts e.backtrace
          sleep(60)
        end # begin
      end # loop
    end # do_loop

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

    # @return [Array] an array of user game ids
    def user_games(name)
      r = user(name)
      return if r.code!="200"
      Utils.xmls(r.body)['games']
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
  w = Weewar::Weewar.new
  w.do_loop
end

