require "MA5616"
require "yaml"

describe "MA5616 can tetrieve multi info" do
  
  before(:each) do
    ma5616_configuration = YAML::load(File.open(File.dirname(__FILE__)+"/../lib/device_configurations/"+"MA5616.yaml"))
    @ma5616 = MA5616.new(ma5616_configuration)
  end
  
  it "should get onu system info" do
    system_info = @ma5616.tel_system_info
    p system_info
    system_info["The main service identification of this node"].should =~ /\d/
    system_info["The IP address of this node"].should =~ /^(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])$/
    system_info["The description of this node"].should =~ /Huawei/
    system_info["The description of this node"].should =~ /Huawei/
  end
  
  it "should get active alarm information" do
    alarm_info = @ma5616.tel_active_alarm
    table_header = alarm_info[0]
    
    table_header[0].should =~ /AlarmSN/
    table_header[1].should =~ /Date&Time/
    table_header[2].should =~ /Alarm Name\/Para/
    
    table_data = alarm_info[1]
    table_data.length == 3
    table_data[0].should =~ /\d/
    table_data[1].should =~ /\d{4}/
  end
end