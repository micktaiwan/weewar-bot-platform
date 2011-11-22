require File.dirname(__FILE__) + '/../lib/goal'
require File.dirname(__FILE__) + '/../lib/goal_dsl'

module Weewar

  class Horus < Bot

    include GoalDSL

    def initialize(account, game_id)
      super(account, game_id)
      define_generic_goals
    end

    def take_turn
      puts "  Taking turn for game #{game.id}"
      sort_goals
      run_goals
      send_commands
      puts "  Ending turn for game #{game.id}"
      #@game.finish_turn
    end

    def sort_goals
    end

    def run_goals
      @commands = @plan.run
    end

    def send_commands
    end

    def define_generic_goals
      reset_goals

      goal :take_neutral_base do
        precond a_capturer_is_available?, :build_a_capturer, neutral_base
      end

      goal :build_a_capturer do
        precond a_base_is_available?
        precond enough_credit_for?(:linf)

        # find nearest neutral base
        action do
          for_base = my_base
          build_a_capturer(for_base)
        end
      end

    end

    def enough_credit_for?(unit)
      @i.credit >= UNIT_COST[unit]
    end

    def a_capturer_is_available?
      @game.my_capturers.size > 0
    end

    def a_base_is_available?
      @game.my_free_bases.size > 0
    end

    def build_a_capturer(for_base)
      base = for_base.nearest(free_bases)
      if @i.credits > 1000
        unit = :hover
      else # assume we have some credits (a precond exists for that)
        unit = :linf
      end
      base.build(unit) # TODO: refresh credits
    end

  end

end

