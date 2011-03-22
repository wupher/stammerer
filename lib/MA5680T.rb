require "rubygems"
require File.dirname(__FILE__)+"/Telnetable"
require File.dirname(__FILE__)+"/MA5616"
require "json"
require "yaml"
require "MA5616"

class MA5680T < MA5616
  def tel_board_info(slot=0)
    telnet_table_cmd("display board #{slot}").to_json
  end

  def tel_gpon_port_performance(frameid=0,slot=1,port=1)
    telnet_pair_cmd("display gpon statistics ethernet #{frameid}/#{slot} #{port}").to_json
  end
end

device_config = YAML::load(File.open(File.dirname(__FILE__)+'/device_configurations' + '/MA5680T.yaml'))
ma5680 = MA5680T.new(device_config)
print ma5680.tel_gpon_port_performance
