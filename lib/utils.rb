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
  def deep_copy
    Marshal.load( Marshal.dump(self) )
  end
end

class String
  def sp(nb)
    self + ' '*([0,nb-self.size].max)
  end
end

module Weewar

  module Utils

    BASEURL = 'weewar.com'

    # to call once
    def self.init
      # the global logguer
      @log      = Logger.new('log.txt')
      Hex.initialize_specs
    end

    # TODO: some switching account function
    #def self.credentials
    #  @credentials[@cred_index]
    #end

    def self.log_debug(msg)
      @log.debug(msg)
    end

    #  @return [HTTPResponse]
    def self.get(account, method)
      @log.debug "getting '#{method}' for #{account.login}"
      Net::HTTP.start(BASEURL) do |http|
        req = Net::HTTP::Get.new("/api1/#{method}")
        req.basic_auth(account.login, account.key)
        tag(http.request(req)) { |r| # returns a response (check response.code before reading response.body)
          @log.debug "[#{r.code},#{r.body}]"
          }
      end
    end

    def self.raw_send(account, xml)
      url = URI.parse( "http://#{BASEURL}/api1/eliza" )
      req = Net::HTTP::Post.new(url.path)
      #req.read_timeout = 500
      req.basic_auth(account.login, account.key)
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
      #xml_options['ForceArray'] = xml_options['ForceArray'] || false
      #p xml
      #gets
      XmlSimple.xml_in(xml, xml_options)
    end

    # pretty print
    def self.pp(i)
      @pp_indent ||= 0
      if i.class.name=="Array"
        puts ' '*@pp_indent + '['
        @pp_indent += 1
        i.each_with_index { |j,index|
           print ' '*(@pp_indent-1)
           puts "##{index}"
           pp(j)
           }
        @pp_indent -= 1
        puts ' '*@pp_indent + ']'
      elsif i.class.name=="Hash"
        puts ' '*@pp_indent + '{'
        @pp_indent += 1
        i.each { |k,v| print "#{' '*@pp_indent}#{k}\t=> "
          if v.class.name=="Array" or v.class.name=="Hash"
            @pp_indent += 1
            puts
            pp(v)
            @pp_indent -= 1
          else
            puts v.to_s
          end
          }
        @pp_indent -= 1
        puts ' '*@pp_indent + '}'
      else
        puts ' '*@pp_indent + i.to_s
      end
    end

  end # module Utils
end # module Weewar

