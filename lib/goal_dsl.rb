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

    def precond(condition, subgoal_name, *args)
      if !condition # force action
        @plan[-1].add_precond(false, subgoal_name, arguments(*args))
      else
        @plan[-1].add_precond(method(condition), subgoal_name, arguments(*args))
      end
    end

    def arguments(*args)
      args.map { |a| method(a)}
    end

    def action(&block)
      @plan[-1].set_action(block)
    end

  end
end
