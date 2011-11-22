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
    precond nil, :take_lessons # force action
    precond :have_ingredients?, :buy_ingredients, :my_ingredient
    action {"making meal"}

    goal :buy_ingredients
    action { |args| "buying #{args.size}"}

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

  def my_ingredient
    "soup"
  end

  def run_plan(goal, *args)
    @plan.run(goal, args)
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

