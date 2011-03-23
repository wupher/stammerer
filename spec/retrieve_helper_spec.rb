require "retrieve_helper"

describe "retrieve helper test" do
  describe "retrieve multi pair test" do
    
    it "should retrieve multi pair info into a hash result" do
      test_str = "  Profile index :1    Name: DEFVAL";
      desire_result = {"Profile index" => '1', "Profile Name" => "DEFVAL"}
      accual_result = retrieve_multi_pair(test_str)
      accual_result.should == desire_result
    end
    
    it "should also retrieve single pair string " do
      test_str = " Profile index : 1 "
      desire = {"Profile index" => "1"}
      accual = retrieve_multi_pair(test_str)
      accual.should == desire
    end
  end
  
  describe "retrieve pair test" do
    it "should retrieve pair info into a hash" do
      test_str = "Profile index : 1"
      desire = {"Profile index" => "1"}
      accual = retrieve_pair_info test_str
      accual.should == desire
    end
  end
end