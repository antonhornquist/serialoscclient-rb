# serialoscclient-rb

SerialOSC device (monome grid, arc) support for Ruby

## Description

This is a **less maintained** port of the [SerialOSCClient-sc](http://github.com/antonhornquist/SerialOSCClient-sc) SuperCollider library. Please report bugs.

SerialOSCClient provides plug'n'play support for [monome](http://monome.org) grids, arcs and other SerialOSC compliant devices.

## Requirements

This library requires the [osc-ruby](https://github.com/aberant/osc-ruby) gem.

This code has been developed and tested in Ruby 2.3.3 and JRuby 9.1.6.0.

## Installation

Install gem [osc-ruby](https://github.com/aberant/osc-ruby):

```
$ gem install osc-ruby
```

or, for JRuby:

```
$ jgem install osc-ruby
```

Download serialoscclient-rb. Add the ```lib``` folder of serialoscclient-rb to the Ruby load path.

## Implementation

This is a Ruby port of the [SerialOSCClient-sc](http://github.com/antonhornquist/SerialOSCClient-sc) SuperCollider library.

If you intend to use this library beware of the monkey patching due to port of a collection of SuperCollider extensions to Ruby.

## License

Copyright (c) Anton Hörnquist
