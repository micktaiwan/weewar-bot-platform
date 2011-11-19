require 'game'

module Weewar

  #this part of the class will analyse a state of a game (which is a Game instance in itself)
  class Bot

    def analyse(state)
      @state = state
      factions = @state.factions
      my_units = @state.my_faction.units

      puts "There are #{factions.size} factions"
      factions.each do |f|
        puts "- #{f}: #{f.units.size} units"
      end
      puts "I have #{my_units.size} units"
      my_units.each do |unit|
        puts "- #{unit}"
      end
      puts "my board score is #{board_score}"
    end

    # calculate my faction units score againts other factions
    # score = my units points - others_factions_points.max
    # if I have one linf against 2 linf:
    # 1 - 2 = -1
    def board_score
      "not done"
      #my_points = @state.my_faction.unit_points
      #my_points - others_factions_points.max
    end

    def others_factions_points
      #@state.factions.each { |f|
      #Utils.credentials[:login]
    end

  end

end

