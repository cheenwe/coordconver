require 'test_helper'

class TencentTest < Minitest::Test
  def setup
    Coordconver::Geo::Configuration.reset!
    @captured = []
    Coordconver::Client.new([], [], tencent_map_keys: ["tencent_key1", "tencent_key2"])
  end

  def stub_get(response)
    original = Coordconver::Utils::Request.method(:get)
    captured = @captured
    Coordconver::Utils::Request.define_singleton_method(:get) do |url, params: nil|
      captured << { url: url, params: params }
      response
    end
    yield
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  def test_geo_builds_url_with_key
    response = { "status" => 0, "result" => { "location" => { "lng" => 116.3, "lat" => 39.9 } } }
    result = nil
    stub_get(response) do
      result = Coordconver::Tencent.geo("北京市海淀区彩和坊路海淀西大街74号")
    end
    assert_equal "https://apis.map.qq.com/ws/geocoder/v1/", @captured[0][:url]
    assert_equal "北京市海淀区彩和坊路海淀西大街74号", @captured[0][:params][:address]
    assert_includes ["tencent_key1", "tencent_key2"], @captured[0][:params][:key]
    assert_equal response, result
  end

  def test_regeo_uses_lat_lng_order
    response = { "status" => 0, "result" => { "address" => "北京市海淀区中关村大街27号" } }
    stub_get(response) do
      Coordconver::Tencent.regeo(116.322987, 39.983424)
    end
    assert_equal "39.983424,116.322987", @captured[0][:params][:location]
  end

  def test_ip
    stub_get({ "status" => 0, "result" => {} }) do
      Coordconver::Tencent.ip("8.8.8.8")
    end
    assert_equal "https://apis.map.qq.com/ws/location/v1/ip", @captured[0][:url]
    assert_equal "8.8.8.8", @captured[0][:params][:ip]
  end

  def test_geo_location_convenience
    response = { "status" => 0, "result" => { "location" => { "lng" => 116.3, "lat" => 39.9 } } }
    result = nil
    stub_get(response) do
      result = Coordconver::Tencent.geo_location("某地址")
    end
    assert_equal [116.3, 39.9], result
  end

  def test_regeo_address_prefers_recommend
    response = {
      "status" => 0,
      "result" => {
        "address" => "北京市海淀区中关村大街27号",
        "formatted_addresses" => { "recommend" => "海淀区中关村大街27号(中关村)" }
      }
    }
    result = nil
    stub_get(response) do
      result = Coordconver::Tencent.regeo_address(116.322987, 39.983424)
    end
    assert_equal "海淀区中关村大街27号(中关村)", result
  end

  def test_regeo_address_falls_back_to_address
    response = { "status" => 0, "result" => { "address" => "北京市海淀区中关村大街27号" } }
    result = nil
    stub_get(response) do
      result = Coordconver::Tencent.regeo_address(116.322987, 39.983424)
    end
    assert_equal "北京市海淀区中关村大街27号", result
  end

  def test_unconfigured_raises
    Coordconver::Geo::Configuration.reset!
    assert_raises(Coordconver::ConfigurationError) { Coordconver::Tencent.geo("某地址") }
  end
end
