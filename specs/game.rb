require File.dirname(__FILE__) + '/../lib/weewar'


describe "Game State" do

  before(:all) do
    @w = Weewar::Weewar.new
    @b = @w.dummy_bot
    @g = @b.game
    @g.set_data(File.open(File.dirname(__FILE__) + "/../specs/game_finished.xml",'r').read)
    #options = Hash.new
    #options[:local_game] = true
    #options[:data] = File.open(File.dirname(__FILE__) + "/../specs/game_finished.xml",'r').read
  end

  it "should parse the xml correctly for a finished game" do
    @g['name'].should eq("Arthur")
    @g['state'].should eq("finished")
  end

end

