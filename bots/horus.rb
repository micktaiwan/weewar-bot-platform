require File.dirname(__FILE__) + '/../lib/goal'
require File.dirname(__FILE__) + '/../lib/goal_dsl'

module Weewar

  class Horus < Bot

    include GoalDSL

    def initialize(account, game_id)
      raise "no account" if !account
      super(account, game_id)
      define_generic_goals
    end

    def take_turn
      puts "  Taking turn for game #{game.id}"
      send_commands(run_goals(sort_goals))
      puts "  Ending turn for game #{game.id}"
      #@game.finish_turn
    end

    def sort_goals
      [:take_neutral_base]
    end

    def run_goals(goals)
      @commands = []
      goals.each { |g|
        @commands << @plan.run(g)
        }
      @commands
    end

    def send_commands(commands)
      print "commands:"
      p commands
    end

    def define_generic_goals
      reset_goals

      goal :take_neutral_base
      precond :a_capturer_is_available?, :build_a_capturer, :neutral_base
      action { |b| "taking #{b.inspect}" }

      goal :build_a_capturer
      precond :a_base_is_available?, nil
      precond :enough_credit_for?, nil
      action { |for_base| build_a_capturer(for_base) }

    end

    def enough_credit_for?(unit=:linf)
      @i.credit >= UNIT_COST[unit]
    end

    def a_capturer_is_available?
      #return false
      @game.my_capturers.size > 0
    end

    def a_base_is_available?
      @game.my_free_bases.size > 0
    end

    def take_neutral_base
      "taking #{neutral_base}"
    end

    # find nearest neutral base
    def neutral_base
      "my neutral base"
    end

    def build_a_capturer(for_base)
      return "building a capturer for base #{for_base}"
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

