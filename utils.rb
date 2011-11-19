require 'net/http'
require 'logger'
require 'rubygems'
require 'xmlsimple'
require 'hex'

class Object

  # do what "returning" do in Rails, handy!
  def tag(value)
    yield(value)
    value
  end
end

module Weewar

  class XmlData

    attr_reader :data, :method, :id

    def initialize(options={}, get_options={})
      if options[:get]
        get(get_options)
      else
        @data = Utils.xmls(options[:data], get_options)
      end
    end

    # @return [Hash] Hash representing the data
    def get(options)
      r = Utils.get("#{@method}/#{@id}")
      raise "Could not get data: #{r.message}" if(r.code!="200")
      @data = Utils.xmls(r.body, options)
    end

    #def data=(xml, options)
    #  @data = Utils.xmls(xml, options)
    #end

    def [](attr)
      @data[attr.to_s]
    end

  end

  module Utils

    BASEURL = 'weewar.com'

    # to call once
    def self.init
      # the global logguer
      @log      = Logger.new('log.txt')

      # set your login / developper key in the file ./accounts.txt
      @credentials = []
      File.open('./accounts.txt','r').each_line { |line|
        arr = line.split(':')
        @credentials << {:name=>arr[0].strip,:login=>arr[1].strip, :key=>arr[2].strip}
        }
      @cred_index = 0
      Hex.initialize_specs
    end

    # TODO: some switching account function
    def self.credentials
      @credentials[@cred_index]
    end

    def self.log_debug(msg)
      @log.debug(msg)
    end

    #  @return [HTTPResponse]
    def self.get(method)
      @log.debug method
      Net::HTTP.start(BASEURL) do |http|
        req = Net::HTTP::Get.new("/api1/#{method}")
        req.basic_auth(self.credentials[:login], self.credentials[:key])
        tag(http.request(req)) { |r| # returns a response (check response.code before reading response.body)
          @log.debug "[#{r.code},#{r.body}]"
          }
      end
    end

    def self.raw_send(xml)
      url = URI.parse( "http://#{BASEURL}/api1/eliza" )
      req = Net::HTTP::Post.new( url.path )
      #req.read_timeout = 500
      req.basic_auth(self.credentials[:login], self.credentials[:key])
      req['Content-Type'] = 'application/xml'
      result = Net::HTTP.new(url.host, url.port).start { |http|
        @log.debug "XML SEND: #{xml}"
        http.request(req, xml)
        }.body
      @log.debug "XML RECEIVE: #{result}"
      result
    end

    def self.xmls(xml, options={})
      options['ForceArray'] = options['ForceArray'] || false
      XmlSimple.xml_in(xml, options)
    end
  end # module Utils
end # module Weewar

