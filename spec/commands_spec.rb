require 'spec_helper'
require 'ej'

describe Ej::Commands do
  before do
  end

  it "should exists search option" do
    output = capture_stdout do
      Ej::Commands.start(['help', 'search'])
    end
    output.should include('--type')
    output.should include('--fields')
    output.should include('--query')
    output.should include('--size')
    output.should include('--from')
    output.should include('--source-only')
  end

  it "should exists copy option" do
    output = capture_stdout do
      Ej::Commands.start(['help', 'copy'])
    end
    output.should include('--source')
    output.should include('--dest')
    output.should include('--query')
  end

  it "should exists delete option" do
    output = capture_stdout do
      Ej::Commands.start(['help', 'delete'])
    end
    output.should include('--query')
    output.should include('--index')
    output.should include('--type')
  end

  it "should default check" do
    output = capture_stdout do
      Ej::Commands.start(['help', 'search'])
    end
    output.should include("Default: localhost")
    output.should include("Default: _all")
  end

  after do
  end
end
