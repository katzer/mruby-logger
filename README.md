# mruby-logger [![Build Status](https://travis-ci.com/katzer/mruby-logger.svg?branch=master)](https://travis-ci.com/katzer/mruby-logger)

Implementation of the Ruby 2.4.1 Standard Library [Logger][logger].
A simple but sophisticated logging utility that you can use to output messages.

```ruby
logger = Logger.new 'logs/development.log'

logger.formatter = -> (severity, datetime, progname, msg) do
  "[#{severity[0]}] #{datetime}: #{msg}\n"
end

logger.info 'hello world'
# => "[INFO] 2017-05-23 16:04:08 +0900: hello world"
```


## Installation

Add the line below to your `build_config.rb`:

```ruby
MRuby::Build.new do |conf|
  # ... (snip) ...
  conf.gem 'mruby-logger'
end
```

Or add this line to your aplication's `mrbgem.rake`:

```ruby
MRuby::Gem::Specification.new('your-mrbgem') do |spec|
  # ... (snip) ...
  spec.add_dependency 'mruby-logger'
end
```


## Development

Clone the repo:
    
    $ git clone https://github.com/katzer/mruby-logger.git && cd mruby-logger/

Compile the source:

    $ rake compile

Run the tests:

    $ rake test


## Authors

- Sebastián Katzer, Fa. appPlant GmbH


## License

The mgem is available as open source under the terms of the [MIT License][license].

Made with :yum: in Leipzig

© 2017 [appPlant GmbH][appplant]


[logger]: https://ruby-doc.org/stdlib-2.4.1/libdoc/logger/rdoc/Logger.html
[license]: http://opensource.org/licenses/MIT
[appplant]: www.appplant.de
