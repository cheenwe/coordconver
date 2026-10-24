# 坐标转换 / Coordconver

[![CI](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml/badge.svg)](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coordconver.svg)](https://badge.fury.io/rb/coordconver)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个零依赖的 Ruby 坐标工具库：

1. **坐标系互转**（纯离线计算，无网络请求）：百度坐标（BD-09）、国测局/火星坐标（GCJ-02）、地球坐标（WGS-84）
2. **经纬度与度分秒互转**：`38.65777` ⇄ `38°39′27.97″`
3. **两点球面距离**：Haversine 公式，结果为米
4. **地址与坐标互转**：封装百度 / 高德 Web 服务 API（地理编码 / 逆地理编码）
5. **命令行工具**：单点转换、批量文件转换、距离计算

要求 Ruby >= 2.7。零运行时依赖，仅使用标准库。

## 安装

添加到 Gemfile：

```ruby
gem 'coordconver'
```

执行：

    $ bundle

或者直接安装：

    $ gem install coordconver

## 坐标系转换

### 快速上手

```ruby
require 'coordconver'

wgs = [121.468738, 31.247138]         # WGS-84 (GPS 原始坐标)
Coordconver.wgs_gcj(*wgs)             # => [121.47327833883615, 31.2452165865549]  (GCJ-02, 高德/谷歌中国)
Coordconver.wgs_bd(*wgs)              # => [121.47980789007566, 31.251157822142243] (BD-09, 百度)
```

### 全部转换方法

传入参数需为 **Float** 类型，如 `Coordconver.bd_gcj(lng.to_f, lat.to_f)`，返回 `[lng, lat]` 数组。

| 坐标系 | 转换名称 | 方法 | 语义化别名 |
| ----- | ----- | ----- | ----- |
| BD-09 -> GCJ-02 | 百度 -> 谷歌、高德 | `Coordconver.bd_gcj(lng, lat)` | `bd09_gcj02` |
| GCJ-02 -> BD-09 | 谷歌、高德 -> 百度 | `Coordconver.gcj_bd(lng, lat)` | `gcj02_bd09` |
| GCJ-02 -> WGS-84 | 谷歌、高德 -> 地球坐标 | `Coordconver.gcj_wgs(lng, lat)` | `gcj02_wgs84` |
| WGS-84 -> GCJ-02 | 地球坐标 -> 谷歌、高德 | `Coordconver.wgs_gcj(lng, lat)` | `wgs84_gcj02` |
| BD-09 -> WGS-84 | 百度 -> 地球坐标 | `Coordconver.bd_wgs(lng, lat)` | `bd09_wgs84` |
| WGS-84 -> BD-09 | 地球坐标 -> 百度 | `Coordconver.wgs_bd(lng, lat)` | `wgs84_bd09` |

### 辅助方法

```ruby
# 判断坐标是否在中国境外(境外 WGS-84 与 GCJ-02 一致, 转换方法会原样返回)
Coordconver.out_of_china?(121.47, 31.25)   # => false

# 两点球面距离(米), 两点需在同一坐标系下
Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416) # => 1068194.1 (北京->上海 约 1068 公里)
```

### 坐标系说明

| 坐标系 | 说明 | 使用方 |
| ----- | ----- | ----- |
| WGS-84 | 国际标准，GPS/北斗芯片原始坐标 | iOS 原生定位、OSM、海外谷歌地图 |
| GCJ-02 | 国测局标准（火星坐标），WGS-84 加密所得 | 高德、腾讯、谷歌中国、搜搜、阿里云 |
| BD-09 | 百度标准，GCJ-02 再次加密所得 | 百度地图、百度 SDK |

### 相关资料

- [各坐标系位置在线查看](http://www.gpsspg.com/maps.htm)
- [百度地图转换 API](https://lbsyun.baidu.com/jsdemo.htm#a5_2)
- [高德地图转换 API](https://lbs.amap.com/api/webservice/guide/api/convert/)

## 经纬度与度分秒互转

```ruby
Coordconver.degree(38.65777, 104.08296)
# => ["38°39′27.97″", "104°4′58.66″"]

Coordconver.undegree("38°39′27.97″", "104°4′58.66″")
# => [38.657769, 104.082961]

# 单值转换, 第二个参数控制秒的小数位(默认 2 位, 传 0 可得整数秒)
Coordconver.cal_degree(38.65777)     # => "38°39′27.97″"
Coordconver.cal_degree(38.65777, 0)  # => "38°39′28″"

# 解析支持多种写法: 38°39′27.97″ / 38°39′27.97" / 38d39m27.97s / 38:39:27.97
# 负值按西经/南纬处理
Coordconver.cal_undegree("-38°39′27.97″") # => -38.657769
```

换算公式：`Decimal Degrees = Degrees + minutes/60 + seconds/3600`

## 命令行工具

安装 gem 后可直接使用 `coordconver` 命令：

```bash
# 坐标系转换 (wgs2gcj / gcj2wgs / wgs2bd / bd2wgs / gcj2bd / bd2gcj)
coordconver wgs2gcj 121.468738 31.247138        # => 121.473278,31.245217
coordconver wgs84togcj02 121.468738 31.247138   # 同上, 支持完整写法
coordconver wgs2gcj 121.468738 31.247138 --json # => [121.473278,31.245217]
coordconver wgs2gcj 121.468738 31.247138 -r 4   # 保留 4 位小数

# 度分秒互转
coordconver dms 38.65777 104.08296              # => 38°39′27.97″,104°4′58.66″
coordconver dec "38°39′27.97″" "104°4′58.66″"   # => 38.657769,104.082961

# 两点距离(米)
coordconver dist 116.397428 39.90923 121.473701 31.230416

# 批量转换: 每行一条 "lng,lat" 或 "lng lat"
cat points.txt | coordconver wgs2gcj
echo "121.468738,31.247138" | coordconver gcj2wgs

# 地址 <-> 坐标 (需先配置 key, 见下文)
coordconver geo --gaode "北京方恒国际中心A座"
coordconver regeo --baidu 116.322987 39.983424
```

## 地址与坐标互转 (百度 / 高德 API)

地理编码/逆地理编码 API 提供结构化地址与经纬度之间的相互转化服务。使用前需申请对应的 API Key：

- 百度地图开放平台: https://lbsyun.baidu.com/apiconsole/key （创建**服务端**类型 AK，配置 IP 白名单；若选择 SN 校验类型，需同时配置 `baidu_sn`）
- 高德开放平台: https://console.amap.com/dev/key/app （类型选**Web 服务**）

百度默认配额 6000 次/天；高德个人认证 5000 次/天，企业用户单 Key 可达 200 万次/天。防止同一 key 超额，支持传入多个 key 让系统随机轮询。

### 配置

```ruby
require 'coordconver'

# 推荐: 全局配置块 (key 支持数组以轮询)
Coordconver.configure do |config|
  config.baidu_map_aks = ["百度ak1", "百度ak2"]
  config.gaode_map_keys = ["高德key1", "高德key2"]
  # config.baidu_sn = "SN校验密钥"      # 仅 AK 类型为"SN校验"时需要
  # config.open_timeout = 5             # 可选: 连接超时(秒)
  # config.read_timeout = 10            # 可选: 读取超时(秒)
end
```

或兼容旧写法：

```ruby
Coordconver::Client.new(["百度ak1", "百度ak2"], ["高德key1"])
```

未配置 key 就调用 API 会抛出 `Coordconver::ConfigurationError`，错误信息会提示如何配置。

### 地理编码 (地址 -> 坐标)

```ruby
# 百度, 返回完整 JSON (BD-09 坐标)
Coordconver::Baidu.geo("百度大厦")["result"]["location"]
# => {"lng"=>116.30775539540981, "lat"=>40.05685561073758}
Coordconver::Baidu.geo("百度大厦", city: "北京")   # 支持限定城市等官方可选参数

# 便捷方法, 解析失败返回 nil
Coordconver::Baidu.geo_location("百度大厦")  # => [116.30775539540981, 40.05685561073758]

# 高德, 返回完整 JSON (GCJ-02 坐标)
Coordconver::Gaode.geo("北京方恒国际中心A座")["geocodes"][0]["location"]
# => "116.480724,39.989584"
Coordconver::Gaode.geo_location("北京方恒国际中心A座")  # => [116.480724, 39.989584]
```

### 逆地理编码 (坐标 -> 地址)

```ruby
# 百度 (输入 BD-09 坐标)
Coordconver::Baidu.regeo(116.322987, 39.983424)["result"]["formatted_address"]
# => "北京市海淀区中关村大街27号1101-08室"
Coordconver::Baidu.regeo_address(116.322987, 39.983424)
# => "北京市海淀区中关村大街27号1101-08室"

# 高德 (输入 GCJ-02 坐标)
Coordconver::Gaode.regeo(116.480881, 39.989410)["regeocode"]["formatted_address"]
# => "北京市朝阳区望京街道方恒国际中心B座方恒国际中心"
Coordconver::Gaode.regeo_address(116.480881, 39.989410)

# 拿到的是 GPS(WGS-84) 坐标想直接查地址? 先转成对应坐标系:
gcj = Coordconver.wgs_gcj(lng, lat)
Coordconver::Gaode.regeo_address(*gcj)
```

### IP 定位 (百度)

```ruby
Coordconver::Baidu.ip          # 当前出口 IP 定位
Coordconver::Baidu.ip("8.8.8.8")
```

### 错误处理

```ruby
begin
  Coordconver::Gaode.regeo_address(116.48, 39.98)
rescue Coordconver::ConfigurationError => e
  # 未配置 key
rescue Coordconver::NetworkError => e
  # 超时/连接失败/响应非 JSON (内部已自动重试 3 次)
rescue Coordconver::Error => e
  # 基类, 兜底
end
```

服务端业务错误（如 key 无效、配额超限）不会抛异常，返回原始 JSON，通过 `status` 字段判断：百度 `status == 0` 为成功，高德 `status == "1"` 为成功。

## 升级说明 (0.x -> 1.0)

- 修复 `bd_wgs` 方向 bug（0.x 版本返回的是错误结果），并增加回归测试
- 百度地理编码升级到 Geocoding API v3（v2 接口已下线），默认走 HTTPS
- `cal_degree` 默认保留两位小数秒（`cal_degree(n, 0)` 可得旧版整数秒输出）
- 移除源码中硬编码的 key，调用 API 前必须先配置
- 支持 Ruby 2.7 ~ 3.4；CI 由 Travis 迁移至 GitHub Actions
- 新增：`distance`、`out_of_china?`、语义化别名、CLI 工具、统一错误体系、SN 校验支持

完整变更见 [CHANGELOG.md](CHANGELOG.md)。

## Development

检出代码后，运行 `bin/setup` 安装依赖，`rake test` 运行测试（全部离线，无需 API key）。

需要在线联调时：

```bash
COORDCONVER_LIVE_TEST=1 \
COORDCONVER_BAIDU_AK=你的百度ak \
COORDCONVER_GAODE_KEY=你的高德key \
rake test
```

本地安装：`bundle exec rake install`。发布新版本：更新 `lib/coordconver/version.rb` 后执行 `bundle exec rake release`。

## Contributing

欢迎提交 Bug 报告和 Pull Request：https://github.com/cheenwe/coordconver

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
