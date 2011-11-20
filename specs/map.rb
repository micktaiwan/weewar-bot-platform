require File.dirname(__FILE__) + '/../lib/map'

describe "Map" do
  before(:all) do
    Utils.init
    @m      = Weewar::Map.new(2, {:local_game=>true})
    @m.data = File.open(File.dirname(__FILE__) + '/../maps/map_2.xml','r').read
  end

  it "should parse the xml correctly for a map" do
    @m['name'].should eq("Botanic Troubles")
    @m['width'].should eq("20")
    @m['height'].should eq("19")
  end

end

