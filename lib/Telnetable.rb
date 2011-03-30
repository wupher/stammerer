require "rubygems"
require "net/telnet"
require File.dirname(__FILE__)+"/retrieve_helper"

module Telnetable
  #函数模板，负责telnet的登录，通过block来执行要在telnet上执行的操作
  def skeleton_command(cmd, command_options)
    raise ArgumentError, "cmd cannot be nil or empty" if cmd.nil? or cmd.empty?
    
    telnet = Net::Telnet.new("Host" => @host, "Port" => @port, "Prompt" => Regexp.new(@prompt), 
    "Output_log" => File.dirname(__FILE__)+'/../logs/telnet_onu.log')
    
    telnet.cmd("\n")
    telnet.cmd(@user_name)
    telnet.cmd(@password){ |output| return {:ERROR => "用户名或密码错误：\n #{@user_name}|#{@password}\n error info:#{output}"} if 
    output =~ /Username or password invalid/}
    
    telnet.cmd('scroll 512')
    prepare_cmd_options(telnet, command_options)
    
    cmd_result = []
    yield telnet, cmd_result
    cmd_result
  rescue Errno::ECONNREFUSED  => err
    return {:ERROR => "#{@host}拒绝连接：#{err}"}
  rescue Timeout::Error => err
    return {:ERROR => "操作超时：#{err}"}
  ensure
    telnet.close if telnet
  end
  
  def prepare_cmd_options(telnet, command_options={})
    enable_mode = true
    command_options = {} if command_options.nil?
    config_mode |= command_options[:config_mode] | command_options[:adsl_mode] | command_options[:h248_mode] | command_options[:gponnni_port]

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
    return array_type_result if array_type_result.class==Hash and array_type_result[:ERROR]
    {"pair" => array_type_result.inject{ |hash, x| hash.update x}}
  end
  
  
  def telnet_table_cmd(cmd, cmd_options=nil)
    output = skeleton_command(cmd,cmd_options) do |telnet, cmd_result|  
      telnet.cmd(cmd){|ret| cmd_result << ret if ret.split(' ').length > 2}
    end
    return output if output.class == Hash and output[:ERROR]
    result = []
    output.join('').each_line do |line|
      line.gsub!(/-{10,}/,'')
      result << line.split(' ') if line.split(' ').length > 2
    end
    result
  end
  
  def telnet_multi_row_table_cmd(cmd, cmd_options=nil)
    telnet_output = skeleton_command(cmd,cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){ |ret| cmd_result << ret unless ret.length < 3 or ret =~ /-{10}/  }
    end
    return telnet_output if telnet_output.class==Hash and telnet_output[:ERROR]
    big_string = telnet_output.inject{ |sum, line| sum << line  }
    table_result = []
    # p big_string
    # print big_string
    big_string.each_line do |line| 
      table_result << line.split('  ').reject!{ |x| x.empty?} if line.split('  ').length > 2 and line !~ /^\s{20,}\w/
      table_result << line.strip if line =~ /^\s{20,}\w/
    end

    table_result = retrieve_return_row_table table_result
  end
  
  def telnet_multi_type(cmd, cmd_options=nil)
    the_result = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){|ret| cmd_result << ret}
    end
    return the_result if the_result.class==Hash and the_result[:ERROR]
    the_result.delete_if {|x| x.length < 10  }
    the_result.each{ |x| x.delete!("-")  }

    final_result = the_result.inject{ |sum, arr| sum << arr  }

    result = {}
    pair_content, table_content = {}, []
    final_result.split("\n").each do |line|
      next if line.strip.empty?
      if line.index(':')
        pair_content.update(retrieve_pair_info(line))
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
     return the_result if the_result.class==Hash and the_result[:ERROR]
     the_result.delete_if{ |x| x.length < 10  }
     the_result.each{ |x| x.delete("-") }
     
     
     final_result = the_result.inject{ |sum, arr| sum << arr  }
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
    output = skeleton_command(cmd, cmd_options) do |telnet, cmd_result|
      telnet.cmd(cmd){ |ret| cmd_result << ret  }
    end
    return output if output.class==Hash and output[:ERROR]
    output.delete_if{ |x| x.length < 2 or x=~ /-{10}/}
    output.each{ |x| x.strip!}

    result={}
    output.each_index do |i|
      pair_string = "#{output[i]} #{output[i+1]}" if output[i]=~ /:$/
      pair_string = output[i] if output[i] =~ /:\n/
      result.update(retrieve_pair_info pair_string) if pair_string
    end
    result
  end
end
