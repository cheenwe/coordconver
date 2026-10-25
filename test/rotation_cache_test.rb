require 'test_helper'

class RotationCacheTest < Minitest::Test
  def setup
    Coordconver::Geo::Configuration.reset!
    @captured = []
  end

  def stub_get_sequence(responses)
    calls = 0
    original = Coordconver::Utils::Request.method(:get)
    Coordconver::Utils::Request.define_singleton_method(:get) do |url, params: nil|
      resp = responses[calls] or raise "多余的请求: 第 #{calls + 1} 次 #{url}"
      calls += 1
      resp
    end
    yield
    calls
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  # ---------- KeyPool ----------

  def test_key_pool_round_robin
    pool = Coordconver::Geo::KeyPool.new
    keys = %w[k1 k2 k3]
    assert_equal "k1", pool.next_key(:gaode, keys)
    assert_equal "k2", pool.next_key(:gaode, keys)
    assert_equal "k3", pool.next_key(:gaode, keys)
    assert_equal "k1", pool.next_key(:gaode, keys)
  end

  def test_key_pool_mark_bad_skips_key
    pool = Coordconver::Geo::KeyPool.new
    keys = %w[k1 k2]
    pool.mark_bad(:gaode, "k1")
    assert_equal "k2", pool.next_key(:gaode, keys)
    assert_equal "k2", pool.next_key(:gaode, keys)
  end

  def test_key_pool_all_disabled_raises
    pool = Coordconver::Geo::KeyPool.new
    keys = %w[k1]
    pool.mark_bad(:gaode, "k1")
    assert_raises(Coordconver::ApiError) { pool.next_key(:gaode, keys) }
  end

  def test_key_pool_cooldown_recovers
    pool = Coordconver::Geo::KeyPool.new
    pool.mark_bad(:gaode, "k1")
    assert pool.disabled?(:gaode, "k1")
    # 模拟冷却时间已过
    pool.instance_variable_get(:@disabled_at)[[:gaode, "k1"]] = Time.now - (Coordconver::Geo::KeyPool::COOLDOWN + 1)
    refute pool.disabled?(:gaode, "k1")
    assert_equal "k1", pool.next_key(:gaode, %w[k1])
  end

  def test_key_pool_isolated_per_provider
    pool = Coordconver::Geo::KeyPool.new
    pool.mark_bad(:gaode, "k1")
    assert_equal "k1", pool.next_key(:baidu, %w[k1])
  end

  # ---------- Api 轮换 ----------

  def test_api_rotates_to_next_key_on_quota_error
    Coordconver::Client.new(["bad_key", "good_key"], [])
    bad = { "status" => 401, "message" => "quota" }
    good = { "status" => 0, "result" => { "location" => { "lng" => 116.3, "lat" => 39.9 } } }

    calls = stub_get_sequence([bad, good]) do
      result = Coordconver::Baidu.geo("百度大厦")
      assert_equal good, result
    end
    assert_equal 2, calls, "应轮换 key 重试一次"
  end

  def test_api_raises_when_all_keys_exhausted
    Coordconver::Client.new(["bad1", "bad2"], [])
    bad = { "status" => 401 }

    error = nil
    calls = stub_get_sequence([bad, bad]) do
      error = assert_raises(Coordconver::ApiError) { Coordconver::Baidu.geo("百度大厦") }
    end
    assert_equal 2, calls
    assert_match(/所有 2 个 key/, error.message)
    assert_equal bad, error.raw
  end

  def test_api_does_not_rotate_on_non_key_errors
    Coordconver::Client.new(["ak1"], [])
    param_error = { "status" => 2, "msg" => "参数错误" } # 非配额类错误, 原样返回
    calls = stub_get_sequence([param_error]) do
      result = Coordconver::Baidu.geo("")
      assert_equal param_error, result
    end
    assert_equal 1, calls
  end

  def test_gaode_rotation_on_infocode
    Coordconver::Client.new([], ["k1", "k2"])
    bad = { "status" => "0", "infocode" => "10003", "info" => "DAILY_QUERY_OVER_LIMIT" }
    good = { "status" => "1", "geocodes" => [{ "location" => "116.48,39.98" }] }
    calls = stub_get_sequence([bad, good]) do
      assert_equal good, Coordconver::Gaode.geo("某地址")
    end
    assert_equal 2, calls
  end

  # ---------- Cache ----------

  def test_cache_disabled_by_default
    Coordconver::Client.new(["ak"], [])
    refute Coordconver::Geo::Cache.enabled?
  end

  def test_cache_prevents_second_request
    Coordconver::Client.new(["ak"], [], cache: true, cache_ttl: 60)
    good = { "status" => 0, "result" => { "location" => { "lng" => 116.3, "lat" => 39.9 } } }

    calls = stub_get_sequence([good]) do
      Coordconver::Baidu.geo_location("百度大厦")
      assert_equal [116.3, 39.9], Coordconver::Baidu.geo_location("百度大厦")
    end
    assert_equal 1, calls, "命中缓存不应再发请求"
  ensure
    Coordconver::Geo::Cache.clear!
  end

  def test_cache_respects_ttl
    Coordconver::Client.new(["ak"], [], cache: true, cache_ttl: -1) # 立即过期
    good = { "status" => 0, "result" => {} }

    calls = stub_get_sequence([good, good]) do
      Coordconver::Baidu.geo("百度大厦")
      Coordconver::Baidu.geo("百度大厦")
    end
    assert_equal 2, calls, "过期缓存不应命中"
  ensure
    Coordconver::Geo::Cache.clear!
  end

  def test_cache_lru_eviction
    Coordconver::Client.new(["ak"], [], cache: true, cache_size: 2)
    cache = Coordconver::Geo::Cache
    cache.set(:a, 1)
    cache.set(:b, 2)
    cache.set(:c, 3) # 超出容量, a 被淘汰
    assert_nil cache.get(:a)
    assert_equal 2, cache.get(:b)
    assert_equal 3, cache.get(:c)
  ensure
    Coordconver::Geo::Cache.clear!
  end

  # ---------- 便捷方法与批量接口 ----------

  def test_gaode_convert
    Coordconver::Client.new([], ["k1"])
    response = { "status" => "1", "info" => "OK", "locations" => "121.473279,31.245217" }
    original = Coordconver::Utils::Request.method(:get)
    captured = @captured
    Coordconver::Utils::Request.define_singleton_method(:get) do |url, params: nil|
      captured << { url: url, params: params }
      response
    end
    result = Coordconver::Gaode.convert([121.468738, 31.247138], from: :gps)
    assert_equal response, result
    assert_equal "121.468738,31.247138", captured[0][:params][:locations]
    assert_equal "gps", captured[0][:params][:coordsys]
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  def test_gaode_convert_url_and_params
    Coordconver::Client.new([], ["k1"])
    response = { "status" => "1", "locations" => "a,b" }
    original = Coordconver::Utils::Request.method(:get)
    captured = @captured
    Coordconver::Utils::Request.define_singleton_method(:get) do |url, params: nil|
      captured << { url: url, params: params }
      response
    end
    Coordconver::Gaode.convert([[121.46, 31.24], [116.39, 39.90]], from: :baidu)
    assert_equal "https://restapi.amap.com/v3/assistant/coordinate/convert", captured[0][:url]
    assert_equal "121.46,31.24;116.39,39.9", captured[0][:params][:locations]
    assert_equal "baidu", captured[0][:params][:coordsys]
    assert_equal "k1", captured[0][:params][:key]
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  def test_gaode_convert_location
    Coordconver::Client.new([], ["k1"])
    response = { "status" => "1", "locations" => "121.473279,31.245217;116.487585,39.991754" }
    original = Coordconver::Utils::Request.method(:get)
    Coordconver::Utils::Request.define_singleton_method(:get) { |url, params: nil| response }
    result = Coordconver::Gaode.convert_location([[121.46, 31.24], [116.39, 39.90]], from: :gps)
    assert_equal [[121.473279, 31.245217], [116.487585, 39.991754]], result
  ensure
    Coordconver::Utils::Request.define_singleton_method(:get, original)
  end

  def test_gaode_convert_invalid_coordsys
    Coordconver::Client.new([], ["k1"])
    assert_raises(ArgumentError) { Coordconver::Gaode.convert([121.46, 31.24], from: :mars) }
  end

  def test_gaode_convert_too_many_points
    Coordconver::Client.new([], ["k1"])
    many = Array.new(41) { |i| [100.0 + i * 0.1, 30.0] }
    assert_raises(ArgumentError) { Coordconver::Gaode.convert(many) }
  end
end
