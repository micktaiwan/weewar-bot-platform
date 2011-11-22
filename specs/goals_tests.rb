require File.dirname(__FILE__) + '/../lib/goal'

class MyClass

  def initialize
    @some_value = 2
  end

  def set_action(goal)
    goal.set_action(method(:test_action))
  end

  def test_action
    @some_value
  end

end

describe "Goal" do

  before(:all) do
    @goal   = Weewar::Goal.new(:test)
    @plan   = Weewar::Plan.new
    @plan  << @goal
    @test   = MyClass.new
    @test.set_action(@goal)
  end

  it "init" do
    @goal.run.should eq(2)
    @plan[0].should eq(@goal)
  end

end

