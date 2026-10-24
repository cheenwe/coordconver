require 'test_helper'

class GeoTest < Minitest::Test
  def setup
    Coordconver::Geo::Configuration.reset!
    @captured = []
  end

  # 用单例方法替换/恢复代替 minitest stub, 兼容 minitest 5/6 (6.x 移除了模块级 stub)
  def stub_get(response = nil)
    original = Coordconver::Utils::Request.method(:get)
    captured = @captured
    Coordconver::Utils::Request.define_singleton_method(:get) do |url, params: nil|
      captured << { url: url, params: params }
      response || { "status" => 0, "result" => {} }
    end
    yield
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  def configure(baidu: ["test_ak1", "test_ak2"], gaode: ["test_key1"], opts: {})
    Coordconver::Client.new(baidu, gaode, opts)
  end

  def test_unconfigured_raises_clear_error
    error = assert_raises(Coordconver::ConfigurationError) do
      Coordconver::Baidu.geo("百度大厦")
    end
    assert_match(/configure|Client\.new/, error.message)
  end

  def test_missing_gaode_key_raises
    Coordconver::Client.new(["ak"], [])
    error = assert_raises(Coordconver::ConfigurationError) do
      Coordconver::Gaode.geo("某地址")
    end
    assert_match(/gaode_map_keys/, error.message)
  end

  def test_configure_block_style
    Coordconver.configure do |c|
      c.baidu_map_aks = ["ak1"]
      c.gaode_map_keys = ["key1"]
    end
    assert_equal ["ak1"], Coordconver::Geo::Configuration.settings[:baidu_map_aks]
    assert_equal ["key1"], Coordconver::Geo::Configuration.settings[:gaode_map_keys]
  ensure
    Coordconver::Geo::Configuration.reset!
  end

  def test_baidu_geo_builds_v3_url
    configure
    stub_get do
      Coordconver::Baidu.geo("百度大厦")
    end
    assert_equal "https://api.map.baidu.com/geocoding/v3/", @captured[0][:url]
    assert_equal "百度大厦", @captured[0][:params][:address]
    assert_includes ["test_ak1", "test_ak2"], @captured[0][:params][:ak]
  end

  def test_baidu_regeo_builds_v3_url
    configure
    stub_get do
      Coordconver::Baidu.regeo(116.322987, 39.983424)
    end
    assert_equal "https://api.map.baidu.com/reverse_geocoding/v3/", @captured[0][:url]
    assert_equal "39.983424,116.322987", @captured[0][:params][:location]
    assert_equal "bd09ll", @captured[0][:params][:coordtype]
  end

  def test_baidu_regeo_coordtype_option
    configure
    stub_get do
      Coordconver::Baidu.regeo(116.322987, 39.983424, coordtype: "wgs84ll")
    end
    assert_equal "wgs84ll", @captured[0][:params][:coordtype]
  end

  def test_baidu_sn_enabled
    configure(opts: { baidu_sn: "test_sk" })
    stub_get do
      Coordconver::Baidu.geo("百度大厦")
    end
    sn = @captured[0][:params][:sn]
    assert_match(/\A[0-9a-f]{32}\z/, sn)
  end

  def test_baidu_sn_absent_by_default
    configure
    stub_get do
      Coordconver::Baidu.geo("百度大厦")
    end
    refute @captured[0][:params].key?(:sn)
  end

  # 百度 SN 校验要求的 URI 编码: 等同 encodeURIComponent, / ? = 等也需编码
  def test_baidu_custom_uri_encode
    encoded = Coordconver::Baidu.send(:custom_uri_encode, "/geocoding/v3/?address=北京")
    assert_equal "%2Fgeocoding%2Fv3%2F%3Faddress%3D%E5%8C%97%E4%BA%AC", encoded
  end

  def test_baidu_geo_location_convenience
    configure
    response = {
      "status" => 0, "result" => { "location" => { "lng" => 116.3077, "lat" => 40.0568 } }
    }
    location = nil
    stub_get(response) do
      location = Coordconver::Baidu.geo_location("百度大厦")
    end
    assert_equal [116.3077, 40.0568], location
  end

  def test_gaode_geo_builds_url
    configure
    stub_get do
      Coordconver::Gaode.geo("北京方恒国际中心A座")
    end
    assert_equal "https://restapi.amap.com/v3/geocode/geo", @captured[0][:url]
    assert_equal "北京方恒国际中心A座", @captured[0][:params][:address]
    assert_equal "test_key1", @captured[0][:params][:key]
  end

  def test_gaode_regeo_builds_url
    configure
    stub_get do
      Coordconver::Gaode.regeo(116.480881, 39.989410)
    end
    assert_equal "https://restapi.amap.com/v3/geocode/regeo", @captured[0][:url]
    assert_equal "116.480881,39.98941", @captured[0][:params][:location]
  end

  # 兼容旧版本以 /geocode 结尾的 base_url 配置
  def test_gaode_legacy_base_url
    configure(opts: { gaode_base_url: "http://restapi.amap.com/v3/geocode" })
    stub_get do
      Coordconver::Gaode.geo("某地址")
    end
    assert_equal "http://restapi.amap.com/v3/geocode/geo", @captured[0][:url]
  end

  def test_gaode_geo_location_convenience
    configure
    response = { "status" => "1", "geocodes" => [{ "location" => "116.480724,39.989584" }] }
    result = nil
    stub_get(response) do
      result = Coordconver::Gaode.geo_location("北京方恒国际中心A座")
    end
    assert_equal [116.480724, 39.989584], result
  end

  def test_gaode_geo_location_empty_result
    configure
    response = { "status" => "1", "geocodes" => [], "count" => "0" }
    result = nil
    stub_get(response) do
      result = Coordconver::Gaode.geo_location("不存在的地址")
    end
    assert_nil result
  end

  def test_timeout_options_passthrough
    configure(opts: { open_timeout: 3, read_timeout: 4 })
    assert_equal 3, Coordconver::Geo::Configuration.settings[:open_timeout]
    assert_equal 4, Coordconver::Geo::Configuration.settings[:read_timeout]
  end
end
