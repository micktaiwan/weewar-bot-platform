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
      puts "  Taking turn for game #{@game.name}. Credits: #{my.credits}. Board score: #{board_score}"
      attacked = []
      going_to_bases = []
      units         = @game.my_units.find_all { |u| not u.finished? }


      # TODO: loop through bsses to take first and then non capturers, marking capturers that moved or not

      # Move units
      # TODO: make 2 loops on units that didn't move before doing something else
      units.sort_by{|u| [u.speed(1)]}.each do |unit|
       # [u.attack_range[0], -u.defense_strength, -u.hp, -u.speed(1)]
        #next if !unit # useless, but in case we implement the remove myself if dead after attack feature

        # After a victorious attack, the enemy is still in the array and therefore
        # following units still believe it is there, so need to refresh the array at each loop
        # (as @game.units is refresh)
        enemies       = @game.enemy_units

        if unit.surrounded_by?(6,@game.my_units) # to gain speed, but no attack possible...
          puts "    #{unit} is surrounded"
          next
        end

        all_others = (@game.my_units + enemies) - [unit]
        puts "\n    Moving #{unit}..."
        move_options = {}

        # debugging
=begin
        puts "=== 2 / #{unit}"
        enemies.each {|u|
          puts "- ennemy: #{u}"
          }
=end
        enemies.find_all {|u| !u.respond_to?(:defense_strength)}.each { |u|
          puts "**  #{u} does not respond to 'defense_strength'"
          }

        #puts "    #{unit} destinations: #{unit.my_destinations.size}"

        # TODO not good, attack formula will not take the right terrain as we didn't move yet
        weakers     = enemies.find_all {|u| unit.battle_outcome(u) >= 0 }
        #weakers     = enemies.find_all {|u| (u.defense_strength < unit.defense_strength) or
        #  (u.defense_strength <= unit.defense_strength and u.hp < unit.hp) }
        #puts "enemies:"
        #enemies.each {|u|
        #  puts "     attack outcome for #{unit} vs #{u} is #{unit.battle_outcome(u)}"
        #  }
        #puts "weakers:"
        #weakers.each {|u|
        #  puts "     attack outcome for #{unit} vs #{u} is #{unit.battle_outcome(u)}"
        #  }
        puts "     weakers: #{weakers.size}"
        #gets
        #to_attack   = weakers - attacked
        dest  = nil
        moved = nil # # FIXME: moved or dest, but why 2 of them ?
        # Find a place to go, things to shoot
        if(not Unit::CAPTURERS.include?(unit.type))
          # if we are not a capturer and there are base to take, insure they have paths to go
          moved = unit.insure_paths_to_enemy_bases_not_blocked
        else
          # TODO: the capturer to go to the base shall be the nearest,
          # it is not the case as we loop through the capturers first (and then select the nearest base)
          # and not the bases first
          dest  = unit.nearest((@game.neutral_bases + @game.enemy_bases).find_all { |b| !going_to_bases.include?(b)}, enemies)
          if dest
            moved = unit.move_to(dest,{:exclusions=>enemies, :also_attack=>@game.enemy_on_bases})
            if moved
              going_to_bases << dest
              puts "     gone to base #{dest}"
            end
          end
          if !dest
            dest  = unit.nearest(@game.enemy_bases, enemies)
            moved = unit.move_to(dest,{:exclusions=>all_others, :also_attack=>weakers}) if dest
            puts "     gone to enemy base #{dest}" if moved
          end
        #elsif(unit.max_range > 1)
        #  unit.find_target_and_safe_place
        end

        # TODO: attack enemies capturing our base
        # TODO: if we are trying to attack nearest enemy, first use my_targets, it is quicker
        if !moved
          #if attacked.size > 0
          #  dest = unit.nearest(attacked, all_others)
          #  puts("     found attacked: #{dest}")
          #end
          dest = unit.select_near_target
          if dest
            puts("     found near target: #{dest}")
          else
            dest = unit.nearest(weakers, all_others-weakers)
          end
          if dest
            puts("     found weaker: #{dest}")
          else
            # TODO: must verify that enemy is in range, otherwise the unit could go very far....
            dest = unit.nearest(attacked, all_others-attacked)
            dest = nil if dest and unit.dist_between(dest) > unit.speed(1)-1
            puts("     found attacked: #{dest}") if dest
          end
          if dest
            # FIXME: a :bers can not move to woods so it can not attack the unit there !!!!
            attacked += [dest] if !attacked.include?(dest)
            puts("     #{unit} trying to move to #{dest}")
            moved = unit.move_to(dest,{:exclusions=>all_others, :also_attack=>enemies})
            # FIXME: unit.best_place_to_attack(dest)
            puts("     moved ? =>  #{moved}")
          end
        end

        if !moved
          print("     Didn't move so trying surrounded... ")
          if unit.surrounded_by?(1)
            puts "yes"
=begin
            dest = unit.nearest(my.units.find_all{|u|
              (u.defense_strength > unit.defense_strength) or
              ((u.defense_strength == unit.defense_strength) and (u.hp > unit.hp))
              }, [])
            if dest
              move_options[:also_attack] = weakers
              move_options[:exclusions] = all_others
              moved = unit.move_to(dest,move_options)
              puts "     escaped ? => #{moved}"
            end
=end
          else
            puts "no"
          end
          # get out of the base
          if !moved and unit.hex.type == :base
            puts "     moving #{unit} out of base"
            target = unit.hex.neighbours.find_all {|h| h.unit.nil?}.first
            puts "     target is #{target}"
            moved = unit.move_to(target) if target # get out of our base
            puts "     out of base ? => #{moved}"
          end
          if !moved and unit.hp < 10
            puts "     repairing #{unit}"
            unit.repair
          end
        end
      end

      build

      # End
      @game.finish_turn
      puts "  Ending turn for game #{@game.name}. Credits: #{my.credits}. Board score: #{board_score}"
      if(false) #need_to_surrender?) # TODO: need to check nb of factions, or else it surrender too easily
        @game.surrender
        @game.chat("OK, this is futile, you won :)")
        puts "!   Surrendering !"
        return
      end
    end

    def build
      @build = []
      @total_cost = 0
      my      = @game.my_faction
      enemies = @game.enemy_units

      # Maybe go the other way around: first know what to build and then find bases to build it
      # but in that case the surrounded bases must be first analyzed
      # and a more intelligent system is needed anyway. Horus will do it :)
      @builders_built = 0
      @alt ||= 1
      @game.my_bases.sort_by{ |b| [-b.hex.surrounded_nb(enemies), b.hex.surrounded_nb(my.units)]}.each do |base|
        next if base.occupied?

        if base.surrounded_by?(1)
          build_close_attack_units(base)
          next
        end

        #if free bases and no builders, build them
        builders = [:hover, :linf] - @game.disabled_units
        built = false
        # TODO: ...and the builders is able to reach the base
        if # @builders_built > 0 and
           @game.my_units.find_all { |u|
            builders.include?(u.type) and !u.capturing?
            }.size < @game.enemy_bases.size + @game.neutral_bases.size
          builders.each { |b|
            if Unit::UNIT_COSTS[b] < my.credits
              puts "*    building a builder"
              build_unit(base, b); @builders_built += 1; built = true; break
            else; next # see if we can build next cheaper unit
            end
           }
        end
        next if built

        if @game.bot.board_score <= 18
          # other units
          build_close_attack_units(base) if @alt % 4!=0 # one base over 4
          build_range_attack_units(base) if @alt % 4==0
          @alt += 1
          puts "     alt=#@alt"
        end
      end
      puts "    build: #{@build.join(', ')}. Total cost: #{@total_cost}. Credits: #{my.credits}"
    end

    def build_close_attack_units(base)
      my      = @game.my_faction
      ([:bers, :htank, :tank, :raider, :hinf, :linf] - @game.disabled_units).each do |unit|
        next if Unit::UNIT_COSTS[unit] > my.credits
        # build if base is surrounded
        if base.surrounded_by?(1)
          build_unit(base, unit)
          break
        end

        nb_enemies  = @game.enemy_units.find_all { |u| u.type==unit }.size
        nb_units    = my.units.find_all { |u| u.type==unit }.size
        # insure we have almost the same units as enemy
        if nb_enemies > nb_units
          build_unit(base, unit)
          break
        end

        # TODO: find a better decision to build or not
        if (nb_units <= nb_enemies and (my.credits > 1.5*Unit::UNIT_COSTS[unit])) or
           (nb_units <= nb_enemies+3 and (my.credits > 2*Unit::UNIT_COSTS[unit]))
          build_unit(base, unit)
          break
        end
      end
    end

    def build_range_attack_units(base)
        my      = @game.my_faction
      ([:dfa, :hart, :aa, :lart] - @game.disabled_units).each do |unit|
        next if Unit::UNIT_COSTS[unit] > my.credits

        enemies     = @game.enemy_units
        nb_enemies  = enemies.find_all { |u| u.type==unit }.size
        nb_units    = my.units.find_all { |u| u.type==unit }.size
        # insure we have almost the same units as enemy
        if nb_enemies > nb_units
          build_unit(base, unit)
          break
        end

        # TODO: find a better decision to build or not
        if (nb_units <= nb_enemies and (my.credits > 1.5*Unit::UNIT_COSTS[unit])) or
           (nb_units <= nb_enemies+2 and (my.credits > 3*Unit::UNIT_COSTS[unit]))
          build_unit(base, unit)
          break
        end
      end
    end

    def build_unit(base, unit)
      return if Unit::UNIT_COSTS[unit] > (@game.my_faction.credits)
      puts "* building #{unit}"
      base.build unit
      @build << unit
      @total_cost += Unit::UNIT_COSTS[unit]
    end

  end

end


