require "rubygems"
require "net/telnet"
require File.dirname(__FILE__)+"/retrieve_helper"

module Telnetable
  def skeleton_command(cmd, command_options)
    raise ArgumentError, "cmd cannot be nil or empty" if cmd.nil? or cmd.empty?
    
    telnet = Net::Telnet.new("Host" => @host, "Port" => @port, "Prompt" => Regexp.new(@prompt), 
    "Output_log" => File.dirname(__FILE__)+'/../logs/telnet_onu.log')
    
    telnet.cmd("\n")
    telnet.cmd(@user_name)
    telnet.cmd(@password)
    

    
    telnet.cmd('scroll 512')
    prepare_cmd_options(telnet, command_options)
    
    cmd_result = []
    yield telnet, cmd_result
    cmd_result
  end
  
  def prepare_cmd_options(telnet, command_options={})
    enable_mode = true
    command_options = {} if command_options.nil?
    config_mode |= command_options[:config_mode] | command_options[:adsl_mode] | command_options[:h248_mode]

    adsl_mode |= command_options[:adsl_mode]
    adsl_board_frameid = command_options[:adsl_board_frameid]
    adsl_board_slotid = command_options[:adsl_board_slotid]
    raise ArgumentError, "Please specify adsl frameid & slotid to initialize adsl command mode" if adsl_board_frameid.nil? & adsl_board_slotid.nil? & adsl_mode
    
    h248_mode |= command_options[:h248_mode]
    h248_mgid = command_options[:mgid]
    raise ArgumentError, "Please specify h248 mgid" if h248_mode & h248_mgid.nil?
    
    gponnni_port = command_options[:gponnni_port]

    telnet.cmd('enable') if enable_mode
    telnet.cmd('config') if config_mode
    telnet.cmd("interface adsl #{adsl_board_frameid}/#{adsl_board_slotid}") if adsl_mode
    telnet.cmd("interface h248 #{h248_mgid}") if h248_mode
    telnet.cmd("interface gponnni #{gponnni_port}") if gponnni_port
  end
  
  def telnet_pair_cmd(cmd, cmd_options=nil)
    array_type_result = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){ |ret| tmp = retrieve_pair_info(ret); cmd_result << tmp unless tmp.empty? }
    end
    hash_type_result = {}
    array_type_result.each{ |x| hash_type_result.update(x)  }
    {"pair" => hash_type_result}
  end
  
  def telnet_table_cmd(cmd, cmd_options=nil)
    skeleton_command(cmd,cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){ |ret| cmd_result << ret.split(' ') if ret.split(' ').length > 2 }
    end
  end
  
  def telnet_multi_type(cmd, cmd_options=nil)
    the_result = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){|ret| cmd_result << ret}
    end
    the_result.delete_if {|x| x.length < 10  }
    the_result.each{ |x| x.delete!("-")  }
    final_result = ""
    the_result.each do |arr|
      final_result<<arr
    end
    result = {}
    pair_content, table_content = [], []
    final_result.split("\n").each do |line|
      next if line.strip.empty?
      if line.index(':')
        pair_content <<  retrieve_pair_info(line)
      else
        table_content << line.split(/\s{2}/).delete_if{|str|str.empty?}
      end
    end
    result['pair'] = pair_content
    result['table'] = table_content
    result
  end
  
  def telnet_multi_row(cmd, cmd_options=nil)
    the_result = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
       telnet.cmd(cmd){ |ret| cmd_result << ret}
     end
     the_result.delete_if{ |x| x.length < 10  }
     the_result.each{ |x| x.delete("-") }
     final_result = ""
     the_result.each{ |arr| final_result << arr }
     result = {}
     pair_content, line_content = {}, []
     final_result.split("\n").each do |line|
      next if line.strip.empty? or line =~ /-{20}/
      if line.index(':')
        pair_content.update retrieve_pair_info(line) unless line.count(':') > 1
        pair_content.update retrieve_multi_pair(line) if line.count(':') > 1
      else
        line_content << line.strip
      end
     end
     result['pair'] = pair_content
     result['line'] = line_content
     result
  end
  
  def telnet_return_pair(cmd, cmd_options=nil)
    the_result = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){ |ret| cmd_result << ret  }
    end
    the_result.delete_if{ |x| x.length < 2}
    the_result.each{ |x| x.strip!}
    the_result.delete_if{ |x| x =~ /-{10}/  }
    result={}
    0.upto(the_result.size-1) do |i|
      line = the_result[i]
      next_line = the_result[i+1]
      result[line] = next_line if line =~ /:/
    end
    result
  end
end
