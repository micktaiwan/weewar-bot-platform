require File.dirname(__FILE__) + '/../lib/bot'

module Weewar

  class ChuckBot < Bot

    def initialize(account, game_id)
      super(account, game_id)
    end

    def take_turn
      i = me = my = @game.my_faction
      puts "  Taking turn for game #{@game.id}. Credits: #{my.credits}. Board score: #{board_score}"

      units = @game.my_units.find_all { |u| not u.finished? }

      enemies       = @game.enemy_units
      not_attacked  = @game.enemy_units
      attacked = []
      # Move units
      units.each do |unit|
        move_options = {}
        moved = nil
        weakers     = enemies.find_all {|u| u.respond_to?(:strength) and (u.strength <= unit.strength) and (u.hp <= unit.hp) }
        #to_attack   = weakers - attacked
        dest = nil
        # Find a place to go, things to shoot
        if([:hover, :hinf, :linf].include?(unit.type))
          dest = unit.nearest(@game.neutral_bases.find_all { |b| !b.occupied?}, enemies)
          dest = unit.nearest(@game.enemy_bases, enemies) if !dest
          moved = unit.move_to(dest,move_options) if dest
        end
        if !moved
          dest = unit.nearest(weakers)#, enemies)
          attacked += [dest] if dest
          move_options[:also_attack] = weakers
        end
        moved = unit.move_to(dest,move_options) if dest
        # TODO: to refactor...
=begin
        if !moved
          dest = unit.nearest(my.units.find_all{|u| u.strength > unit.strength}, enemies)
          dest = unit.nearest(my.units.find_all{|u| u.hp > unit.hp}, enemies) if !dest
          if dest
            moved = unit.move_to(dest,move_options)
            puts "    escaping" if moved
          end
          if unit.hex.type == :base
            moved = unit.move_to(units.first, {}) # get out of our base
          end
        end
=end
        if !moved and unit.hp < 10
          puts "    repairing #{unit}"
          unit.repair
        end
      end
      # Build

      #linf =  my.units.find_all { |u| u.type == :linf }
      build = []
      @game.my_bases.each do |base|
        next if base.occupied?
        ([:htank, :hover, :tank, :raider, :hinf, :linf] - @game.disabled_units).each_with_index { |unit, index|
        # TODO: to add :htank, we must first see if disabled or not
          nb_enemies = enemies.find_all { |u| u.type==unit }.size
          nb_units = @game.my_units.find_all { |u| u.type==unit }.size
          next if nb_units > nb_enemies and nb_units.size > index+2
          next if nb_units > nb_enemies and nb_units.size*Unit::UNIT_COSTS[unit] >= my.credits

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
      if(need_to_surrender?)
        @game.surrender
        @game.chat("OK, this is futile, you won :)")
        puts "!   Surrendering !"
        return
      end
    end


  end

end


