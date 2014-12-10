gem 'rspec', '~> 2.4'
require 'rspec'
require 'ej/version'

include Ej

def capture_stdout
  out = StringIO.new
  $stdout = out
  yield
  return out.string
ensure
  $stdout = STDOUT
end

def capture_stderr
  out = StringIO.new
  $stderr = out
  yield
  return out.string
ensure
  $stderr = STDERR
end

