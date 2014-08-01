# Esq

elasticsearch utility

## Installation

Add this line to your application's Gemfile:

    gem 'esq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install esq


## Usage

### simple search
```bash
esq -s
```

### other host
```bash
esq -s -h other_host
```

### query search and index
```bash
esq -s "ip_address: 127.0.0.1" -i logstash-2014.07.01
```

### index list
```bash
esq -l
```

### facet
```bash
esq -c ip_address -q "log_date: 2014-01-15"
```

### mapping
```bash
esq -m
```


## Contributing

1. Fork it ( http://github.com/toyama0919/esq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
