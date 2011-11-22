require File.dirname(__FILE__) + '/../../lib/weewar'

describe "Horus" do

  before(:all) do
    @w = Weewar::Weewar.new
    @b = @w.dummy_bot("Horus")
    @g = @b.game
    @g.set_data(File.open(File.dirname(__FILE__) + "/../../specs/game_horus.xml",'r').read)
    @g.refresh
  end

  it "init" do
    @b.take_turn
  end

end

