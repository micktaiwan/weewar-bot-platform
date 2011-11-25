module Weewar

  class Unit
    # An Array of the Hex es which the given Unit can move to in the current turn.
    #   possible_moves = my_unit.destinations
    # TODO: replace that. do not call the server.
    #def destinations
    #  xml = XmlSimple.xml_in(@game.send("<movementOptions x='#{x}' y='#{y}' type='#{TYPE_FOR_SYMBOL[@type]}'/>"))
    #  coords = xml['coordinate']
    #  if !coords
    #    puts "no coords for #{self}. xml=#{xml}"
    #    return []
    #  end
    #  coords.map { |c| @game.map.hex(c['x'], c['y']) }
    #end
    #alias movement_options destinations
    #alias movementOptions destinations

    # version without calls to server
    def my_destinations(from=nil, cc=0, possibles=nil)#, cost=nil)
      # starting hex
      from ||= self.hex
      raise "no hex ?" if !from
      # path cost from self. algorith stops when current_cost > unit movement capacity
      current_cost = cc
      # every possible destination in one move
      possibles ||= []
      # all costs to go to hexes
      #cost ||= Hash.new
      # take neighbourgs hex, check the path cost, add them to possibles hexes, recurse
      new_h = Array.new
      mob = mobility(1)
      from.neighbours.each { |h|
        ec = entrance_cost(h)
        next if h.occupied? or h == self.hex or possibles.include?(h) or current_cost+ec > mob # not already calculated # not too far
        possibles << h
        new_h << h
        #cost[h] = current_cost+ec
        }
      # recurse
      new_h.each { |h|
        possibles = my_destinations(h, current_cost+entrance_cost(h), possibles)#, cost)
        }
      possibles
    end

    #-- ----------------------------------------------
    # Travel
    #++

    # The cost in movement points for the unit to enter the given Hex.  This
    # is an internal method used for travel-related calculations; you should not
    # normally need to use this yourself.
    def entrance_cost(hex)
      raise "hex is nil" if hex.nil?
      raise "hex.type is nil" if hex.type.nil?

      specs_for_type = Hex.terrain_specs[hex.type]
      raise "**  No spec for type '#{hex.type}' hex: #{hex}" if specs_for_type.nil?
      tag(specs_for_type[:movement][unit_class]) { |rv|
        raise "no movement spec for #{unit_class}" if !rv
        }
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
      #puts "shortest_path"
      return my_shortest_path(dest, exclusions)

      exclusions ||= []
      previous = shortest_paths(exclusions)
      u = dest.hex
      s = []
      while previous[u]
        s.unshift u
        u = previous[u]
      end
      return nil if s.empty?
      s
    end

    def my_shortest_path(goal, closedset = [])
      time = Time.now
      closedset ||= Array.new # The set of nodes already evaluated.
      openset   = [@hex]    # The set of tentative nodes to be evaluated, initially containing the start node
      came_from = Hash.new # The map of navigated nodes.
      g_score   = Hash.new
      h_score   = Hash.new
      f_score   = Hash.new

      g_score[@hex] = 0     # Cost from start along best known path.
      h_score[@hex] = heuristic_cost_estimate(@hex, goal)
      f_score[@hex] = g_score[@hex] + h_score[@hex]  # Estimated total cost from start to goal through y.

      while not openset.empty?
        x = openset.sort_by{ |x| f_score[x]}.first # the node in openset having the lowest f_score[] value
        #return reconstruct_path(came_from, goal) if x == goal
        if x == goal
          path =  reconstruct_path(came_from, goal)
          puts "time: #{Time.now-time}. path size: #{path.size}"
          return path
        end

        openset.delete(x)
        closedset.push(x)
        #x.value = "X "
        #x.map.print_map

        for y in x.neighbours
          next if closedset.include?(y)
          tentative_g_score = g_score[x] + dist_between(x,y)
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
            h_score[y]    = heuristic_cost_estimate(y, goal)
            f_score[y]    = g_score[y] + h_score[y]
          end
        end
      end
      puts "time: #{Time.now-time}. no path"
      nil
    end

    # Math distance (not path related)
    def dist_between(a,b)
      dx = b.x - a.x
      dy = b.y - a.y
      if (sign(dx) == sign(dy))
        dist = [dx.abs, dy.abs].max
      else
        dist = dx.abs + dy.abs
      end
    end

    def sign(a)
      return :minus if a < 0
      return :plus
    end

    def reconstruct_path(came_from, current_node)
      if came_from[current_node]
        p = reconstruct_path(came_from, came_from[current_node])
        return (p + [current_node])
      else
        return [current_node]
      end
    end

    def heuristic_cost_estimate(x,y)
      dist_between(x,y) + entrance_cost(x)
    end


=begin
 function A*(start,goal)
     closedset := the empty set    // The set of nodes already evaluated.
     openset := {start}    // The set of tentative nodes to be evaluated, initially containing the start node
     came_from := the empty map    // The map of navigated nodes.

     g_score[start] := 0    // Cost from start along best known path.
     h_score[start] := heuristic_cost_estimate(start, goal)
     f_score[start] := g_score[start] + h_score[start]    // Estimated total cost from start to goal through y.

     while openset is not empty
         x := the node in openset having the lowest f_score[] value
         if x = goal
             return reconstruct_path(came_from, came_from[goal])

         remove x from openset
         add x to closedset
         foreach y in neighbor_nodes(x)
             if y in closedset
                 continue
             tentative_g_score := g_score[x] + dist_between(x,y)

             if y not in openset
                 add y to openset
                 tentative_is_better := true
             else if tentative_g_score < g_score[y]
                 tentative_is_better := true
             else
                 tentative_is_better := false

             if tentative_is_better = true
                 came_from[y] := x
                 g_score[y] := tentative_g_score
                 h_score[y] := heuristic_cost_estimate(y, goal)
                 f_score[y] := g_score[y] + h_score[y]

     return failure

 function reconstruct_path(came_from, current_node)
     if came_from[current_node] is set
         p := reconstruct_path(came_from, came_from[current_node])
         return (p + current_node)
     else
         return current_node
=end


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

