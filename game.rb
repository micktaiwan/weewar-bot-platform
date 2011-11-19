# lot of code by Pistos:
# https://github.com/Pistos/weewar-ai

require 'utils'
require 'player'
require 'faction'
require 'unit'

module Weewar

  # The Game class is your interface to a game on the weewar server.
  # Game instances are used to do such things as finish turns, surrender,
  # and abandon.  Also, you access game maps and units through a Game
  # instance.
  class Game < XmlData
    attr_reader :id, :name, :round, :state, :pending_invites, :pace, :type,
      :url, :map, :map_url, :credits_per_base, :initial_credits, :playing_since,
      :players, :units, :factions
    attr_accessor :last_attacked

    # Instantiate a new Game instance corresponding to the weewar game
    # with the given id number.
    #   game = WeewarAI::Game.new( 132 )
    def initialize(game_id=nil, options={})
      @method = 'gamestate'
      @id     = game_id
      if options[:local_game]
        super({:data=>File.open(File.dirname(__FILE__) + "/specs/game_for_testing.xml",'r').read},
          {'ForceArray' => ['faction', 'player', 'terrain', 'unit']})
      else
        super(options, { 'ForceArray' => ['faction', 'player', 'terrain', 'unit'], })
      end
      @map    = Map.new(self, self[:map].to_i, options) if !@map
      refresh
    end

    def me_to_play?
      p = get_player(login)
      raise "can't find player #{login}" if !p
      p['current'] ? true : false
    end

    def get_player(name)
      self[:players]['player'].each { |p|
        return p if p['content'] == name
        }
      nil
    end

    # The Player whose turn it is.
    #   turn_taker = game.current_player
    #def current_player
    #  @players.find { |p| p.current? }
    #end

    #alias pendingInvites pending_invites
    #alias mapUrl map_url
    #alias creditsPerBase credits_per_base
    #alias initialCredits initial_credits
    #alias playingSince playing_since

    # Hits the weewar server for all the game state data as it sees it.
    # All internal variables are updated to match.
    #   my_game.refresh
    def refresh
      @name   = self['name']
      @round  = self['round'].to_i
      @state  = self['state']
      @pending_invites = ( self['pendingInvites'] == 'true' )
      @pace   = self['pace'].to_i
      @type   = self['type']
      @url    = self['url']
      @players = self['players']['player'].map { |p| Player.new(p) }
      @credits_per_base = self['creditsPerBase']
      @initial_credits = self['initialCredits']
      @playing_since = Time.parse( self['playingSince'] )

      @units = Array.new
      @factions = Array.new
      self['factions']['faction'].each_with_index do |faction_xml,ordinal|
        faction = Faction.new( self, faction_xml, ordinal )
        @factions << faction
        #p faction_xml
        next if !faction_xml['unit'] # happens when no more unit :) (dead)
        faction_xml['unit'].each do |u|
          hex = @map.hex(u['x'].to_i, u['y'].to_i)
          unit = Unit.new(
            self,
            hex,
            faction,
            u['type'],
            u['quantity'].to_i,
            u['finished'] == 'true',
            u['capturing'] == 'true'
          )
          @units << unit
          hex.unit = unit
        end
        faction_xml['terrain'].each do |terrain|
          hex = @map.hex(terrain['x'], terrain['y'])
          if hex.type == :base
            hex.faction = faction
          end
        end
      end
    end

    # Sends some command XML for this game to the server.  You should
    # generally never need to call this method directly; it is used
    # internally by the Game class.
    def send(xml_command)
      Utils.raw_send "<weewar game='#{@id}'>#{xml_command}</weewar>"
    end

    #-- -------------------------
    # API Commands
    #++

    # End turn in this game.
    #   game.finish_turn
    def finish_turn
      send "<finishTurn/>"
    end
    alias finishTurn finish_turn

    # Surrender in this game.
    #  game.surrender
    def surrender
      send "<surrender/>"
    end

    # Abandon this game.
    #  game.abandon
    def abandon
      send "<abandon/>"
    end

    #-- --------------------------------------------------
    # Utilities
    #++

    # The Faction of the given player.
    #   pistos_faction = game.faction_for_player 'Pistos'
    def faction_for_player( player_name )
      @factions.find { |f| f.player_name == player_name }
    end

    # Your AI's Faction in this game.
    #   me = my = i = game.my_faction
    #   puts "My name is #{my.player_name}."
    #   if i.can_afford? :htank
    #     my_base.build :htank
    #   end
    def my_faction
      faction_for_player(login)
    end

    # An Array of the Units not belonging to your AI.
    #   bad_guys = game.enemy_units
    def enemy_units
      @units.find_all { |u| u.faction != my_faction }
    end

    # An Array of the base Hexes for this game.
    #   bases = game.bases
    def bases
      @map.bases
    end

    # An Array of the base Hexes owned by the given faction.
    #   their_bases = game.bases enemy_faction
    def bases_of( faction )
      @map.bases.find_all { |b| b.faction == faction }
    end

    # Your AI's bases in this game.
    #   good_bases = game.my_bases
    def my_bases
      bases_of my_faction
    end

    # An Array of bases not owned by your AI (including neutral bases).
    #   capturable_bases = game.enemy_bases
    def enemy_bases
      @map.bases.find_all { |b| b.faction != my_faction }
    end

protected

    def login
      Utils.credentials[:login]
    end
  end

end

