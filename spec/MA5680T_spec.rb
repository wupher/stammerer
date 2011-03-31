require "MA5680T"
require "yaml"

describe "MA5680T can retrieve multipul information" do
  before(:all) do
    configuration = YAML::load(File.open(File.dirname(__FILE__)+"/../lib/device_configurations/"+"MA5680T.yaml"))
    @olt = MA5680T.new(configuration)
  end
  
  it "should get gpon port statistics infomation" do
    info = @olt.tel_gpon_port_performance
    statistics = info["pair"]
    p statistics
    statistics.should_not be_empty
  end
  
  sleep 2
  
  it "should get board info" do
    info = @olt.tel_board_info
    p info
    info.class.should == Array
    info.should_not be_nil
    info.should_not be_empty
  end
end