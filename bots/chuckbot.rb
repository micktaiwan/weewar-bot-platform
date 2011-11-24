require File.dirname(__FILE__) + '/../lib/bot'

module Weewar

  class ChuckBot < Bot

    def initialize(account, game_id)
      super(account, game_id)
    end

    def take_turn
      # TODO:
      # attack first capturing bases enemies
      # coordinated attacks
      # better movements order
      i = me = my = @game.my_faction
      puts "  Taking turn for game #{@game.id}. Credits: #{my.credits}. Board score: #{board_score}"

      units = @game.my_units.find_all { |u| not u.finished? }

      enemies       = @game.enemy_units
      not_attacked  = @game.enemy_units
      attacked = []
      # Move units
      # TODO: make 2 loops on units that didn't move before doing something else
      units.sort_by{|u| [u.attack_range[0], -u.defense_strength, -u.hp, -u.speed(1)]}.each do |unit|
        all_others = (@game.my_units + enemies) - [unit]
        puts "    Moving #{unit}"
        move_options = {}
        moved = nil

        # debugging
        enemies.find_all {|u| !u.respond_to?(:defense_strength)}.each { |u|
          puts "**  #{u} does not respond to 'defense_strength'"
          }

        puts "    #{unit} destinations: #{unit.my_destinations.size}"


        # TODO not good, attack formula will not take the right terrain as we didn't move yet
        weakers     = enemies.find_all {|u| unit.battle_outcome(u) > 0 }
        puts "enemies:"
        enemies.each {|u|
          puts "     attack outcome for #{unit} vs #{u} is #{unit.battle_outcome(u)}"
          }
        puts "weakers:"
        weakers.each {|u|
          puts "     attack outcome for #{unit} vs #{u} is #{unit.battle_outcome(u)}"
          }
        puts "     weakers: #{weakers.size}"
        gets
        #to_attack   = weakers - attacked
        dest = nil
        # Find a place to go, things to shoot
        if([:hover, :hinf, :linf].include?(unit.type))
          dest = unit.nearest(@game.neutral_bases.find_all { |b| !b.occupied?}, enemies)
          dest = unit.nearest(@game.enemy_bases, @game.my_units) if !dest
          moved = unit.move_to(dest,move_options) if dest
        end
        if !moved
          # TODO: take into account air types
          dest = unit.nearest(attacked, all_others) if attacked.size > 0
          dest = unit.nearest(weakers, all_others-weakers) if !dest
          dest = unit.nearest(weakers, []) if !dest
          attacked += [dest] if dest and !attacked.include?(dest)
          move_options[:also_attack] = weakers
        end
        if dest and !moved
          moved = unit.move_to(dest,move_options)
        end

        # TODO: to refactor...
=begin
        if !moved
          dest = unit.nearest(my.units.find_all{|u| u.strength > unit.strength}, all_others)
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
        # TODO: run for life instead of reparing if surrounded by enemies. Repair only if no escape.
        if !moved
          if unit.surrounded?(1)
            dest = unit.nearest(my.units.find_all{|u| u.strength > unit.strength}, all_others)
            dest = unit.nearest(my.units.find_all{|u| u.hp > unit.hp}, all_others) if !dest
            if dest
              move_options[:also_attack] = []
              move_options[:exclusions] = all_others
              moved = unit.move_to(dest,move_options)
              puts "     escaped: #{moved}"
            end
          end
          if !moved and unit.hp < 10
            puts "     repairing #{unit}"
            unit.repair
          end
        end
      end

      # Build
      @build = []
      @total_cost = 0
      def build_unit(base, unit)
        return if Unit::UNIT_COSTS[unit] > (@game.my_faction.credits-@total_cost)
        puts "* building #{unit}"
        base.build unit
        @build << unit
        @total_cost += Unit::UNIT_COSTS[unit]
      end

      # Maybe go the other way around: first know what to build and then find bases to build it
      # but in that case the surrounded bases must be first analyzed
      # and a more intelligent system is needed anyway. Horus will do it :)
      @builders_built = 0
      @game.my_bases.each do |base|
        next if base.occupied?

        #if free bases and no builders, build them
        builders = [:hover, :linf] - @game.disabled_units
        built = false
        # TODO: ...and the builders is able to reach the base
        if @builders_built < 2 and
           @game.neutral_bases.find_all { |b| !b.occupied?}.size > 0 and
           @game.my_units.find_all { |u| builders.include?(u.type) and !u.capturing?}.size == 0
          builders.each { |b|
            if Unit::UNIT_COSTS[b] < my.credits-@total_cost
              puts "*    building a builder"
              build_unit(base, b); @builders_built += 1; built = true; break
            else; next # see if we can build next cheaper unit
            end
           }
        end
        next if built

        # other units
        ([:bers, :htank, :hover, :tank, :raider, :hinf, :linf] - @game.disabled_units).each_with_index do |unit, index|
          # build if base is surrounded
          if base.surrounded?(1)
            if Unit::UNIT_COSTS[unit] < my.credits-@total_cost
              build_unit(base, unit); break
            else; next # see if we can build next cheaper unit
            end
          end
          next if Unit::UNIT_COSTS[unit] > my.credits-@total_cost
          nb_enemies  = enemies.find_all { |u| u.type==unit }.size
          nb_units    = @game.my_units.find_all { |u| u.type==unit }.size
          # insure we have almost the same units as enemy. If we have no money for it, wait
          if nb_enemies > nb_units
            build_unit(base, unit); break
          end

          # if enough unit of the same type, go to next one
          next if my.credits-@total_cost < 1200*2 and nb_units >= nb_enemies

          build_unit(base, unit)
          break
        end
      end
      puts "    build: #{@build.join(', ')}. Total cost: #{@total_cost}. Credits: #{my.credits-@total_cost}"

      # End
      puts "  Ending turn for game #{@game.id}"
      @game.finish_turn
      if(false)#need_to_surrender?)
        @game.surrender
        @game.chat("OK, this is futile, you won :)")
        puts "!   Surrendering !"
        return
      end
    end


  end

end


