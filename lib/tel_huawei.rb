require "rubygems"
require "net/telnet"
require "yaml"

def telnet_pair_cmd(cmd, options=nil)
  return nil if cmd.nil? or cmd.empty?
  options = YAML::load(File.open('MA5616.yaml')) unless options
  cmd_result = {}
  telnet = Net::Telnet.new("Host" => options['host'], "Port" => options['port'], 'Prompt' => Regexp.new(options['prompt'],'Timeout' => 10),
   "Output_log" => "output.log")
  telnet.cmd("\n")
  telnet.cmd('root')
  telnet.cmd('String' => 'mduadmin','Match' => /----/)
  telnet.cmd('Q')
  telnet.cmd("String"=> 'enable', "Match" => /MA5616#/)

  telnet.cmd(cmd){ |ret| tmp= retrieve_pair_info(ret); cmd_result = tmp unless tmp.empty? }
  cmd_result
end

def telnet_table_cmd(cmd, options=nil)
  return nil if cmd.nil? or cmd.empty?
  options = YAML::load(File.open('MA5616.yaml')) unless options
  cmd_result = []
  telnet = Net::Telnet.new("Host" => options['host'], "Port" => options['port'], 'Prompt' => Regexp.new(options['prompt'],'Timeout' => 10),
   "Output_log" => "output.log")
  telnet.cmd("\n")
  telnet.cmd('root')
#  telnet.cmd('String' => 'mduadmin','Match' => /----/)
  telnet.cmd('mduadmin')
  # telnet.cmd('Q')
  telnet.cmd("String"=> 'enable', "Match" => /MA5616#/)
  telnet.cmd(cmd) do |ret|
    cmd_result << ret.split(' ') if ret.split(' ').length > 2
  end
  cmd_result
end
