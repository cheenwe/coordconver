# 坐标转换/Coordconver
提供了百度坐标（BD09）、国测局坐标（火星坐标，GCJ02）、和WGS84坐标系之间的转换。


## 坐标系说明
### 地球坐标 (WGS84)

- 国际标准，从 GPS 设备中取出的数据的坐标系

- 国际地图提供商使用的坐标系

### 火星坐标 (GCJ-02)也叫国测局坐标系
- 中国标准，从国行移动设备中定位获取的坐标数据使用这个坐标系

- 国家规定： 国内出版的各种地图系统（包括电子形式），必须至少采用GCJ-02对地理位置进行首次加密。

###百度坐标 (BD-09)
- 百度标准，百度 SDK，百度地图，Geocoding 使用

## 开发过程需要注意的事
- 从设备获取经纬度（GPS）坐标

    		如果使用的是百度sdk那么可以获得百度坐标（bd09）或者火星坐标（GCJ02),默认是bd09
    		如果使用的是ios的原生定位库，那么获得的坐标是WGS84
    		如果使用的是高德sdk,那么获取的坐标是GCJ02

- 互联网在线地图使用的坐标系

		火星坐标系：
    			iOS 地图（其实是高德）
    			Google国内地图（.cn域名下）
    			搜搜、阿里云、高德地图、腾讯
		百度坐标系：
    			当然只有百度地图
		WGS84坐标系：
    			国际标准，谷歌国外地图、osm地图等国外的地图一般都是这个

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

