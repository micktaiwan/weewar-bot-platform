require File.dirname(__FILE__) + '/../lib/utils'

module Weewar

  class Unit
    # An Array of the Hex es which the given Unit can move to in the current turn.
    #   possible_moves = my_unit.destinations
    def server_destinations
      xml = XmlSimple.xml_in(@game.send("<movementOptions x='#{x}' y='#{y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>"))
      coords = xml['coordinate']
      if !coords
        puts "no coords for #{self}. xml=#{xml}"
        return []
      end
      coords.map { |c| @game.map.hex(c['x'], c['y']) }
    end

    # version without calls to server
    def my_destinations_and_backchains(exclusions = [], from=nil)
      closedset   = exclusions.map{ |x| x} # The set of nodes already evaluated. Perform a copy of the array
      from      ||= @hex
      openset     = [from]    # The set of tentative nodes to be evaluated, initially containing the start node
      came_from   = Hash.new # The map of navigated nodes.
      cost        = Hash.new
      zoc_hash    = Unit.init_zoc_hash(@game)
      possibles   = Array.new
      cost[from]  = 0     # Cost from start along best known path.

      mob         = mobility(1)
      while not openset.empty?
        x = openset.sort_by{ |x| cost[x]}.first
        openset.delete(x)
        closedset.push(x)
        for y in x.neighbours
          next if closedset.include?(y)
          ec = entrance_cost(y, x, zoc_hash)
          next if cost[x]+ec > mob
          if not openset.include?(y)
            openset.push(y)
            came_from[y]  = x
            cost[y]       = cost[x]+ec
            possibles << y
          end
        end
      end
      [possibles, came_from]
    end

    def my_destinations(exclusions = [], from=nil)
      my_destinations_and_backchains(exclusions, from)[0]
    end

    #-- ----------------------------------------------
    # Travel
    #++

    # The cost in movement points for the unit to enter the given Hex.  This
    # is an internal method used for travel-related calculations; you should not
    # normally need to use this yourself.
    def entrance_cost(hex, from, zh)
      raise "hex is nil"      if hex.nil?
      raise "hex.type is nil" if hex.type.nil?

      specs_for_type = Hex.terrain_specs[hex.type]
      raise "**  No spec at all for type '#{hex.type}' from hex: #{hex}" if specs_for_type.nil?
      rv = specs_for_type[:movement][unit_class]
      raise "**  No movement spec for #{unit_class}" if !rv
      rv + zoc_cost(hex, from, zh)
    end

    def self.init_zoc_hash(game)
      zoc_hash = Hash.new(false)
      game.enemy_units.each{|e| e.hex.neighbours.each { |n| zoc_hash[n] = true}}
      zoc_hash
    end

    def zoc_cost(hex, from, zoc_hash)
      # if was already in zoc, can not move to hex
      return 99 if zoc_hash[from] and zoc_hash[hex]
      return 0
    end

    # The cost in movement points for the unit to travel along the given path.
    # The path given should be an Array of Hexes.  This
    # is an internal method used for travel-related calculations; you should not
    # normally need to use this yourself.
    def path_cost(path)
      return INFINITY if !path
      path.inject(0) { |sum,hex|
        sum + entrance_cost(hex)
        }
    end

    # The cost in movement points for this unit to travel to the given
    # destination.
    def travel_cost(dest)
      sp = shortest_path(dest)
      path_cost(sp)
    end

    # The shortest path (as an Array of Hexes) from the
    # Unit's current location to the given destination.
    #
    # If the optional exclusion array is provided, the path will not
    # pass through any Hex in the exclusion array.
    #
    #   best_path = my_trooper.shortest_path(enemy_base)
    def shortest_path(dest, exclusions = [])
      reconstruct_path(dest, my_shortest_path(dest, exclusions)) # shortest_paths(exclusions)
    end

    def reconstruct_path(dest, back_chain)
      return nil if !back_chain
      u = dest.hex
      s = []
      while back_chain[u]
        s.unshift u
        u = back_chain[u]
      end
      s
    end

    # A* (see wikipedia for pseudo-code)
    def my_shortest_path(goal, exclusions = [])
      time = Time.now
      closedset = exclusions.map{ |x| x} # The set of nodes already evaluated. Perform a copy of the array
      openset   = [@hex]    # The set of tentative nodes to be evaluated, initially containing the start node
      came_from = Hash.new # The map of navigated nodes.
      zoc_hash  = Unit.init_zoc_hash(@game)
      g_score   = Hash.new
      h_score   = Hash.new
      f_score   = Hash.new

      g_score[@hex] = 0     # Cost from start along best known path.
      h_score[@hex] = heuristic_cost_estimate(@hex, goal, @hex, zoc_hash)
      f_score[@hex] = g_score[@hex] + h_score[@hex]  # Estimated total cost from start to goal through y.

      while not openset.empty?
        x = openset.sort_by{ |x| f_score[x]}.first # the node in openset having the lowest f_score[] value
        #return reconstruct_path(came_from, goal) if x == goal
        if x == goal.hex
          #puts "      path time: #{Time.now-time}"
          return came_from
        end

        openset.delete(x)
        closedset.push(x)
        #x.value = ". "
        #x.map.print_map

        for y in x.neighbours
          next if closedset.include?(y)
          tentative_g_score = g_score[x] + x.dist_between(y)
          if not openset.include?(y)
            openset.push(y)
            tentative_is_better = true
          elsif tentative_g_score < g_score[y]
            tentative_is_better = true
          else
            tentative_is_better = false
          end
          if tentative_is_better
            came_from[y]  = x
            g_score[y]    = tentative_g_score
            h_score[y]    = heuristic_cost_estimate(y, goal, x, zoc_hash)
            f_score[y]    = g_score[y] + h_score[y]
          end
        end
      end
      puts "!    time: #{Time.now-time}. no path from #{self} to #{goal}"
      nil
    end

    # Math distance (not path related)
    def dist_between(b)
      self.hex.dist_between(b.hex)
    end

    #def reconstruct_path(came_from, current_node)
    #  if came_from[current_node]
    #    p = reconstruct_path(came_from, came_from[current_node])
    #    return (p + [current_node])
    #  else
    #    return [current_node]
    #  end
    #end

    def heuristic_cost_estimate(x, goal, from, zoc_hash)
      x.dist_between(goal) + entrance_cost(x, from, zoc_hash)
    end

    # Calculate all shortest paths from the Unit's current Hex to every other
    # Hex, as per Dijkstra's algorithm
    # (http://en.wikipedia.org/wiki/Dijkstra's_algorithm).
    # Most AIs will only need to make use of the shortest_path method instead.
    def shortest_paths(exclusions = [])
      # Initialization
      start = Time.now
      exclusions ||= []
      source    = hex
      dist      = Hash.new
      previous  = Hash.new
      q         = []
      @game.map.each do |h|
        raise "h is nil" if !h
        next if exclusions.include? h
        dist[h] = INFINITY
        q << h
      end
      dist[source] = 0

      # Work
      while not q.empty?
        u = q.inject { |best,h| dist[h] < dist[best] ? h : best }
        q.delete u
        u.neighbours.each do |h|
          raise "h is nil" if !h
          next if exclusions.include? h
          alt = dist[u] + entrance_cost(h)
          if alt < dist[h]
            dist[h]     = alt
            previous[h] = u
          end
        end
      end

      #puts "      #{previous.size} paths, time: #{Time.now-start}"
      # Results
      previous
    end

  end # class

end # module

