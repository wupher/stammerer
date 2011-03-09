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

port_info = adsl_port_info

p port_info["pair"]

