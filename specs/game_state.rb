require File.dirname(__FILE__) + '/../game_state'


describe "Game State" do
  before(:all) do
    @gs = GameState.new
    XML = File.open(File.dirname(__FILE__) + '/game_state_finished.xml','r').read
  end

  it "should parse the xml correctly for a finished game" do
    @gs.parse(XML)
    @gs.name.should eq("Arthur")
    @gs.state.should eq("finished")
  end

end

