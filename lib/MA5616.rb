require "rubygems"
require File.dirname(__FILE__)+"/Telnetable"
require "json"
require "yaml"

class MA5616
  include Telnetable
  
  def initialize(config)
    @host = config['host']
    @port = config['port']
    @prompt = config['prompt']
    @user_name = config['username']
    @password = config['password'] 
  end
  
  def method_missing(id, *args, &block)
    case(id.to_s)    
    when /_to_json$/
      send((id.to_s.split('_to_json'))[0], *args, &block).to_json
    else
      super
    end
  end
  
  def tel_board_info(slot=0)
    telnet_table_cmd("display board #{slot}")
  end

  def tel_pon_sn()
    telnet_pair_cmd('display pon sn')
  end

  def tel_version_info(frame=0, slot=0)
    telnet_pair_cmd("display version #{frame}/#{slot}")
  end

  def tel_adsl_board_info(frame=0, slot=4)
    telnet_multi_type("display board #{frame}/#{slot}")
  end

  def tel_pstn_board_info(frame=0, slot=4)
    adsl_board_info(frame, slot).to_json
  end

  def tel_adsl_port_info(frameid=0, slot=4, port=0)
     telnet_multi_row("display interface adsl #{frameid}/#{slot}/#{port}")
  end

  def tel_system_info()
    telnet_return_pair('display system sys-info')
  end

  def tel_last_10_minutes_mem_occupancy()
    telnet_pair_cmd('display resource occupancy mem')
  end

  def tel_last_10_minutes_cpu_occupancy()
    telnet_pair_cmd('display resource occupancy cpu')
  end

  def tel_current_cpu_usage()
    telnet_pair_cmd('display cpu 0/0')
  end

  def tel_current_mem_usage()
    telnet_pair_cmd('display mem 0/0')
  end

  def tel_adsl_port_parameters(frame=0, slot=4, port=0)
    cmd_options = {:adsl_mode => true, :adsl_board_frameid => frame, :adsl_board_slotid => slot}
    telnet_multi_row("display parameter #{port}",cmd_options)
  end

  def tel_adsl_port_performance(frame=0, slot=4, port=0)
    cmd_options = {:adsl_mode => true, :adsl_board_frameid => frame, :adsl_board_slotid  => slot}
    telnet_section_pari_cmd("display statistics performance #{port} current-15minutes", cmd_options, "ATU-C","ATU-R")
  end


  def tel_onu_port_info(frame=0, slot=0, port=1)
    #测试结果需要过滤命令
    cmd_options = {:gponnni_mode => true, :gponnni_port => "#{frame}/#{slot}/#{port}"}
    telnet_multi_type("display onu info", cmd_options)
  end
  
  def tel_display_mac_address(frame=0, slot=1)
    telnet_table_cmd("display mac-address board #{frame}/#{slot}")
  end
  
  def tel_display_port_mac_address(frame=0, slot=1, port=4)
    output = telnet_table_cmd("display mac-address port #{frame}/#{slot}/#{port}")
    if output[1] == ["INDEX","TYPE","PARA"]
      output[0] = ["SRV-P INDEX", "TYPE", "MAC", "MAC TYPE", "FRAME", "SLOT", "PORT", "VPI", "VCI", "FLOW TYPE",
         "FLOW PARA", "VLANID"]
      output.delete_at 1
    end
    output
  end
  
  def tel_active_alarm()
    telnet_multi_row_table_cmd("display alarm active all list")
  end
  
  def tel_ping_test(ip="10.90.100.2")
    output = telnet_plain_text("ping #{ip}")
    result = {}
    # p output
    output.each do |line|
      result["packets_transmitted"] = line[/(\d) packet\(s\) transmitted/,1] if line =~ /packet\(s\) transmitted/
      result["packets_received"] = line[/(\d) packet\(s\) received/,1] if line=~ /packet\(s\) received/
      result["packets_loss_percentage"] = line[/(\d\.\d\d)% packet loss/,1] if line =~ /packet loss/
      if line =~ /round-trip min\/avg\/max = \d+\/\d+\/\d+ ms/
        result["round-trip_min"] = line[/(\d+)\/\d+\/\d+ ms/,1]
        result["round-trip_avg"] = line[/\d+\/(\d+)\/\d+ ms/,1]
        result["round-trip_max"] = line[/\d+\/\d+\/(\d+) ms/,1]
      end
    end
    {"pair" => result}
  end
end

ma5616_configuration = YAML::load(File.open(File.dirname(__FILE__)+"/device_configurations/MA5616.yaml"))
ma5616 = MA5616.new(ma5616_configuration['MA5616_ONLINE'])
p ma5616.tel_ping_test