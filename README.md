# 坐标转换 / Coordconver

[![CI](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml/badge.svg)](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coordconver.svg)](https://badge.fury.io/rb/coordconver)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

一个零依赖的 Ruby 坐标工具库（[English](README.en.md)）：

1. **坐标系互转**（纯离线）：百度（BD-09）、火星（GCJ-02）、地球（WGS-84），含**厘米级精确逆变换**
2. **球面几何**：两点距离、方位角、沿方位角偏移点
3. **经纬度 ⇄ 度分秒**、**WKT / GeoJSON** 格式互转
4. **高斯-克吕格投影**正反算（CGCS2000 / 北京54 / 西安80 / WGS-84，含 3°/6° 带号换算）
5. **地理编码**：百度 / 高德 / 腾讯三家的地址 ⇄ 坐标、IP 定位、高德官方坐标转换 API
6. **生产级细节**：多 key 自动轮询与配额摘除、进程内 LRU 缓存、统一错误体系、线程安全
7. **命令行工具**：单点/批量转换、CSV、GeoJSON 输出

要求 Ruby >= 2.7。零运行时依赖，仅使用标准库。

> **在线试用**（无需安装）: https://cheenwe.github.io/coordconver/ —— 纯前端实现，算法与 gem 数值一致。

## 安装

添加到 Gemfile：

```ruby
gem 'coordconver'
```

执行 `bundle`，或直接安装：

    $ gem install coordconver

## 坐标系转换

### 快速上手

```ruby
require 'coordconver'

wgs = [121.468738, 31.247138]         # WGS-84 (GPS 原始坐标)
Coordconver.wgs_gcj(*wgs)             # => [121.47327833883615, 31.2452165865549]  (GCJ-02, 高德/谷歌中国/腾讯)
Coordconver.wgs_bd(*wgs)              # => [121.47980789007566, 31.251157822142243] (BD-09, 百度)
```

### 全部转换方法

所有方法支持多种入参与出参：

```ruby
# 入参: (lng, lat) 双参 / Point / [lng, lat] / {lng:, lat:}
Coordconver.wgs_gcj(121.468738, 31.247138)
Coordconver.wgs_gcj(Coordconver.point(121.468738, 31.247138))
Coordconver.wgs_gcj([121.468738, 31.247138])

# 出参: 默认 [lng, lat]; as: :hash => {lng:, lat:}; as: :point => Point
Coordconver.wgs_gcj(121.468738, 31.247138, as: :hash)
# => {lng: 121.47327833883615, lat: 31.2452165865549}
```

| 坐标系 | 转换名称 | 方法 | 语义化别名 |
| ----- | ----- | ----- | ----- |
| BD-09 -> GCJ-02 | 百度 -> 谷歌、高德、腾讯 | `Coordconver.bd_gcj(lng, lat)` | `bd09_gcj02` |
| GCJ-02 -> BD-09 | 谷歌、高德、腾讯 -> 百度 | `Coordconver.gcj_bd(lng, lat)` | `gcj02_bd09` |
| GCJ-02 -> WGS-84 | 谷歌、高德、腾讯 -> 地球坐标 | `Coordconver.gcj_wgs(lng, lat)` | `gcj02_wgs84` |
| WGS-84 -> GCJ-02 | 地球坐标 -> 谷歌、高德、腾讯 | `Coordconver.wgs_gcj(lng, lat)` | `wgs84_gcj02` |
| BD-09 -> WGS-84 | 百度 -> 地球坐标 | `Coordconver.bd_wgs(lng, lat)` | `bd09_wgs84` |
| WGS-84 -> BD-09 | 地球坐标 -> 百度 | `Coordconver.wgs_bd(lng, lat)` | `wgs84_bd09` |

### 精确逆变换（厘米级）

`gcj_wgs` 是近似逆运算（误差米级）。`gcj_wgs_precise` 用迭代法求解，误差厘米级：

```ruby
g = Coordconver.wgs_gcj(121.468738, 31.247138)
Coordconver.gcj_wgs(*g)          # => [121.468753, 31.247151]  误差 ~1.6 米
Coordconver.gcj_wgs_precise(*g)  # => [121.468738, 31.247138]  误差 < 1e-7 度 (~1cm)
Coordconver.bd_wgs_precise(*bd)  # 百度坐标同理
```

### 批量转换

```ruby
points = [[121.468738, 31.247138], Coordconver.point(116.481499, 39.990475), { lng: 104.08, lat: 30.65 }]
Coordconver.transform(points, from: :wgs84, to: :gcj02, as: :hash)
```

`from`/`to` 支持 `:wgs84` `:gcj02` `:bd09`（及简写 `:wgs` `:gcj` `:bd`，大小写不限）。

### 坐标系说明

| 坐标系 | 说明 | 使用方 |
| ----- | ----- | ----- |
| WGS-84 | 国际标准，GPS/北斗芯片原始坐标 | iOS 原生定位、OSM、海外谷歌地图 |
| GCJ-02 | 国测局标准（火星坐标），WGS-84 加密所得 | 高德、腾讯、谷歌中国、搜搜、阿里云 |
| BD-09 | 百度标准，GCJ-02 再次加密所得 | 百度地图、百度 SDK |

## 球面几何

```ruby
# 两点球面距离(米), 两点需在同一坐标系下
Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416) # => 1068194.1

# 初始方位角(正北为 0°, 顺时针 0-360°)
Coordconver.bearing(116.397428, 39.90923, 121.473701, 31.230416)  # => 153.04...

# 从起点沿方位角移动指定距离后的坐标
Coordconver.destination_point(116.397428, 39.90923, 153.0, 100_000)
# => [116.92357, 39.106734]

# 判断坐标是否在中国境外(境外 WGS-84 与 GCJ-02 一致, 转换方法会原样返回)
Coordconver.out_of_china?(121.47, 31.25) # => false
```

## 经纬度与度分秒互转

```ruby
Coordconver.degree(38.65777, 104.08296)
# => ["38°39′27.97″", "104°4′58.66″"]

Coordconver.undegree("38°39′27.97″", "104°4′58.66″")
# => [38.657769, 104.082961]

# 单值转换, 第二个参数控制秒的小数位(默认 2 位, 传 0 可得整数秒)
Coordconver.cal_degree(38.65777)     # => "38°39′27.97″"

# 解析支持多种写法: 38°39′27.97″ / 38°39′27.97" / 38d39m27.97s / 38:39:27.97
# 负值按西经/南纬处理
Coordconver.cal_undegree("-38°39′27.97″") # => -38.657769
```

## WKT / GeoJSON

```ruby
Coordconver.parse_wkt("POINT (121.47 31.25)")   # => [121.47, 31.25]
Coordconver.to_wkt(121.47, 31.25)               # => "POINT (121.47 31.25)"

Coordconver.parse_geojson('{"type":"Point","coordinates":[121.47,31.25]}')  # => [121.47, 31.25]
# 也接受 Hash 与 Feature(自动取 geometry)
Coordconver.to_geojson(121.47, 31.25)           # => {"type"=>"Point", "coordinates"=>[121.47, 31.25]}

# 与坐标系转换自由组合
Coordconver.wgs_gcj(Coordconver.parse_wkt(wkt), as: :point)
```

## 高斯-克吕格投影（测绘）

经纬度 ⇄ 高斯平面坐标，支持 CGCS2000 / WGS-84 / 北京54(krassovsky) / 西安80(iag75) 椭球，正反算往返精度优于 1cm：

```ruby
# 正算: 默认 6° 带自动推算中央经线, 东坐标偏移 500km (测绘惯例)
Coordconver.gauss_kruger(121.47, 31.24, zone_width: 3)
# => [640045.58, 3458515.34]   (3° 带 40 带, 中央经线 120°)

# 指定中央经线 / 椭球
Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120, ellipsoid: :krassovsky)  # 北京54

# 反算: 中央经线必填
Coordconver.inverse_gauss_kruger(640045.58, 3458515.34, central_meridian: 120)
# => [121.47, 31.24]

# 带号与中央经线换算
Coordconver.zone_meridian(121.47)              # => [21, 123]  (6° 带)
Coordconver.zone_meridian(121.47, width: 3)    # => [40, 120]  (3° 带)
```

## 命令行工具

安装 gem 后可直接使用 `coordconver` 命令：

```bash
# 坐标系转换 (wgs2gcj / gcj2wgs / wgs2bd / bd2wgs / gcj2bd / bd2gcj)
coordconver wgs2gcj 121.468738 31.247138        # => 121.473278,31.245217
coordconver wgs2gcj 121.468738 31.247138 --json
coordconver wgs2gcj 121.468738 31.247138 --geojson

# 度分秒互转
coordconver dms 38.65777 104.08296
coordconver dec "38°39′27.97″" "104°4′58.66″"

# 距离 / 方位角 / 偏移点
coordconver dist 116.397428 39.90923 121.473701 31.230416
coordconver bearing 116.397428 39.90923 121.473701 31.230416   # => 153.04
coordconver dest 116.397428 39.90923 153 100000

# 高斯-克吕格
coordconver gk 121.47 31.24 --zone3             # => 640045.58,3458515.34
coordconver invgk 640045.58 3458515.34 --cm 120 # => 121.47,31.24

# 批量转换: 每行一条 "lng,lat"; --csv 自动跳过表头
cat points.txt | coordconver wgs2gcj
cat points.csv  | coordconver wgs2gcj --csv

# 地址 <-> 坐标 (需先配置 key, 见下文)
coordconver geo --gaode "北京方恒国际中心A座"
coordconver regeo --baidu 116.322987 39.983424 --cache
```

## 地址与坐标互转 (百度 / 高德 / 腾讯)

使用前需申请对应平台的 API Key：

- 百度地图开放平台: https://lbsyun.baidu.com/apiconsole/key （**服务端**类型 AK + IP 白名单；SN 校验类型需配置 `baidu_sn`）
- 高德开放平台: https://console.amap.com/dev/key/app （**Web 服务**类型）
- 腾讯位置服务: https://lbs.qq.com/dev/console/application/mine （启用 WebServiceAPI）

百度默认配额 6000 次/天；高德个人认证 5000 次/天，企业单 Key 可达 200 万次/天；腾讯个人 1 万次/天。**支持传入多个 key**：库会自动轮询，并在某个 key 配额超限/无效时自动摘除、切换下一个（冷却 5 分钟后自动恢复）。

### 配置

```ruby
require 'coordconver'

# 推荐: 全局配置块
Coordconver.configure do |config|
  config.baidu_map_aks = ["百度ak1", "百度ak2"]
  config.gaode_map_keys = ["高德key1", "高德key2"]
  config.tencent_map_keys = ["腾讯key1"]
  # config.baidu_sn = "SN校验密钥"   # 仅 AK 类型为"SN校验"时需要
  # config.cache = true              # 进程内缓存地理编码结果, 节省配额
  # config.cache_ttl = 3600          # 缓存秒数(默认 3600)
  # config.cache_size = 1024         # 缓存条目上限, LRU 淘汰(默认 1024)
  # config.open_timeout = 5          # 连接超时(秒)
  # config.read_timeout = 10         # 读取超时(秒)
end
```

或兼容旧写法：

```ruby
Coordconver::Client.new(["百度ak1", "百度ak2"], ["高德key1"], tencent_map_keys: ["腾讯key1"])
```

未配置 key 就调用 API 会抛出 `Coordconver::ConfigurationError`，错误信息会提示如何配置。

### 地理编码 (地址 -> 坐标)

```ruby
# 百度 (BD-09), 支持官方可选参数如 city:
Coordconver::Baidu.geo("百度大厦")["result"]["location"]
Coordconver::Baidu.geo_location("百度大厦")          # => [116.30775539540981, 40.05685561073758]

# 高德 (GCJ-02)
Coordconver::Gaode.geo_location("北京方恒国际中心A座") # => [116.480724, 39.989584]

# 腾讯 (GCJ-02)
Coordconver::Tencent.geo_location("北京市海淀区彩和坊路海淀西大街74号")
```

### 逆地理编码 (坐标 -> 地址)

```ruby
Coordconver::Baidu.regeo_address(116.322987, 39.983424)   # => "北京市海淀区中关村大街27号1101-08室"
Coordconver::Gaode.regeo_address(116.480881, 39.989410)   # => "北京市朝阳区望京街道方恒国际中心B座方恒国际中心"
Coordconver::Tencent.regeo_address(116.322987, 39.983424)

# 拿到的是 GPS(WGS-84) 坐标想直接查地址? 先转成对应坐标系:
gcj = Coordconver.wgs_gcj(lng, lat)
Coordconver::Gaode.regeo_address(*gcj)
```

注意坐标系统：百度接口收发 BD-09，高德/腾讯接口收发 GCJ-02；坐标类型可通过选项控制（如百度 `coordtype: "wgs84ll"`、高德 `extensions` 等，详见各家官方文档）。

### IP 定位

```ruby
Coordconver::Baidu.ip          # 当前出口 IP (BD-09)
Coordconver::Tencent.ip("8.8.8.8")  # 指定 IP (GCJ-02)
```

### 高德官方坐标转换 API

```ruby
# GPS/百度坐标 -> 高德坐标(官方权威转换, 单次最多 40 点)
Coordconver::Gaode.convert_location([121.468738, 31.247138], from: :gps)
# => [[121.473279, 31.245217]]
Coordconver::Gaode.convert_location([[121.46, 31.24], [116.39, 39.90]], from: :baidu)
```

### 错误处理

```ruby
begin
  Coordconver::Gaode.regeo_address(116.48, 39.98)
rescue Coordconver::ConfigurationError => e
  # 未配置 key
rescue Coordconver::ApiError => e
  # 所有 key 均无效或配额超限 (e.raw 可取到最后一次原始响应)
rescue Coordconver::NetworkError => e
  # 超时/连接失败/响应非 JSON (网络层已自动重试 3 次)
rescue Coordconver::Error => e
  # 基类, 兜底
end
```

服务端返回的其他业务错误（如地址不存在、参数非法）不抛异常，返回原始 JSON，通过 `status` 字段判断：百度 `status == 0`、高德 `status == "1"`、腾讯 `status == 0` 为成功。

## 升级说明 (0.x -> 1.x)

- 修复 `bd_wgs` 方向 bug（0.x 版本返回的是错误结果），并增加回归测试
- 百度地理编码升级到 Geocoding API v3（v2 接口已下线），默认走 HTTPS
- `cal_degree` 默认保留两位小数秒（`cal_degree(n, 0)` 可得旧版整数秒输出）
- 移除源码中硬编码的 key，调用 API 前必须先配置
- 支持 Ruby 2.7 ~ 3.4；CI 由 Travis 迁移至 GitHub Actions
- 1.1.0 起所有转换方法兼容 Point/数组/Hash 入参与 `as:` 出参，多 key 从随机取样改为轮询

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

在线试用页托管在 GitHub Pages（`docs/` 目录）。首次发布需在仓库 Settings -> Pages 将 Source 设为 `Deploy from a branch`，分支选 `master`、目录选 `/docs`。

## Contributing

欢迎提交 Bug 报告和 Pull Request：https://github.com/cheenwe/coordconver

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
