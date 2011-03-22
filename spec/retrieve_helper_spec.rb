require "retrieve_helper"

describe "retrieve pair test" do
  it "should retrieve multi pair info into a hash result" do
    test_str = "  Profile index :1    Name: DEFVAL";
    desire_result = {"Profile index" => '1', "Profile Name" => "DEFVAL"}
    accual_result = retrieve_multi_pair(test_str)
    accual_result.should == desire_result
  end
end