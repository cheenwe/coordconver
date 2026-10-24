require 'test_helper'

# 在线联调测试, 默认跳过。需要真实 API key 时执行:
#   COORDCONVER_LIVE_TEST=1 \
#   COORDCONVER_BAIDU_AK=你的百度ak \
#   COORDCONVER_GAODE_KEY=你的高德key \
#   bundle exec rake test
class LiveApiTest < Minitest::Test
  def setup
    skip "设置 COORDCONVER_LIVE_TEST=1 并提供真实 API key 后启用" unless ENV["COORDCONVER_LIVE_TEST"]
  end

  def test_gaode_geo_and_regeo
    skip "缺少 COORDCONVER_GAODE_KEY" unless ENV["COORDCONVER_GAODE_KEY"]

    Coordconver.configure { |c| c.gaode_map_keys = ENV["COORDCONVER_GAODE_KEY"].split(",").map(&:strip) }
    location = Coordconver::Gaode.geo_location("北京方恒国际中心A座")
    refute_nil location, "高德 geo 应解析出坐标"
    assert_in_delta 116.48, location[0], 0.01

    address = Coordconver::Gaode.regeo_address(location[0], location[1])
    refute_nil address, "高德 regeo 应解析出地址"
    assert_match(/北京/, address)
  end

  def test_baidu_geo_and_regeo
    skip "缺少 COORDCONVER_BAIDU_AK" unless ENV["COORDCONVER_BAIDU_AK"]

    Coordconver.configure { |c| c.baidu_map_aks = ENV["COORDCONVER_BAIDU_AK"].split(",").map(&:strip) }
    location = Coordconver::Baidu.geo_location("百度大厦")
    refute_nil location, "百度 geo 应解析出坐标"
    assert_in_delta 116.3, location[0], 0.05

    address = Coordconver::Baidu.regeo_address(116.322987, 39.983424)
    refute_nil address, "百度 regeo 应解析出地址"
    assert_match(/北京|海淀/, address)
  end
end
