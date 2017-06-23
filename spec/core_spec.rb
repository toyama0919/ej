require 'spec_helper'
require 'ej'

describe Ej::Core do
  before do
    values = Values.new(
      {
        index: '_all',
        host: DEFAULT_HOST,
        debug: false
      }
    )
    @core = Core.new(values)
  end

  it "core not nil" do
    @core.should_not nil
  end

  after do
  end
end
