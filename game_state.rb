require 'utils'

class GameState

  attr_reader :name, :state

  def initialize
  end

  def get(game_id)
    r = Utils.get("gamestate/#{game_id}")
    raise r.message if r.code!="200"
    parse(r.body)
  end

  def parse(xml)
    doc = REXML::Document.new(xml)
    @name     = doc.elements['game/name'].text
    @state    = doc.elements['game/state'].text
    #tag([]) do |games|
    #  doc.elements.each('game/name') { |g| games << g.text.to_i }
    #end
  end

end

