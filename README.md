# serialoscclient-rb

SuperCollider client for SerialOSC compliant devices

## Description

SerialOSCClient provides plug'n'play support for [monome](http://monome.org) grids, arcs and other SerialOSC compliant devices.

## Requirements

This code has been developed and tested in Ruby 2.3.3 and JRuby 9.1.6.0. ```Grrr::ScreenGrid``` only works for JRuby.

## Installation

Download serialoscclient-rb. Add the ```lib``` folder of serialoscclient-rb to the Ruby load path.

## Implementation

This is a **less maintained** Ruby port of my SuperCollider library [SerialOSCClient-sc](http://github.com/antonhornquist/SerialOSCClient-sc).

If you intend to use this library beware of the monkey patching due to port of a collection of SuperCollider extensions to Ruby.

## License

Copyright (c) Anton Hörnquist
