require File.dirname(__FILE__) + '/spec_helper'
require 'tel_huawei'


describe 'telnet huawei pon device' do
  
    # it "should get board info successfuly" do
    #      output = telnet_table_cmd('display board 0')
    #      output.should_not be_nil
    #      puts "display board 0:\n--------------------------"
    #      p output
    #      puts
    #    end
    #    
    #    sleep 2
    #    
    #    it "shoud get pon sn successfully" do
    #      output = telnet_pair_cmd('display pon sn')
    #      output.should_not be_nil
    #      puts "disp pon sn:\n--------------------------"
    #      p output
    #      puts
    #    end
    #    
    #    sleep 2
    #    
    #    it "should get version successfully" do
    #      output = telnet_pair_cmd('display version 0/0')
    #      output.should_not be_nil
    #      puts "display version 0/0:\n--------------------------"
    #      p output
    #      puts
    #    end
    #    
    #    sleep 2
    # 
  it "should get single board information" do
    output = telnet_multi_type('display board 0/4')
    p output
  end
    
end