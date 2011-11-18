require File.dirname(__FILE__) + '/../map'

describe "Map" do
  before(:all) do
    @m      = Weewar::Map.new(nil)
    @m.data = File.open(File.dirname(__FILE__) + '/../maps/map_2.xml','r').read
  end

  it "should parse the xml correctly for a map" do
    @m['name'].should eq("Botanic Troubles")
    @m['width'].should eq("20")
    @m['height'].should eq("19")
  end

end

