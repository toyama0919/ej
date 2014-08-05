# Ej

elasticsearch utility

## Installation

Add this line to your application's Gemfile:

    gem 'ej'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ej


## Usage

### simple search
```bash
ej -s
```

### other host
```bash
ej -s -h other_host
```

### query search and index
```bash
ej -s "ip_address: 127.0.0.1" -i logstash-2014.07.01
```

### index list
```bash
ej -l
```

### facet
```bash
ej -c ip_address -q "log_date: 2014-01-15"
```

### mapping
```bash
ej -m
```


## Contributing

1. Fork it ( http://github.com/toyama0919/ej/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
