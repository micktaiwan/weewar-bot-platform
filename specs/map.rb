require File.dirname(__FILE__) + '/../lib/weewar'

describe "Map" do
  before(:all) do
    @w = Weewar::Weewar.new
    @b = @w.dummy_bot
    @g = @b.game
    @g.set_data(File.open(File.dirname(__FILE__) + "/../specs/game_running.xml",'r').read)
    @g.refresh
    @m = @g.map
  end

  it "should parse the xml correctly for a map" do
    @m['name'].should eq("Botanic Troubles")
    @m['width'].should eq("20")
    @m['height'].should eq("19")
  end

end

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

