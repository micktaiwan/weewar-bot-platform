require File.dirname(__FILE__) + '/../game'

describe "Game State" do

  before(:all) do
    @g       = Weewar::Game.new(0, {:local_game=>true})
    @g.data  = File.open(File.dirname(__FILE__) + '/game_finished.xml','r').read
  end

  it "should parse the xml correctly for a finished game" do
    @g['name'].should eq("Arthur")
    @g['state'].should eq("finished")
  end

end

