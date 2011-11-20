require File.dirname(__FILE__) + '/../lib/game'

describe "Game State" do

  before(:all) do
    Weewar::Utils.init
    options = Hash.new
    options[:local_game] = true
    options[:data] = File.open(File.dirname(__FILE__) + "/../specs/game_finished.xml",'r').read
    @g = Weewar::Game.new(0, options)
  end

  it "should parse the xml correctly for a finished game" do
    @g['name'].should eq("Arthur")
    @g['state'].should eq("finished")
  end

end

