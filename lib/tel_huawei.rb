require "rubygems"
require "net/telnet"
require "yaml"
require File.dirname(__FILE__) + "/retrieve_helper"

def cmd_skeleton(cmd, options=nil)
  return nil if cmd.nil? or cmd.empty?
  options = YAML::load(File.open(File.dirname(__FILE__)+'/device_configurations' + '/MA5616.yaml')) unless options
  cmd_result = []
  telnet = Net::Telnet.new("Host" => options['host'], "Port" => options['port'], 'Prompt' => Regexp.new(options['prompt'],'Timeout' => 10),
   "Output_log" => "logs/output.log")
  telnet.cmd("\n")
  telnet.cmd(options['username'])
  telnet.cmd(options['password'])
  # telnet.cmd('Q')
  telnet.cmd('scroll 512')
  telnet.cmd("String"=> 'enable', "Match" => /MA5616#/)
  yield(telnet, cmd_result)
  cmd_result
end

def telnet_pair_cmd(cmd, options=nil)
  cmd_skeleton(cmd,options) do |telnet, cmd_result|
    telnet.cmd(cmd){ |ret| tmp = retrieve_pair_info(ret); cmd_result << tmp unless tmp.empty? }
  end
end

def telnet_table_cmd(cmd, options=nil)
  cmd_skeleton(cmd,options) do |telnet, cmd_result|
    telnet.cmd(cmd){ |ret| cmd_result << ret.split(' ') if ret.split(' ').length > 2 }
  end
end

def telnet_multi_type(cmd, options=nil)
  the_result = cmd_skeleton(cmd, options) do |telnet, cmd_result|
    telnet.cmd(cmd){|ret| cmd_result << ret}
  end
  # the_result.each do |line|
  #     the_result.shift unless line.index('-') or line.index(':') or line.index(' ')
  #   end
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
