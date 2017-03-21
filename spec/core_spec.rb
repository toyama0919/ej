require 'spec_helper'
require 'ej'

describe Ej::Core do
  before do
    values = Values.new(
      {
        index: 'localhost',
        host: '_all',
        debug: false
      }
    )
    @core = Core.new(values)
  end

  it "core not nil" do
    @core.should_not nil
  end

  it "parse json" do
    @core.send(:parse_json, '{"id":1, "name":"rspec"}').should == [{"id" => 1, "name" => "rspec"}]
  end

  it "parse json" do
    json = %[{"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}
      {"id":1, "name":"rspec"}] 
    @core.send(:parse_json, json).should == [{"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}, {"id" => 1, "name" => "rspec"}]
  end

  it "generate id" do
    @core.send(:generate_id, '%s_%s', {"id" => 1, "name" => "rspec"}, ['id', 'name']).should == '1_rspec'
  end

  after do
  end
end
