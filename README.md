# 坐标转换/Coordconver
[![Build Status](https://travis-ci.org/cheenwe/coordconver.svg?branch=master)](https://travis-ci.org/cheenwe/coordconver)

- 1.提供了百度坐标（BD-09）、国测局坐标（火星坐标，GCJ-02）、和 地球坐标( WGS-84) 坐标系之间的转换。

- 2.坐标点到经纬度的相互转换

- 3.坐标点和地理位置的相互转换(百度，高德API)

## 安装

添加到Gemfile:

```ruby
gem 'coordconver'
```

执行:

    $ bundle

或者只安装该GEM:

    $ gem install coordconver


## 坐标系转换

### 用法

提供6转换方式，传入参数需为**float**类型，如：
>Coordconver.bd_gcj(lng.to_f, lat.to_f)

|   坐标系      |   转换名称     |   方法|
|   ----------- |   ------- |   -----   | --------- |
|  BD-09 ->  GCJ-02  |    百度 -> 谷歌、高德  |   Coordconver.bd_gcj(lng, lat)  |
|  BD-09 ->  WGS-84  |    百度 -> 地球坐标  |   Coordconver.bd_wgs(lng, lat)  |
|  GCJ-02 -> WGS-84  |    谷歌、高德 -> 地球坐标  |    Coordconver.gcj_wgs(lng, lat)  |
|  GCJ-02 -> BD-09  |    谷歌、高德 -> 百度  |    Coordconver.gcj_bd(lng, lat)  |
|  WGS-84 -> BD-09  |    地球坐标 -> 百度  |    Coordconver.wgs_bd(lng, lat)  |
|  WGS-84 -> GCJ-02 |    地球坐标 -> 谷歌、高德  |    Coordconver.wgs_gcj(lng, lat)  |

示例：
>Coordconver.wgs_bd(121.46873833333332, 31.247138333333336) # => [121.479808223763, 31.25115814844421]

### 坐标系说明

#### 百度坐标系 (BD-09)
- 百度标准，百度 SDK，百度地图，Geocoding 使用

#### 火星坐标系 (GCJ-02)
- 中国标准(国测局坐标系)，从国行移动设备中定位获取的坐标数据使用这个坐标系, 由中国国家测绘局制订的地理信息系统的坐标系统

- 由WGS84坐标系经加密后的坐标系

- 谷歌中国地图, 搜搜中国地图, iOS地图(高德), 搜搜, 阿里云, 高德地图, 腾讯

#### 地球坐标系 (WGS-84)
- 国际标准， 设备一般包含GPS芯片或者北斗芯片获取的经纬度为WGS84地理坐标系

- 谷歌地图采用的是WGS84地理坐标系（中国范围除外）

- ios的原生定位库, osm


### 相关资料

- [各坐标系位置在线查看](http://www.gpsspg.com/maps.htm)

- [百度地图转换API](http://lbsyun.baidu.com/jsdemo.htm#a5_2)

- [高德地图转换API](http://lbs.amap.com/api/webservice/guide/api/convert/#convert)


## 坐标点与经纬度转换

### 用法

提供4种转换方式，传入坐标点需为**float**类型，传入经纬度需为**string**类型。

|   转换名称     |   方法|
|   -----   | --------- |
|   坐标点转度数 |   Coordconver.degree(lng, lat)  |
|   单个坐标点转度数  |   Coordconver.cal_degree(n)  |
|   度数点转坐标点 |   Coordconver.undegree(lng_degree, lat_degree)  |
|   单个度数转坐标点  |   Coordconver.cal_degree(n)  |


示例：

>Coordconver.degree(38.65777, 104.08296) # => ["38°39′27″","104°4′58″"]

>Coordconver.undegree("38°39′27.97″","104°4′58.66″") # => [38.65777,104.08296]

### 相关资料
		地形图坐标系：我国的地形图采用高斯－克吕格平面直角坐标系。在该坐标系中，横轴：赤道，用Ｙ表示；纵轴：中央经线，用Ｘ表示；坐标原点：中央经线与赤道的交点，用0表示。赤道以南为负，以北为正；中央经线以东为正，以西为负。我国位于北半球，故纵坐标均为正值，但为避免中央经度线以西为负值的情况，将坐标纵轴西移500公里。

		北京54坐标系：1954年我国在北京设立了大地坐标原点，采用克拉索夫斯基椭球体，依此计算出来的各大地控制点的坐标，称为北京54坐标系。
		GS84坐标系：即世界通用的经纬度坐标系。

		经纬度表示：1884年国际经度会议规定，以通过英国伦敦格林威治天文台子午仪中心的经线为0°经线。从0°经线往东叫东经，往西叫西经，东、西各分180°。习惯上以西经20°和东经160°为分界把地球分为东西两个半球。假如从地轴的正中间将地球切成南北两半，上边的一半叫北半球，下边的一半叫南半球。被切的这个平面，叫赤道面。赤道面与地球表面相交的线叫赤道。纬线从赤道往两极越来越短，到了两极就缩小成一个点了。科学家们把赤道定为0°纬线，从赤道向两极各分为90°，赤道以南叫南纬，赤道以北叫北纬。在计算机或GPS上经纬度经常用度、分、秒和度.度、分.分、秒.秒的混合方式进行表示，度、分、秒间的进制是60进制，度.度、分.分、秒.秒的进制是100进制，换算时一定要注意。可以近似地认为每个纬度之间的距离是不变的111KM,每分间 1.85KM，每秒间31.8M。经度间的距离随纬度增高逐渐减小，可按以下公式计算：
		Decimal Degrees = Degrees + minutes/60 + seconds/3600
		例：57°55’56.6″ =57+55/60+56.6/3600=57.9323888888888
		114°65’24.6″=114+65/60+24.6/3600=115.00683333333333


## 坐标点与地址转换

地理编码/逆地理编码API是一类简单的HTTP接口，提供结构化地址与经纬度之间的相互转化服务。

该套API免费对外开放，使用API您需先申请对应的API Key，

- 百度地图 默认配额6000次/天。

- 高德地图API，企业用户单个Key支持200万次/天，5万次/分钟。

防止同一key 使用超额， 建议申请多个key使用让系统随机调用。

### 用法

```ruby
Coordconver::Client.new(["百度 ak1","百度 ak2"],["高德 key1"," key2"])

Coordconver::Baidu.regeo(116.322987, 39.983424) #百度地图api在线坐标转换地址

Coordconver::Gaode.regeo(116.480881,39.989410) #高德地图api在线坐标转换地址

Coordconver::Gaode.geo("北京方恒国际中心A座") #高德地图api在线地址转换坐标

Coordconver::Baidu.geo("百度大厦") #百度地图api在线地址转换坐标
```

示例：

>Coordconver::Client.new(["xxxxx],["xxxx"])

1.百度地图转换
[Online API](http://lbsyun.baidu.com/index.php?title=webapi/guide/webservice-geocoding)


- 地理编码：即地址解析，由详细到街道的结构化地址得到百度经纬度信息
    例如：“北京市海淀区中关村南大街27号”地址解析的结果是“lng:116.31985,lat:39.959836”。

>Coordconver::Baidu.geo("百度大厦")["result"]["location"].values # => [116.30775539540981, 40.05685561073758]

```json
{
    "status": 0,
    "result": {
        "location": {
            "lng": 116.30775539540981,
            "lat": 40.05685561073758
        },
        "precise": 1,
        "confidence": 80,
        "level": "商务大厦"
    }
}
```

- 逆地理编码：即逆地址解析，由百度经纬度信息得到结构化地址信息，例如：“lat:31.325152,lng:120.558957”逆地址解析的结果是“江苏省苏州市虎丘区塔园路318号”。

>Coordconver::Baidu.regeo(116.32298699999993,39.98342407140365)["result"]["formatted_address"] # => 北京市海淀区中关村大街27号1101-08室

```json
{
"status": 0,
"result": {
"location": {
"lng": 116.32298699999993,
"lat": 39.98342407140365
},
"formatted_address": "北京市海淀区中关村大街27号1101-08室",
"business": "中关村,人民大学,苏州街",
"addressComponent": {
"country": "中国",
"country_code": 0,
"province": "北京市",
"city": "北京市",
"district": "海淀区",
"adcode": "110108",
"street": "中关村大街",
"street_number": "27号1101-08室",
"direction": "附近",
"distance": "7"
},
"pois": [],
"poiRegions": [],
"sematic_description": "北京远景国际公寓(中关村店)内0米",
"cityCode": 131
}
}

```

2.高德地图转换

[API](http://lbs.amap.com/api/webservice/guide/api/georegeo/#geo)

- 地理编码：将详细的结构化地址转换为高德经纬度坐标，且支持名胜景区、标志性建筑物名称解析为高德经纬度坐标。
例如：北京市朝阳区阜通东大街6号-->116.480881,39.989410
          天安门-->116.397499,39.908722

>Coordconver::Gaode.geo("北京方恒国际中心A座")["geocodes"][0]["location"]

```json
{
"status" : "1",
"info" : "OK",
"infocode" : "10000",
"count" : "1",
"geocodes" :
[
"0" :
{
"formatted_address" : "北京市朝阳区方恒国际中心|A座",
"province" : "北京市",
"citycode" : "010",
"city" : "北京市",
"district" : "朝阳区",
...
"location" : "116.480724,39.989584",
"level" : "门牌号"
}
]
}
```

- 逆地理编码：将经纬度转换为详细结构化的地址，且返回附近周边的POI信息，以及该经纬度所在的POI信息。
例如：116.480881,39.989410-->北京市朝阳区阜通东大街6号

>Coordconver::Gaode.regeo(116.480881,39.989410)['regeocode']["formatted_address"]


```json
{
"status" : "1",
"info" : "OK",
"infocode" : "10000",
"regeocode" :
{
"formatted_address" : "北京市朝阳区望京街道方恒国际中心B座方恒国际中心",
...
}
}

```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/cheenwe/coordconver.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

