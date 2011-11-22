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

    def run(goal)
      find_goal(goal).run
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
      @name     = name.to_sym
      @preconds = []
    end

    # if a precondition is not satified, the goal can not be done
    # if a precondition subgoal can be done, then the goal is in progress
    def add_precond(condition, subgoal)
      @preconds << Precond.new(condition, subgoal)
    end

    def set_action(action)
      @action = action
    end

    def run
      run_preconds << run_action
    end

    def run_action
      #puts "#{@name}: running action"
      raise "no action for #{@name}" if @action.nil?
      @action.call
    end

    # return commands for each precond
    def run_preconds
      actions = []
      @preconds.each { |p|
        rv = p.condition.call
        actions << @plan.find_goal(p.subgoal).run if !rv # the precond fails
        }
      actions
    end

  end

  class Precond
    attr_reader :subgoal, :condition
    def initialize(condition, subgoal)
      @condition  = condition
      @subgoal    = subgoal
    end
  end

end

