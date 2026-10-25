# Coordconver

[![CI](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml/badge.svg)](https://github.com/cheenwe/coordconver/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/coordconver.svg)](https://badge.fury.io/rb/coordconver)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A zero-dependency Ruby toolkit for Chinese map coordinates ([中文文档](README.md)):

1. **Offline coordinate conversion** between BD-09 (Baidu), GCJ-02 (Mars, used by Amap/Tencent/Google China) and WGS-84 (GPS), with a **centimeter-accurate iterative inverse**
2. **Spherical geometry**: distance, initial bearing, destination point
3. **Decimal degrees ⇄ DMS**, **WKT / GeoJSON** parsing and generation
4. **Gauss-Krüger projection** (CGCS2000 / Beijing54 / Xi'an80 / WGS-84, 3°/6° zones)
5. **Geocoding** via Baidu / Amap (Gaode) / Tencent Web APIs, plus Amap's official coordinate conversion API
6. **Production-ready**: automatic key rotation with quota failover, in-process LRU cache, unified error hierarchy, thread-safe
7. **CLI** for one-off and batch (CSV/GeoJSON) conversions

Requires Ruby >= 2.7. No runtime dependencies — standard library only.

> **Try it online** (no install needed): https://cheenwe.github.io/coordconver/ — a pure front-end demo with results identical to the gem.

## Installation

Add to your Gemfile:

```ruby
gem 'coordconver'
```

then `bundle`, or install directly:

    $ gem install coordconver

## Coordinate conversion

```ruby
require 'coordconver'

wgs = [121.468738, 31.247138]
Coordconver.wgs_gcj(*wgs)  # => [121.47327833883615, 31.2452165865549]
Coordconver.wgs_bd(*wgs)   # => [121.47980789007566, 31.251157822142243]
```

| Conversion | Method | Alias |
| ----- | ----- | ----- |
| BD-09 -> GCJ-02 | `Coordconver.bd_gcj(lng, lat)` | `bd09_gcj02` |
| GCJ-02 -> BD-09 | `Coordconver.gcj_bd(lng, lat)` | `gcj02_bd09` |
| GCJ-02 -> WGS-84 | `Coordconver.gcj_wgs(lng, lat)` | `gcj02_wgs84` |
| WGS-84 -> GCJ-02 | `Coordconver.wgs_gcj(lng, lat)` | `wgs84_gcj02` |
| BD-09 -> WGS-84 | `Coordconver.bd_wgs(lng, lat)` | `bd09_wgs84` |
| WGS-84 -> BD-09 | `Coordconver.wgs_bd(lng, lat)` | `wgs84_bd09` |

Every method accepts `(lng, lat)`, a `Coordconver.point(lng, lat)` struct, `[lng, lat]` or `{lng:, lat:}`, and returns `[lng, lat]` by default — pass `as: :hash` or `as: :point` for other shapes:

```ruby
Coordconver.wgs_gcj(121.468738, 31.247138, as: :hash)
# => {lng: 121.47327833883615, lat: 31.2452165865549}
```

### Precise inverse

The standard `gcj_wgs` is an approximate inverse (meter-level error). The iterative `gcj_wgs_precise` is accurate to ~1 cm:

```ruby
g = Coordconver.wgs_gcj(121.468738, 31.247138)
Coordconver.gcj_wgs_precise(*g)  # => [121.468738, 31.247138]
Coordconver.bd_wgs_precise(*bd)  # same for Baidu coordinates
```

### Batch conversion

```ruby
points = [[121.468738, 31.247138], Coordconver.point(116.481499, 39.990475), { lng: 104.08, lat: 30.65 }]
Coordconver.transform(points, from: :wgs84, to: :gcj02, as: :hash)
```

## Spherical geometry

```ruby
Coordconver.distance(116.397428, 39.90923, 121.473701, 31.230416) # => 1068194.1 (meters)
Coordconver.bearing(116.397428, 39.90923, 121.473701, 31.230416)  # => 153.04 (degrees from north)
Coordconver.destination_point(116.397428, 39.90923, 153.0, 100_000)
Coordconver.out_of_china?(121.47, 31.25) # => false
```

## DMS / WKT / GeoJSON

```ruby
Coordconver.degree(38.65777, 104.08296)         # => ["38°39′27.97″", "104°4′58.66″"]
Coordconver.undegree("38°39′27.97″", "104°4′58.66″")
Coordconver.cal_undegree("38:39:27.97")         # also 38d39m27.97s, negatives supported

Coordconver.parse_wkt("POINT (121.47 31.25)")   # => [121.47, 31.25]
Coordconver.to_wkt(121.47, 31.25)               # => "POINT (121.47 31.25)"
Coordconver.parse_geojson(geojson_hash_or_string)
Coordconver.to_geojson(121.47, 31.25)           # => {"type"=>"Point", "coordinates"=>[121.47, 31.25]}
```

## Gauss-Krüger projection

Forward/inverse Gauss-Krüger (transverse Mercator) for surveying workflows:

```ruby
Coordconver.gauss_kruger(121.47, 31.24, zone_width: 3)
# => [640045.58, 3458515.34]
Coordconver.gauss_kruger(121.47, 31.24, central_meridian: 120, ellipsoid: :krassovsky) # Beijing54
Coordconver.inverse_gauss_kruger(640045.58, 3458515.34, central_meridian: 120)
Coordconver.zone_meridian(121.47, width: 3)     # => [40, 120]
```

Ellipsoids: `:cgcs2000` (default), `:wgs84`, `:krassovsky` (Beijing54), `:iag75` (Xi'an80).

## Geocoding (Baidu / Amap / Tencent)

Get API keys from [Baidu](https://lbsyun.baidu.com/apiconsole/key) (server-side AK), [Amap](https://console.amap.com/dev/key/app) (Web service) or [Tencent LBS](https://lbs.qq.com/dev/console/application/mine). Pass multiple keys and the library rotates them automatically, skipping keys that hit quota limits (they recover after a 5-minute cooldown).

```ruby
Coordconver.configure do |config|
  config.baidu_map_aks = ["baidu-ak-1", "baidu-ak-2"]
  config.gaode_map_keys = ["amap-key-1"]
  config.tencent_map_keys = ["tencent-key-1"]
  # config.baidu_sn = "sn-secret"  # only for SN-signed AKs
  # config.cache = true            # in-process LRU cache to save quota
end

Coordconver::Baidu.geo_location("百度大厦")            # => [lng, lat] (BD-09)
Coordconver::Gaode.regeo_address(116.480881, 39.989410) # => "北京市朝阳区..." (GCJ-02 in)
Coordconver::Tencent.geo_location("北京市海淀区...")     # => [lng, lat] (GCJ-02)
Coordconver::Baidu.ip("8.8.8.8")

# Official Amap conversion API (up to 40 points per call)
Coordconver::Gaode.convert_location([121.468738, 31.247138], from: :gps)
```

Raw methods (`geo`/`regeo`) return the provider's full parsed JSON. Business errors are not raised — check `status` in the response (`0` for Baidu/Tencent, `"1"` for Amap).

### Error handling

```ruby
begin
  Coordconver::Gaode.regeo_address(116.48, 39.98)
rescue Coordconver::ConfigurationError # no key configured
rescue Coordconver::ApiError           # all keys exhausted/invalid (e.raw has the last response)
rescue Coordconver::NetworkError       # timeouts/HTTP failures (retried 3x internally)
rescue Coordconver::Error              # base class
end
```

## CLI

```bash
coordconver wgs2gcj 121.468738 31.247138     # => 121.473278,31.245217
coordconver dms 38.65777 104.08296
coordconver dist 116.397 39.909 121.474 31.230
coordconver bearing 116.397 39.909 121.474 31.230
coordconver dest 116.397 39.909 153 100000
coordconver gk 121.47 31.24 --zone3
cat points.txt | coordconver wgs2gcj --csv   # batch, header skipped
coordconver wgs2gcj 121.46 31.24 --geojson
coordconver geo --gaode "北京方恒国际中心A座"   # needs COORDCONVER_GAODE_KEY env var
coordconver regeo --baidu 116.322987 39.983424
```

Environment variables: `COORDCONVER_BAIDU_AK`, `COORDCONVER_GAODE_KEY`, `COORDCONVER_TENCENT_KEY` (comma-separated for multiple keys).

## Development

`bin/setup` to install dependencies, `rake test` to run the offline test suite. Live API tests are gated behind `COORDCONVER_LIVE_TEST=1` plus real keys. Install locally with `bundle exec rake install`; release with `bundle exec rake release`.

The online demo is served by GitHub Pages from the `docs/` directory. To enable it once: repo Settings -> Pages -> Source `Deploy from a branch`, branch `master`, folder `/docs`.

## Contributing

Bug reports and pull requests are welcome at https://github.com/cheenwe/coordconver.

## License

MIT License.
