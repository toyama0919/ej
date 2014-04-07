# Myq

mysql to json

## Installation

Add this line to your application's Gemfile:

    gem 'myq'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install myq

## Setting

Create $HOME/.database.yml
```yml
default:
  database: test
  host: localhost
  port: 3306
  username: root
  password: ''

staging:
  database: test
  host: staging.net
  port: 3306
  username: root
  password: ''
```

## Usage

```bash
Commands:
  myq --dbs                                              # show databases
  myq --ps                                               # show processlist
  myq --set -v key=value; -v, --variables=one two three  # set global variable
  myq -I [table]                                         # bulk insert json
  myq -c [table name] -k [group by keys]                 # count record, group by keys
  myq -f [file]                                          # query by sql file
  myq -l [table name]                                    # show table info
  myq -q [sql]                                           # inline query
  myq -s [table name]                                    # sampling query, default limit 10
  myq -v [like query]                                    # show variables
  myq help [COMMAND]                                     # Describe available commands or one specific command
  myq version                                            # show version

Options:
  -p, [--profile=PROFILE]  # profile by .database.yml
                           # Default: default
  -P, [--pretty]           # pretty print
```

## Exsample

### run query

```bash
$ myq -q "select * from access limit 10"
[{"host":"48.189.196.32","user":"-","method":"POST","referer":"-","path":"/search/?c=Games+Sports","size":133,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"128.24.107.59","user":"-","method":"GET","referer":"-","path":"/category/electronics","size":70,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"144.102.28.67","user":"-","method":"GET","referer":"/category/office","path":"/item/games/4274","size":59,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"100.129.167.163","user":"-","method":"GET","referer":"/category/books","path":"/item/electronics/4570","size":139,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0; r","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"132.189.67.199","user":"-","method":"POST","referer":"-","path":"/search/?c=Finance","size":116,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0) A","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"176.147.148.79","user":"-","method":"GET","referer":"/category/software","path":"/item/jewelry/4592","size":78,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"200.48.189.175","user":"-","method":"GET","referer":"-","path":"/category/software","size":85,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0; r","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"220.111.122.175","user":"-","method":"GET","referer":"/category/software","path":"/category/networking","size":43,"code":200,"agent":"Mozilla/5.0 (compatible; Googl","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"220.117.150.167","user":"-","method":"GET","referer":"-","path":"/category/electronics","size":109,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"176.93.131.44","user":"-","method":"POST","referer":"/category/music","path":"/search/?c=Toys","size":60,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:39 +0900"}]
```

### sampling query

```bash
$ myq -s access
[{"host":"48.189.196.32","user":"-","method":"POST","referer":"-","path":"/search/?c=Games+Sports","size":133,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"128.24.107.59","user":"-","method":"GET","referer":"-","path":"/category/electronics","size":70,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"144.102.28.67","user":"-","method":"GET","referer":"/category/office","path":"/item/games/4274","size":59,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"100.129.167.163","user":"-","method":"GET","referer":"/category/books","path":"/item/electronics/4570","size":139,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0; r","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"132.189.67.199","user":"-","method":"POST","referer":"-","path":"/search/?c=Finance","size":116,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0) A","updated_at":"2014-03-01 19:03:38 +0900"},{"host":"176.147.148.79","user":"-","method":"GET","referer":"/category/software","path":"/item/jewelry/4592","size":78,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"200.48.189.175","user":"-","method":"GET","referer":"-","path":"/category/software","size":85,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.0; r","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"220.111.122.175","user":"-","method":"GET","referer":"/category/software","path":"/category/networking","size":43,"code":200,"agent":"Mozilla/5.0 (compatible; Googl","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"220.117.150.167","user":"-","method":"GET","referer":"-","path":"/category/electronics","size":109,"code":200,"agent":"Mozilla/4.0 (compatible; MSIE ","updated_at":"2014-03-01 19:03:39 +0900"},{"host":"176.93.131.44","user":"-","method":"POST","referer":"/category/music","path":"/search/?c=Toys","size":60,"code":200,"agent":"Mozilla/5.0 (Windows NT 6.1; W","updated_at":"2014-03-01 19:03:39 +0900"}]
```

## Contributing

1. Fork it ( http://github.com/<my-github-username>/myq/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
