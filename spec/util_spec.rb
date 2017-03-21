require 'spec_helper'
require 'ej'

describe Ej::Util do
  before do
  end

  it "parse json" do
    Util.parse_json('{"id":1, "name":"rspec"}').should == [{"id" => 1, "name" => "rspec"}]
  end

  it "parse jsonl" do
    json = %[{"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}]
    Util.parse_json(json).should == [{"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}]
  end

  it "parse json array" do
    json = %[[
      {"id":1, "name":"rspec"},
      {"id":2, "name":"rspec"},
      {"id":3, "name":"rspec"},
      {"id":4, "name":"rspec"}
    ]]
    Util.parse_json(json).should == [{"id" => 1, "name" => "rspec"}, {"id" => 2, "name" => "rspec"}, {"id" => 3, "name" => "rspec"}, {"id" => 4, "name" => "rspec"}]
  end

  it "generate id" do
    Util.generate_id('%s_%s', {"id" => 1, "name" => "rspec"}, ['id', 'name']).should == '1_rspec'
  end

  after do
  end
end
