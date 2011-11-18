require 'logger'
require 'rubygems'
require 'xmlsimple'

class Object

  # do what "returning" do in Rails, handy!
  def tag(value)
    yield(value)
    value
  end
end

class XmlData

  attr_reader :data, :method, :id

  def initialize(options={})
    get if options[:get]
  end

  # @return [Hash] Hash representing the data
  def get
    r = Utils.get("#{@method}/#{@id}")
    raise "Could not get data: #{r.message}" if(r.code!="200")
    @data = Utils.xmls(r.body)
  end

  def data=(xml)
    @data = Utils.xmls(xml)
  end

  def [](attr)
    @data[attr.to_s]
  end

end

module Utils

  # the global logguer
  @log      = Logger.new('log.txt')

  # set your developper key in the file ./key.txt
  arr = File.open('./key.txt','r').read.split(':')
  @credentials = {:login=>arr[0].strip, :key=>arr[1].strip}

  BASEURL = 'weewar.com'

  def self.credentials
    @credentials
  end

  def self.log_debug(msg)
    @log.debug(msg)
  end

  #  @return [HTTPResponse]
  def self.get(method)
    @log.debug method
    Net::HTTP.start(BASEURL) do |http|
      req = Net::HTTP::Get.new("/api1/#{method}")
      req.basic_auth(@credentials[:login], @credentials[:key])
      tag(http.request(req)) { |r| # returns a response (check response.code before reading response.body)
        @log.debug "[#{r.code},#{r.body}]"
        }
    end
  end

  def self.xmls(xml, options={})
    options['ForceArray'] = options['ForceArray'] || false
    XmlSimple.xml_in(xml, options)
  end
end

