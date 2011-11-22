require File.dirname(__FILE__) + '/../lib/goal_dsl'

class House

  include Weewar::GoalDSL

  def initialize
    define_goals
  end

  def define_goals
    reset_goals

    goal :eat
    precond :meal_available?, :make_meal#, best_meal
    action {"eating"}

    goal :make_meal
    precond :know_cooking?, :take_lessons
    precond :have_ingredients?, :buy_ingredients
    action {"making meal"}

    goal :buy_ingredients
    action {"buying ingredients"}

    goal :take_lessons
    action {"taking lessons"}

  end

  def meal_available?
    false
  end

  def know_cooking?
    false
  end

  def have_ingredients?
    false
  end

  def set_action(goal)
    goal.set_action(method(:test_action))
  end

  def run_plan(goal)
    @plan.run(goal)
  end

end

describe "Goal" do

  before(:all) do
    @house  = House.new
  end

  it "init" do
    @house.run_plan(:eat).should eq(["making meal", "eating"])
  end

end

