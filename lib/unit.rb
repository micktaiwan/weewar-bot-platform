require File.dirname(__FILE__) + '/pathfinding'

module Weewar

  # An instance of the Unit class corresponds to a single unit in a game.
  #
  # The Unit class provides access to Unit attributes like coordinates (x, y),
  # health (hp), and type (trooper, raider, etc.).  Also available are tactical
  # calculation data, such as enemy targets that can be attacked, and hexes that
  # can be reached in the current turn.
  #
  # Unit s can be ordered to move, attack or repair.
  #
  # Read the full method listing to see everything you can do with a Unit.
  class Unit
    attr_reader :faction, :hex, :type
    attr_accessor :hp

    require File.dirname(__FILE__) + '/unit_constants'

    # Units are created by the Map class.  No need to instantiate any on your own.
    def initialize(game, hex, faction, type, hp, finished, capturing = false)
      sym = SYMBOL_FOR_UNIT[type]
      raise "Unknown type: '#{type}'" if sym.nil?

      @game, @hex, @faction, @type, @hp, @finished, @capturing =
        game, hex, faction, sym, hp.to_i, finished, capturing
    end

    def to_s
      "#{@faction}.#{@type}@(#{@hex.x},#{@hex.y})"
    end

    # The Unit's current x coordinate (column).
    #   my_unit.x
    def x
      @hex.x
    end

    # The Unit's current y coordinate (row).
    #   my unit.y
    def y
      @hex.y
    end

    # Whether or not the unit can be ordered to do anything further.
    #   if not my_unit.finished?
    #     # do stuff with my_unit
    #   end
    def finished?
      @finished
    end

    # Whether or not the unit is capturing a base at the moment.
    #   if not my_trooper.capturing?
    #     # do stuff with my_trooper
    #   end
    def capturing?
      @capturing
    end

    # The unit class of this unit. i.e. :soft, :hard, etc.
    #   if my_unit.unit_class == :hard
    #     # attack some troopers!
    #   end
    def unit_class
      UNIT_CLASSES[@type]
    end

    # Comparison for equality with another Unit.
    # A Unit equals another Unit if it is standing on the same Hex,
    # is of the same Faction, and is the same type.
    #   if new_unit == old_unit
    #   end
    def ==(other)
      return false if !other
      @hex == other.hex and
      @faction == other.faction and
      @type == other.type
    end

    # Whether or not the Unit type can capture bases or not.
    # Be aware that this can return true even if the Unit can no longer
    # take action during the current turn.
    #   if my_unit.can_capture?
    #     my_unit.move_to enemy_base
    #   end
    def can_capture?
      [:linf, :hinf, :hover].include? @type
    end

    # An Array of the Units which this Unit can attack in the current turn.
    # If the optional origin Hex is provided, the target list is calculated
    # as if the unit were on that Hex instead of its current Hex.
    #   enemies_in_range = my_unit.targets
    #   enemies_in_range_from_there = my_unit.targets possible_attack_position
    # TODO: replace that. do not call the server.
    #def targets(origin = @hex)
    #  coords = XmlSimple.xml_in(
    #    @game.send("<attackOptions x='#{origin.x}' y='#{origin.y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>")
    # )['coordinate']
    #  if coords
    #    coords.map { |c|
    #      @game.map.hex(c['x'], c['y']).unit
    #    }.compact
    #  else
    #    []
    #  end
    #end
    #alias attack_options targets
    #alias attackOptions targets

    def my_targets(origin = @hex)
      # get all the hex we can attach in our range
      hexes, cost = attack_hexes
      range_min, range_max = attack_range
      if range_min > 0
        hexes = hexes.select { |h| cost[h] >= range_min }
      end
      hexes = hexes.select { |h| !h.unit.nil? and !h.unit.allied_with?(self) and attack_strength(h.unit.unit_class) > 0 }
      puts "     #{self} with range [#{range_min},#{range_max}] can attack #{hexes.join(', ')}"
      hexes
    end

    # TODO: same algorithm than pathfinding, except range and entrance cost are different
    def attack_hexes(from=nil, cc=0, done=nil, cost=nil)
      # starting hex
      from ||= self.hex
      raise "no hex ?" if !from
      # path cost from self. algorith stops when current_cost > unit attack range
      current_cost = cc
      cost ||= Hash.new
      # every hex done
      done ||= []
      # take neighbourgs hex, check the path cost, add them to possibles hexes, recurse
      new_h = Array.new
      range_min, range_max = attack_range
      from.neighbours.each { |h|
        ec = 1 # entrance cost is 1 for all type of terrain
        next if h == self.hex or done.include?(h) or current_cost+ec > range_max # not already calculated # not too far
        done << h
        new_h << h
        cost[h] = current_cost+ec
        }
      # recurse
      new_h.each { |h|
        done, cost = attack_hexes(h, current_cost+1, done, cost)
        }
      [done, cost]
    end

    # Whether or not the Unit can attack the given target.
    # Returns true iff the Unit can still take action in the current round,
    # and the target is in range.
    #   if my_unit.can_attack? enemy_unit
    #     my_unit.attack enemy_unit
    #   end
    def can_attack?(target)
      not @finished and my_targets.include?(target)
    end

    # Whether or not the Unit can reach the given Hex in the current turn.
    #   if my_unit.can_reach? the_hex
    #     my_unit.move_to the_hex
    #   end
    def can_reach?(hex)
      my_destinations.include? hex
    end

    # An Array of the Unit s of the Game which are on the same side as this Unit.
    #   friends = my_unit.allied_units
    def allied_units
      @game.units.find_all { |u| u.faction == @faction }
    end

    # Whether or not the given unit is an ally of this Unit.
    #   if not my_unit.allied_with?(other_unit)
    #     my_unit.attack other_unit
    #   end
    def allied_with?(unit)
      @faction == unit.faction
    end


    #-- --------------------------------------------------
    # Actions
    #++

    # Sends an XML command to the server regarding this Unit. This is an
    # internal method that you should normally not need to call yourself.
    def send(xml)
      command = "<unit x='#{x}' y='#{y}'>#{xml}</unit>"
      response = @game.send command
      doc = Hpricot.XML(response)
      @finished = !! doc.at('finished')
      if not @finished
        $stderr.puts "#{self} NOT FINISHED:\n\t#{response}"
      end
      if not doc.at('ok')
        error = doc.at 'error'
        if error
          message = "ERROR from server: #{error.inner_html}"
        else
          message = "RECEIVED:\n#{response}"
        end
        # FIXME: could happen if a :bship moved, did not attack. It's not finished but can not move anymore.
        str = "**  Failed to execute:\n#{command}\n#{message}"
        puts str
        Utils.log_debug str
      end
      response
    end

    # Moves the given Unit to the given destination if it is reachable
    # in one turn, otherwise moves the Unit towards it using the optimal path.
    #
    #   this_unit.move_to some_hex
    #   that_unit.move_to enemy_unit
    #
    # If a Unit or an Array of Units is passed as the :also_attack option,
    # those Units will be prioritized for attack after moving, with the Units
    # assumed to be given from highest priority (index 0) to lowest.
    #
    #   another_unit.move_to(
    #     enemy_unit,
    #     :also_attack => [enemy_unit] + enemy_artillery)
    #  )
    #
    # If an Array of hexes is provided as the :exclusions option, the Unit will
    # not pass through any of the exclusion Hex es on its way to the destination.
    #
    #   spy_unit.move_to(
    #     enemy_base,
    #     :exclusions => well_defended_choke_point_hexes
    #  )
    #
    # By default, moving onto a base with a capturing unit will attempt a capture.
    # Set the :no_capture option to true to prevent this.
    #
    #   my_trooper.move_to(enemy_base, :no_capture => true)
    #
    #   navy_seal.move_to(
    #     enemy_base,
    #     :also_attack => hard_targets,
    #     :exclusions => fortified_hexes,
    #     :no_capture => true
    #  )
    def move_to(destination, options = {})
      raise "**  destination is nil" if !destination
      command = ""
      options[:exclusions] ||= []
      puts "     destination is #{destination}, #{options[:exclusions].size} exclusions"

      done = false
      new_hex = @hex

      if destination != @hex
        # Travel

        path = shortest_path(destination, options[:exclusions])
        puts "      path: #{path.join(', ')}"
        if !path or path.empty?
          $stderr.puts "*   No path from #{self} to #{destination}"
        else
          dests = my_destinations
          puts "      dests: #{dests.size}: #{dests.join(', ')}"
          new_dest = path.pop
          while new_dest and not dests.include?(new_dest)
            new_dest = path.pop
          end
        end

        if new_dest.nil?
          $stderr.puts "*   Can't move #{self} to #{destination}"
        else
          o = new_dest.unit
          if o and allied_with?(o)
            # Can't move through allied units
            options[:exclusions] << new_dest
            return move_to(destination, options)
          else
            x = new_dest.x
            y = new_dest.y
            new_hex = new_dest
            command << "<move x='#{x}' y='#{y}'/>"
            done = true
          end
        end
      end

      target = nil
      also_attack = options[:also_attack]
      if also_attack
        enemies = my_targets(new_hex)
        if not enemies.empty?
          case also_attack
          when Array
            preferred = also_attack & enemies
          else
            preferred = [also_attack] & enemies
          end
          target = preferred.sort_by{|u| u.hp}.first

          if target
            $stderr.puts "*   Attack: #{self} => #{destination}"
            command << "<attack x='#{target.x}' y='#{target.y}'/>"
            done = true
          end
        end
      end

      if(
        not options[:no_capture] and
        can_capture? and
        new_hex == destination and
        new_hex.capturable?
        )
        puts "    capture: #{self} => #{new_hex}"
        command << "<capture/>"
        done = true
      end

      if not command.empty?
        result = send(command)
        puts "     moved #{self} to #{new_hex}"
        @hex.unit = nil
        new_hex.unit = self
        @hex = new_hex
        if target
          #<attack target='[3,4]' damageReceived='2' damageInflicted='7' remainingQuantity='8' />
          process_attack(result)
          @game.last_attacked = target
        end

        # Success
        return done
      end
    end
    alias move move_to

    # This is an internal method used to update the Unit attributes after a
    # command is sent to the weewar server.  You should not call this yourself.
    def process_attack(xml_text)
      puts "process_attack"
      xml = XmlSimple.xml_in(xml_text, { 'ForceArray' => false })['attack']
      #Utils.log_debug("process_attack xml: "+xml.inspect)
      #Utils.log_debug("process_attack xml_text: "+xml_text.inspect)
      if !xml or !xml['target']
        puts "process_attack has no xml or no target properties. xml=#{xml_text}"
        return
      end
      if xml['target'] =~ /\[(\d+),(\d+)\]/
        x, y = $1, $2
        enemy = @game.map.hex(x, y).unit
      end

      if enemy.nil?
        raise "Server says enemy attacked was at (#{x},#{y}), but we have no record of an enemy there."
      end

      damage_inflicted = xml['damageInflicted'].to_i
      enemy.hp -= damage_inflicted

      damage_received = xml['damageReceived'].to_i
      @hp = xml['remainingQuantity'].to_i

      puts "    #{self} (-#{damage_received}: #{@hp}) ATTACKED #{enemy} (-#{damage_inflicted}: #{enemy.hp})"
    end

    # Commands this Unit to attack another Unit.  This Unit will not move
    # anywhere in the attempt to attack.
    # Provide either a Unit or a Hex to attack as a method argument.
    #   my_unit.attack enemy_unit
    def attack(unit)
      x = unit.x
      y = unit.y

      result = send "<attack x='#{x}' y='#{y}'/>"
      process_attack result
      @game.last_attacked = @game.map.hex(x, y).unit
      true
    end

    def nearest(units, exclusions=[])
      d = INFINITY
      nearest = nil
      units.each { |u|
        nd = shortest_path(u, exclusions-[u]).size
        if nd < d
          d = nd
          nearest = u
        end
        }
      nearest
    end

    # Commands the Unit to undergo repairs.
    #   my_hurt_unit.repair
    def repair
      send "<repair/>"
      @hp += REPAIR_RATE[@type]
    end

    def defense_strength
      raise "#{@type} has no defense strength" if !DEFENSE_STRENGTH[@type]
      DEFENSE_STRENGTH[@type]
    end

    def nb_moves
      raise "#{@type} has no mobility" if !MOBILITY[@type]
      MOBILITY[@type].size
    end

    def mobility(time)
      raise "mobility error. unit #{self} can move #{nb_move} time(s) but call for #{time} time(s)" if time > nb_moves or time < 1
      MOBILITY[@type][time-1]
    end
    alias speed mobility

    def cost
      UNIT_COSTS[@type]
    end

    def attack_strength(kind)
      raise "#{@type} has no attack strength at all" if !ATTACK_STRENGTH[@type]
      raise "#{@type} has no attack strength for #{kind}" if !ATTACK_STRENGTH[@type][kind]
      ATTACK_STRENGTH[@type][kind]
    end

    def attack_range
      raise "#{@type} has no attack range" if !ATTACK_RANGE[@type]
      ATTACK_RANGE[@type]
    end

    def surrounded?(nb)
      self.hex.surrounded?(nb)
    end

=begin
    How battles are calculated

    If a unit attacks another unit the outcome is determined by the following:
    The number of sub units, ranging from 1 - 10.
    The individual attack (A) and defense (D) strength of both units involved.
    The terrain each unit is sitting on during the attack (Ta and Td).
    Gang up bonus

    If a unit is attacked multiple times during the same turn attackers receive an additional bonus (B) as follows:
    + 1 for each previous attack from a distance (e.g. by an artillery).
    + 1 for each previous attack from a hex adjacent to the attacker and the defender.
    + 3 for each previous attack from a hex on the opposite side of the defender.
    + 2 for each previous attack from any other hex adjacent to the defender.
    The math

    p = 0.05 * (((A + Ta) - (D + Td))+B) + 0.5
    if p < 0 set p to 0
    if p > 1 set p to 1
    For each sub unit of the attacker six random numbers (r) between 0 and 1 are generated. For each r < p a hit is counted. The total number of hits divided by 6 is the number of sub units the opponent loses during the attack.
    Attacker and defender then switch roles and the process starts over. Please note: Losses will only be removed when the battle is over. They will not affect the calculations of the current attack.
=end

    def battle_outcome(enemy)
      win_probability(enemy) - enemy.win_probability(self)
    end

    def win_probability(enemy)
      tag(0.05 * (((attack_strength(enemy.unit_class) + attack_effect) - (enemy.defense_strength + enemy.defense_effect))+attack_bonus) + 0.5) { |p|
        p = 0 if p < 0
        p = 1 if p > 1
        }
    end

    def attack_effect
      raise "no terrain_specs for #{@hex.type}" if !Hex.terrain_specs[@hex.type]
      raise "no attack specs for #{unit_class}" if !Hex.terrain_specs[@hex.type][:attack][unit_class]
      Hex.terrain_specs[@hex.type][:attack][unit_class]
    end

    def defense_effect
      raise "no terrain_specs for #{@hex.type}" if !Hex.terrain_specs[@hex.type]
      raise "no defense specs for #{unit_class}" if !Hex.terrain_specs[@hex.type][:defense][unit_class]
      Hex.terrain_specs[@hex.type][:defense][unit_class]
    end

    # TODO
    def attack_bonus
      0
    end

  end
end

