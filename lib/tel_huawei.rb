require "rubygems"
require "net/telnet"
require "yaml"
require File.dirname(__FILE__) + "/retrieve_helper"
#
#负责telnet到设备上，并执行传入的cmd指令，将结果以array形式进行返回
#
#cmd 在设备上访问的指令
#options a hash options指定登录设备时用到的一些属性设置：
# Host: 设备的访问地址
# Port: 设备访问端口
# Pormpt: 用于匹配提示符的正则表达式形式的字符串，如"(User name:)|(User password:)|(MA5616>)|(MA5616#)|(password:)"
# Timeout: 超时时间
# Output_log: 输出日志的存放路径及文件名
# Waittime: 等待时间
# Dump_log: 用于调试的导出日志，二进制格式
# username: 登录用户名
# password: 登录密码
def cmd_skeleton(cmd, options=nil, cmd_options=nil)
  return nil if cmd.nil? or cmd.empty?
  options = YAML::load(File.open(File.dirname(__FILE__)+'/device_configurations' + '/MA5616.yaml')) unless options
  
  #默认的命令操作模式
  cmd_options = {:h248_mgid => 0, :config_model => false, :enable_model => true, :adsl_model => false, :adsl_frame => 0,
     :adsl_slot => 4, :gponnni_model => false, :gponnni_port=>'0/0/1'} if cmd_options.nil? or cmd_options.empty?
  cmd_options[:h248_mgid] |= 0
  
  cmd_options[:config_model] = false if cmd_options[:config_model].nil?
  cmd_options[:config_model] = true if cmd_options[:adsl_model] or cmd_options[:h249_model] or cmd_options[:gponnni_model]
  
  cmd_options[:h248_model] = false if cmd_options[:h248_model].nil?
  cmd_options[:enable_model] = true if cmd_options[:enable_model].nil?
  cmd_options[:adsl_model] = false if cmd_options[:adsl_model].nil?
  cmd_options[:gponnni_port] = '0/0/1' if cmd_options[:gponnni_port].nil? or cmd_options[:gponnni_port].empty?
  cmd_options[:gponnni_model] = false if cmd_options[:gponnni_model].nil?
  
  cmd_options[:adsl_frame] |= 0
  cmd_options[:adsl_slot] |= 4
  
  
  cmd_result = []
  telnet = Net::Telnet.new("Host" => options['host'], "Port" => options['port'], 'Prompt' => Regexp.new(options['prompt'],'Timeout' => 10),
   "Output_log" => File.dirname(__FILE__)+"/../logs"+"/output.log")
  telnet.cmd("\n")
  telnet.cmd(options['username'])
  telnet.cmd(options['password'])
  # telnet.cmd('Q')
  telnet.cmd('scroll 512')
  telnet.cmd("String"=> 'enable') if cmd_options[:enable_model]
  
  telnet.cmd('config') if cmd_options[:config_model] or cmd_options[:h248_model] or
   cmd_options[:adsl_model] or cmd_options[:gponnni_model]
   
  telnet.cmd("interface h248 #{cmd_options[:h248_mgid]}") if cmd_options[:h248_model]
  telnet.cmd("interface adsl #{cmd_options[:adsl_frame]}/#{cmd_options[:adsl_slot]}") if cmd_options[:adsl_model]
  telnet.cmd("interface gponnni #{cmd_options[:gponnni_port]}") if cmd_options[:gponnni_port]
  yield(telnet, cmd_result)
  cmd_result
end

#
#用于获取以分隔符分隔的命令结果
#
def telnet_pair_cmd(cmd, options=nil, cmd_options=nil)
  array_type_result = cmd_skeleton(cmd, options, cmd_options) do |telnet, cmd_result|
    telnet.cmd(cmd){ |ret| tmp = retrieve_pair_info(ret); cmd_result << tmp unless tmp.empty? }
  end
  hash_type_result = {}
  array_type_result.each{ |x| hash_type_result.update(x)  }
  {"pair" => hash_type_result}
end

#
#用于获取以表格形式返回的结果
#
def telnet_table_cmd(cmd, options=nil)
  cmd_skeleton(cmd,options) do |telnet, cmd_result|
    telnet.cmd(cmd){ |ret| cmd_result << ret.split(' ') if ret.split(' ').length > 2 }
  end
end

def telnet_multi_type(cmd, options=nil, cmd_options=nil)
  the_result = cmd_skeleton(cmd, options, cmd_options) do |telnet, cmd_result|
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
    next if line.empty? or line.strip.empty?
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

def telnet_multi_row(cmd, options=nil, cmd_options=nil)
   the_result = cmd_skeleton(cmd,options,cmd_options) do |telnet, cmd_result|
     telnet.cmd(cmd){ |ret| cmd_result << ret}
   end
   the_result.delete_if{ |x| x.length < 10  }
   the_result.each{ |x| x.delete("-") }
   final_result = ""
   the_result.each{ |arr| final_result << arr }
   result = {}
   pair_content, line_content = [], []
   final_result.split("\n").each do |line|
    next if line.empty? or line.strip.empty? or line =~ /-{20}/
    if line.index(':')
      pair_content << retrieve_pair_info(line) unless line.count(':') > 1
      pair_content << retrieve_multi_pair(line) if line.count(':') > 1
    else
      line_content << line.strip
    end
   end
   result['pair'] = pair_content
   result['line'] = line_content
   result
end

def telnet_return_pair(cmd, options=nil, cmd_options=nil)
  the_result = cmd_skeleton(cmd, options, cmd_options) do |telnet, cmd_result|
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