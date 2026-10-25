# Changelog

## 1.1.0 (2026-10-25)

### 新增

- **厘米级精确逆变换**：`gcj_wgs_precise` / `bd_wgs_precise`（迭代法，误差 < 1e-7 度），原 `gcj_wgs`/`bd_wgs` 保留为近似版本（米级）。
- **球面几何**：`bearing`（初始方位角）、`destination_point`（沿方位角偏移点），与 `distance` 配套。
- **灵活的入参/出参**：所有转换方法支持 `Point` 结构 / `[lng, lat]` / `{lng:, lat:}` 单参调用，以及 `as: :hash` / `as: :point` 返回格式；新增 `Coordconver.point` 与 `Coordconver::Point`。
- **批量转换**：`Coordconver.transform(points, from:, to:, as:)`。
- **WKT / GeoJSON 支持**：`parse_wkt` / `to_wkt` / `parse_geojson` / `to_geojson`，可与坐标转换自由组合。
- **高斯-克吕格投影**：`gauss_kruger` / `inverse_gauss_kruger` 正反算（CGCS2000/WGS-84/北京54/西安80 椭球，往返精度优于 1cm），`zone_meridian` 3°/6° 带号与中央经线换算。
- **腾讯位置服务支持**：`Coordconver::Tencent` 的 `geo` / `regeo` / `ip` 及便捷方法，与百度/高德同等的多 key 轮询能力。
- **多 key 智能轮询**：从随机取样改为线程安全的 round-robin；识别配额超限/无效 key（百度 401/402/200/201/210，高德 10001/10003/10009/10044/20003，腾讯 110/112/120/121/199）后自动摘除并在冷却 5 分钟后恢复；全部 key 耗尽时抛出 `ApiError`。
- **进程内 LRU 缓存**：`config.cache = true` 开启（可配 `cache_ttl`/`cache_size`），重复的地理编码请求不再消耗配额。
- **高德官方坐标转换 API**：`Gaode.convert` / `convert_location`（GPS/百度 -> GCJ-02，单次最多 40 点）。
- **CLI 增强**：新增 `bearing` / `dest` / `gk` / `invgk` 子命令；`--csv`（表头自动跳过）、`--geojson`、`--cache`、`--tencent` 选项。
- **在线试用页**：`docs/` 目录新增纯前端 demo（GitHub Pages 托管），坐标转换/度分秒/距离方位角/高斯-克吕格算法的 JS 移植与 gem 数值一致，无需安装即可体验。
- 英文文档 `README.en.md`。

### 变更

- 百度/高德/腾讯 API 请求统一经 `Geo::Api` 调度层（缓存 + key 轮换），行为对调用方透明。
- `Configuration.reset!` 现在会同时重置 key 轮询状态与缓存。

## 1.0.0 (2026-10-25)

### 修复

- **`bd_wgs` 方向 bug**：0.x 版本的 `bd_wgs` 复用了 `wgs_bd` 的逻辑，返回结果方向完全错误。现已改为 `gcj_wgs(bd_gcj(...))` 并增加回归测试。
- `transformlng` 遗漏 return 导致结果依赖实现细节的问题。

### 变更（不兼容）

- 百度地理编码升级至 [Geocoding API v3](https://lbsyun.baidu.com/index.php?title=webapi/guide/webservice-geocoding)（旧 v2 接口已下线），默认走 HTTPS；`regeo` 使用 Reverse Geocoding API v3。
- 调用百度/高德 API 前必须先配置 key（`Coordconver.configure` 或 `Coordconver::Client.new`），未配置时抛出 `Coordconver::ConfigurationError`；移除了源码中硬编码的测试 key。
- `Coordconver.cal_degree` 默认输出保留两位小数秒（`"38°39′27.97″"`）；需要旧版整数秒输出时使用 `Coordconver.cal_degree(n, 0)`。
- `undegree`/`cal_undegree` 精度由 5 位小数提升至 6 位小数。
- 最低 Ruby 版本要求提升至 2.7。
- 移除 `Coordconver::Coordconver` 嵌套模块，转换方法直接定义在 `Coordconver` 单例上（原调用方式 `Coordconver.bd_gcj` 等不受影响）。
- 要求 RubyGems 发布启用 MFA。

### 新增

- `Coordconver.distance`：两点球面距离（Haversine，米）。
- `Coordconver.out_of_china?`：境外坐标判断，境外坐标 `wgs_gcj`/`gcj_wgs` 原样返回。
- 语义化别名：`wgs84_gcj02`、`gcj02_wgs84`、`gcj02_bd09`、`bd09_gcj02`、`wgs84_bd09`、`bd09_wgs84`。
- 度分秒解析支持多种写法（`38°39′27.97″` / `38d39m27.97s` / `38:39:27.97`）与负值（西经/南纬）。
- 命令行工具 `coordconver`：坐标系转换、度分秒互转、距离计算、stdin 批量转换、JSON 输出。
- 百度 SN 校验支持（`baidu_sn` 配置项）。
- 便捷方法：`Baidu.geo_location`、`Baidu.regeo_address`、`Gaode.geo_location`、`Gaode.regeo_address`。
- 统一错误体系：`Coordconver::Error` / `ConfigurationError` / `NetworkError` / `ApiError`。
- `Coordconver.configure` 全局配置块；`open_timeout` / `read_timeout` 可配置。
- HTTP 层：指数退避自动重试、非 2xx 判定、JSON 解析容错、请求头规范化。
- 测试全面离线化（stub 网络层），另提供 `COORDCONVER_LIVE_TEST=1` 门控的真实 API 联调测试；CI 由 Travis 迁移至 GitHub Actions（Ruby 2.7 ~ 3.4 矩阵）。

## 0.1.4

- 最后一个 0.x 版本。
