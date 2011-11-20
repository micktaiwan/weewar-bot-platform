require 'net/http'
require 'logger'
require 'rubygems'
require 'xmlsimple'
require File.dirname(__FILE__) + '/hex'

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

    def initialize(xml_options={})
      @xml_options = xml_options
    end

    # @return [String] Network data
    # input: options for XmlSimple
    def get(xml_options={})
      xml_options = @xml_options if !xml_options and @xml_options
      #puts "getting data for #{self.class.name}"
      r = Utils.get("#{@method}/#{@id}")
      raise "Could not get data: #{r.message}" if(r.code!="200")
      r.body
    end

    def set_data(xml, xml_options=nil)
      xml_options = @xml_options if !xml_options and @xml_options
      @data = Utils.xmls(xml, xml_options)
    end

    def [](attr)
      raise "#{self.class.name} has no data" if !@data
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
      @log.debug "getting '#{method}'"
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

    def self.xmls(xml, xml_options={})
      xml_options = @xml_options if !xml_options and @xml_options
      xml_options['ForceArray'] = xml_options['ForceArray'] || false
      #p xml
      #gets
      XmlSimple.xml_in(xml, xml_options)
    end
  end # module Utils
end # module Weewar

