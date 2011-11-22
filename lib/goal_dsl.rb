require File.dirname(__FILE__) + '/../lib/goal'

module Weewar

  module GoalDSL

    def reset_goals
      @plan ||= Plan.new
      @plan.reset
    end

    def goal(name)
      @plan << Goal.new(name)
    end

    def precond(condition, subgoal_name)
      @plan[-1].add_precond(method(condition), subgoal_name)
    end

    def action(&block)
      @plan[-1].set_action(block)
    end

  end
end
