# Ej 

[![Build Status](https://secure.travis-ci.org/toyama0919/ej.png?branch=master)](http://travis-ci.org/toyama0919/ej)
[![Gem Version](https://badge.fury.io/rb/ej.svg)](http://badge.fury.io/rb/ej)

elasticsearch command line utility

support ruby version >= 2.1

![ej4.gif](https://qiita-image-store.s3.amazonaws.com/0/26670/116a381c-98f6-aa72-fbd9-ddc4b179b744.gif)

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

### other host(default host is localhost)
```bash
ej -s -h other_host:9201
```

### query search and index
```bash
ej -s "ip_address: 127.0.0.1" -i logstash-2014.07.01 -h other_host
```

### index list
```bash
ej -l -h other_host
```

### count
```bash
ej -c "log_date: 2014-01-15" -h other_host
```

### mapping
```bash
ej -m -h other_host
```

### delete index
```bash
ej delete -i logstash-2014.07.01 -h other_host
```

### delete by query
```bash
ej delete -i logstash-2014.07.01 -q '{ match: { user_id: 1 } }' -h other_host
ej delete -i logstash-2014.07.01 -q '{"range":{"@timestamp":{"lte":"2014-07-01"}}}' -h other_host
```

### copy index from remote to remote
```bash
ej copy --source remote_host1:9200 --dest remote_host2:9200 -i logstash-2017.01.27 -q 'size: 631'
```

## monitor

### node stats
```bash
ej nodes_stats -h remote_host1
```

### settings
```bash
ej settings -h remote_host1
```

## Contributing

1. Fork it ( http://github.com/toyama0919/ej/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
