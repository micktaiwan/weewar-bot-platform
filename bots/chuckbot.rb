require File.dirname(__FILE__) + '/../lib/bot'

module Weewar

  class ChuckBot < Bot

    def initialize(account, game_id)
      super(account, game_id)
    end

    def take_turn
      puts "  Taking turn for game #{@game.id}"

      i = me = my = @game.my_faction
      units = @game.my_units.find_all { |u| not u.finished? }

      if(need_to_surrender?)
        surrender
        return
      end

      enemies     = @game.enemy_units
      # Move units
      units.each do |unit|
        # Find a place to go, things to shoot
        if(unit.type==:linf)
          destination = unit.nearest(@game.neutral_bases.find_all { |b| !b.occupied?})
          destination = unit.nearest(@game.enemy_bases) if !destination
        end
        destination = unit.nearest(enemies) if !destination
        unit.move_to(destination,:also_attack => enemies) if destination
        # TODO: if can't move, repair
      end
      # Build

      #linf =  my.units.find_all { |u| u.type == :linf }


      build = []
      @game.my_bases.each do |base|
        next if base.occupied?
        [:tank, :raider, :linf].each { |unit|
          if i.can_afford?(unit) # TODO: refresh credit
            base.build unit
            build << unit
            break
          end
          }
        break if build.size >= 2
      end
      puts "    build: #{build.join(', ')}"

      # End
      puts "  Ending turn for game #{@game.id}"
      @game.finish_turn
    end


  end

end


