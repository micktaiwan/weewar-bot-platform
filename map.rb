require 'utils'

# = Weewar map
class Map

  attr_reader :name, :width, :height

  def initialize
    #@game_id = game_id
    #get(game_id)
  end

  # @return [string] xml representing the game map
  def get(game_id)
    response = Utils.get("api1/map/#{@game_id}")
    raise "Could not get map: #{r.message}" if(response.code!=200)
    parse(r.body)
  end

  def parse(xml)
    doc = REXML::Document.new(xml)
    @name   = doc.elements['map/name'].text
    @width  = doc.elements['map/width'].text.to_i
    @height = doc.elements['map/height'].text.to_i
    #tag([]) do |games|
    #  doc.elements.each('game/name') { |g| games << g.text.to_i }
    #end
  end

end

