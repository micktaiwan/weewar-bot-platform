
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
      tag(eval("#{@name}.new(self, #{id})")) { |b|
        @bots << b
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
          puts " -\"#{g['name']}\": #{g['state']}/#{g['factionState']} http://weewar.com/game/#{g['id']}"
          #next if g['inNeedOfAttention'] != "true"
          # invites
          case g['state']
          when 'lobby'
            case
            when g['factionState'] != 'accepted'
              if g['rated']=='false'
                accept_invitation(g['id'])
                puts '  accepted'
                b = find(g['id'])
                if b
                  b.game.chat("Hello")
                end
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
                  b.game.finish_turn
                  b.game.chat("Ooops. Finishing my turn due to this error: #{e.message.split("\n").join(". ")}")
                end
                puts "While playing: #{e.message}"
                puts e.backtrace
                #puts "game data is:"
                #p g
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
  end # class

end  # module

