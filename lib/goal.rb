module Weewar

  # array of goals
  class Plan
    def initialize
      reset
    end

    def reset
      @goals = Array.new
    end

    def <<(goal)
      goal.plan = self
      @goals << goal
    end

    def [](index)
      @goals[index]
    end

    def run(goal, args=[])
      find_goal(goal).run(args)
    end

    def find_goal(name)
      g = nil
      @goals.find{|g| g.name==name}
      raise "no goal '#{name}'" if !g
      g
    end
  end

  # a goal returns a set of server commands to archieve a goal
  class Goal

    attr_accessor :plan
    attr_reader   :name

    def initialize(name)
      @name         = name.to_sym
      @preconds     = []
    end

    # if a precondition is not satified, the goal can not be done
    # if a precondition subgoal can be done, then the goal is in progress
    def add_precond(condition, subgoal, args)
      @preconds << Precond.new(condition, subgoal, args)
    end

    def set_action(action)
      @action = action
    end

    def run(args)
      p = run_preconds
      return run_action(args) if p.size == 0
      { run_action(args) =>  p}
    end

    def run_action(args)
      raise "no action for #{@name}" if @action.nil?
      @action.call(args.map{|a| a.call} )
    end

    # return commands for each precond
    def run_preconds
      actions = []
      @preconds.each { |p|
        actions << @plan.find_goal(p.subgoal).run(p.subgoal_args) if !p.condition or !p.condition.call # the precond fails
        }
      actions
    end

  end

  class Precond
    attr_reader :subgoal, :condition, :subgoal_args
    def initialize(condition, subgoal, args)
      @condition    = condition
      @subgoal      = subgoal
      @subgoal_args = args
    end
  end

end

