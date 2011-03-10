require "rubygems"
require "tel_huawei"
require "json"

def board_info(slot=0)
  return nil unless slot.is_a?(Integer)
  telnet_table_cmd("display board #{slot}").to_json
end

def pon_sn()
  telnet_pair_cmd('display pon sn').to_json
end

def version_info(frame=0, slot=0)
  telnet_pair_cmd("display version #{frame}/#{slot}").to_json
end

def adsl_board_info(frame=0, slot=4)
  telnet_multi_type("display board #{frame}/#{slot}").to_json
end

def pstn_board_info(frame=0, slot=4)
  adsl_board_info(frame, slot)
end

def adsl_port_info(frameid=0, slot=4, port=0)
  telnet_multi_row("display interface adsl #{frameid}/#{slot}/#{port}")
end

def system_info()
  #TODO: 
  telnet_pair_cmd('display sys-info')
end

def last_10_minutes_mem_occupancy()
  telnet_pair_cmd('display resource occupancy mem')
end

def last_10_minutes_cpu_occupancy()
  telnet_pair_cmd('display resource occupancy cpu')
end

def current_cpu_usage()
  telnet_pair_cmd('display cpu 0/0')
end

def current_mem_usage()
  telnet_pair_cmd('display mem 0/0')
end

def adsl_port_info(frame=0, slot=4, port=0)
  cmd_options = {:adsl_model => true, :adsl_frame => frame, :adsl_slot => slot}
  telnet_multi_row("display parameter #{port}",nil,cmd_options)
end

def adsl_port_performance(frame=0, slot=4, port=0)
  cmd_options = {:adsl_model => true, :adsl_frame => frame, :adsl_slot  => slot}
  telnet_pair_cmd("display statistics performance #{port} current-15minutes", nil, cmd_options)
end


def onu_port_info(frame=0, slot=0, port=1)
  #测试结果需要过滤命令
  cmd_options = {:gponnni_model => true, :gponnni_port => "#{frame}/#{slot}/#{port}"}
  telnet_multi_type("display onu info",nil, cmd_options)
end

p onu_port_info
