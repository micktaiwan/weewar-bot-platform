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
      r = Utils.get(@account, "#{@method}/#{@id}")
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

end

