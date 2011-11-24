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
      raise "hex.type is nil" if hex.nil?

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
      exclusions ||= []
      previous = shortest_paths(exclusions)
      u = dest.hex
      tag([]) { |s|
        while previous[u]
          s.unshift u
          u = previous[u]
        end
        }
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
        next if exclusions.include? h
        dist[h] = INFINITY
        q << h
      end
      dist[source] = 0

      # Work
      while not q.empty?
        u = q.inject { |best,h| dist[h] < dist[best] ? h : best }
        q.delete u
        @game.map.hex_neighbours(u).each do |h|
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

