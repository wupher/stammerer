require "rubygems"
require "tel_huawei"
require "json"
require "yaml"
require "MA5616"

options = YAML::load(File.open(File.dirname(__FILE__)+'/device_configurations' + '/MA5680T.yaml'))
def tel_board_info(slot=0,opt=nil)
  telnet_table_cmd("display board #{slot}",opt).to_json
end

def tel_gpon_port_performance(frameid=0,slot=1,port=1,opt=nil)
  telnet_pair_cmd("display gpon statistics ethernet #{frameid}/#{slot} #{port}",opt).to_json
end
print tel_gpon_port_performance(0,1,1,options)