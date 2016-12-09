# 坐标转换/Coordconver
提供了百度坐标（BD-09）、国测局坐标（火星坐标，GCJ-02）、和 地球坐标( WGS-84) 坐标系之间的转换。

## 坐标系说明

### 百度坐标系 (BD-09)
- 百度标准，百度 SDK，百度地图，Geocoding 使用

### 火星坐标系 (GCJ-02)
- 中国标准(国测局坐标系)，从国行移动设备中定位获取的坐标数据使用这个坐标系, 由中国国家测绘局制订的地理信息系统的坐标系统

- 由WGS84坐标系经加密后的坐标系

- 谷歌中国地图, 搜搜中国地图, iOS地图(高德), 搜搜, 阿里云, 高德地图, 腾讯

### 地球坐标系 (WGS-84)
- 国际标准， 设备一般包含GPS芯片或者北斗芯片获取的经纬度为WGS84地理坐标系

- 谷歌地图采用的是WGS84地理坐标系（中国范围除外）

- ios的原生定位库, osm

## 转换方法

|   坐标系      |   转换名称     |   方法|
|   ----------- |   ------- |   -----   | --------- |
|  BD-09 ->  GCJ-02  |    百度 -> 谷歌、高德  |   Coordconver.bd_gcj  |
|  BD-09 ->  WGS-84  |    百度 -> 地球坐标  |   Coordconver.bd_wgs   |
|  GCJ-02 -> WGS-84  |    谷歌、高德 -> 地球坐标  |    Coordconver.gcj_wgs   |
|  GCJ-02 -> BD-09  |    谷歌、高德 -> 百度  |    Coordconver.gcj_bd   |
|  WGS-84 -> BD-09  |    地球坐标 -> 百度  |    Coordconver.wgs_bd   |
|  WGS-84 -> GCJ-02 |    地球坐标 -> 谷歌、高德  |    Coordconver.wgs_gcj   |


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coordconver'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coordconver

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cheenwe/coordconver.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

