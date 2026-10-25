/**
 * coordconver 算法层 (JS 移植版)
 * 与 Ruby gem (lib/coordconver) 中的算法保持数值一致, 供在线试用页使用。
 * 纯函数, 无 DOM 依赖, 可在 Node 中独立测试。
 */
(function (root) {
  "use strict";

  var X_PI = (3.14159265358979324 * 3000.0) / 180.0;
  var PI = Math.PI;
  var SEMI_MAJOR_AXIS = 6378245.0; // GCJ-02 偏移算法 (克拉索夫斯基椭球)
  var EE = 0.00669342162296594323;
  var EARTH_RADIUS = 6371008.8;

  var ELLIPSOIDS = {
    cgcs2000: { a: 6378137.0, rf: 298.257222101 },
    wgs84: { a: 6378137.0, rf: 298.257223563 },
    krassovsky: { a: 6378245.0, rf: 298.3 }, // 北京54
    iag75: { a: 6378140.0, rf: 298.257 } // 西安80
  };

  function outOfChina(lng, lat) {
    return lng < 72.004 || lng > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  function transformLat(lng, lat) {
    var ret =
      -100.0 + 2.0 * lng + 3.0 * lat + 0.2 * lat * lat + 0.1 * lng * lat + 0.2 * Math.sqrt(Math.abs(lng));
    ret += ((20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0) / 3.0;
    ret += ((20.0 * Math.sin(lat * PI) + 40.0 * Math.sin((lat / 3.0) * PI)) * 2.0) / 3.0;
    ret += ((160.0 * Math.sin((lat / 12.0) * PI) + 320 * Math.sin((lat * PI) / 30.0)) * 2.0) / 3.0;
    return ret;
  }

  function transformLng(lng, lat) {
    var ret =
      300.0 + lng + 2.0 * lat + 0.1 * lng * lng + 0.1 * lng * lat + 0.1 * Math.sqrt(Math.abs(lng));
    ret += ((20.0 * Math.sin(6.0 * lng * PI) + 20.0 * Math.sin(2.0 * lng * PI)) * 2.0) / 3.0;
    ret += ((20.0 * Math.sin(lng * PI) + 40.0 * Math.sin((lng / 3.0) * PI)) * 2.0) / 3.0;
    ret += ((150.0 * Math.sin((lng / 12.0) * PI) + 300.0 * Math.sin((lng / 30.0) * PI)) * 2.0) / 3.0;
    return ret;
  }

  function wgs2gcj(lng, lat) {
    if (outOfChina(lng, lat)) return [lng, lat];
    var dLat = transformLat(lng - 105.0, lat - 35.0);
    var dLng = transformLng(lng - 105.0, lat - 35.0);
    var radlat = (lat / 180.0) * PI;
    var magic = 1 - EE * Math.sin(radlat) * Math.sin(radlat);
    var sqrtmagic = Math.sqrt(magic);
    dLat = (dLat * 180.0) / (((SEMI_MAJOR_AXIS * (1 - EE)) / (magic * sqrtmagic)) * PI);
    dLng = (dLng * 180.0) / ((SEMI_MAJOR_AXIS / sqrtmagic) * Math.cos(radlat) * PI);
    return [lng + dLng, lat + dLat];
  }

  function gcj2wgs(lng, lat) {
    if (outOfChina(lng, lat)) return [lng, lat];
    var dLat = transformLat(lng - 105.0, lat - 35.0);
    var dLng = transformLng(lng - 105.0, lat - 35.0);
    var radlat = (lat / 180.0) * PI;
    var magic = 1 - EE * Math.sin(radlat) * Math.sin(radlat);
    var sqrtmagic = Math.sqrt(magic);
    dLat = (dLat * 180.0) / (((SEMI_MAJOR_AXIS * (1 - EE)) / (magic * sqrtmagic)) * PI);
    dLng = (dLng * 180.0) / ((SEMI_MAJOR_AXIS / sqrtmagic) * Math.cos(radlat) * PI);
    var mglat = lat + dLat;
    var mglng = lng + dLng;
    return [lng * 2 - mglng, lat * 2 - mglat];
  }

  function gcj2wgsPrecise(lng, lat) {
    var w = [lng, lat];
    for (var i = 0; i < 5; i++) {
      var cur = wgs2gcj(w[0], w[1]);
      w = [w[0] + (lng - cur[0]), w[1] + (lat - cur[1])];
    }
    return w;
  }

  function gcj2bd(lng, lat) {
    var z = Math.sqrt(lng * lng + lat * lat) + 0.00002 * Math.sin(lat * X_PI);
    var theta = Math.atan2(lat, lng) + 0.000003 * Math.cos(lng * X_PI);
    return [z * Math.cos(theta) + 0.0065, z * Math.sin(theta) + 0.006];
  }

  function bd2gcj(lng, lat) {
    var x = lng - 0.0065;
    var y = lat - 0.006;
    var z = Math.sqrt(x * x + y * y) - 0.00002 * Math.sin(y * X_PI);
    var theta = Math.atan2(y, x) - 0.000003 * Math.cos(x * X_PI);
    return [z * Math.cos(theta), z * Math.sin(theta)];
  }

  function wgs2bd(lng, lat) {
    return gcj2bd.apply(null, wgs2gcj(lng, lat));
  }

  function bd2wgs(lng, lat) {
    return gcj2wgs.apply(null, bd2gcj(lng, lat));
  }

  function bd2wgsPrecise(lng, lat) {
    return gcj2wgsPrecise.apply(null, bd2gcj(lng, lat));
  }

  function distance(lng1, lat1, lng2, lat2) {
    var dlng = ((lng2 - lng1) * PI) / 180.0;
    var dlat = ((lat2 - lat1) * PI) / 180.0;
    var a =
      Math.sin(dlat / 2) * Math.sin(dlat / 2) +
      Math.cos((lat1 * PI) / 180.0) *
        Math.cos((lat2 * PI) / 180.0) *
        Math.sin(dlng / 2) *
        Math.sin(dlng / 2);
    return Math.round(2 * EARTH_RADIUS * Math.asin(Math.sqrt(a)) * 10) / 10;
  }

  function bearing(lng1, lat1, lng2, lat2) {
    var p1 = (lat1 * PI) / 180.0;
    var p2 = (lat2 * PI) / 180.0;
    var dl = ((lng2 - lng1) * PI) / 180.0;
    var y = Math.sin(dl) * Math.cos(p2);
    var x = Math.cos(p1) * Math.sin(p2) - Math.sin(p1) * Math.cos(p2) * Math.cos(dl);
    return (((Math.atan2(y, x) * 180.0) / PI) + 360) % 360;
  }

  function destinationPoint(lng, lat, bearingDeg, distanceM) {
    var d = distanceM / EARTH_RADIUS;
    var p1 = (lat * PI) / 180.0;
    var b = (bearingDeg * PI) / 180.0;
    var p2 = Math.asin(Math.sin(p1) * Math.cos(d) + Math.cos(p1) * Math.sin(d) * Math.cos(b));
    var l2 =
      (lng * PI) / 180.0 +
      Math.atan2(Math.sin(b) * Math.sin(d) * Math.cos(p1), Math.cos(d) - Math.sin(p1) * Math.sin(p2));
    var lon = (((l2 * 180.0) / PI) + 540) % 360 - 180;
    return [lon, (p2 * 180.0) / PI];
  }

  function toDMS(n, precision) {
    precision = precision === undefined ? 2 : precision;
    var sign = n < 0 ? "-" : "";
    n = Math.abs(n);
    var d = Math.floor(n);
    var m = (n - d) * 60;
    var s = (m - Math.floor(m)) * 60;
    if (precision === 0) {
      return sign + d + "°" + Math.floor(m) + "′" + Math.round(s) + "″";
    }
    return sign + d + "°" + Math.floor(m) + "′" + s.toFixed(precision) + "″";
  }

  function fromDMS(str) {
    var parts = String(str).match(/[-+]?\d+(?:\.\d+)?/g);
    if (!parts || parts.length === 0) return 0;
    var neg = /^\s*[-–]/.test(String(str)) || parseFloat(parts[0]) < 0;
    var deg = Math.abs(parseFloat(parts[0]));
    var min = parts.length > 1 ? parseFloat(parts[1]) : 0;
    var sec = parts.length > 2 ? parseFloat(parts[2]) : 0;
    var value = deg + min / 60.0 + sec / 3600.0;
    return Math.round((neg ? -value : value) * 1e6) / 1e6;
  }

  function zoneMeridian(lng, width) {
    if (width !== 3 && width !== 6) throw new Error("带宽仅支持 3 或 6 度");
    var zone = width === 6 ? Math.floor(lng / 6) + 1 : Math.round(lng / 3);
    return [zone, width === 6 ? zone * 6 - 3 : zone * 3];
  }

  function gaussKruger(lng, lat, opts) {
    opts = opts || {};
    var ellipsoid = ELLIPSOIDS[opts.ellipsoid || "cgcs2000"];
    if (!ellipsoid) throw new Error("未知椭球: " + opts.ellipsoid);
    var a = ellipsoid.a;
    var f = 1.0 / ellipsoid.rf;
    var cm =
      opts.centralMeridian !== undefined && opts.centralMeridian !== null
        ? opts.centralMeridian
        : zoneMeridian(lng, opts.zoneWidth || 6)[1];
    var fe = opts.falseEasting === undefined ? 500000 : opts.falseEasting;
    var fn = opts.falseNorthing || 0;
    var e2 = f * (2 - f);
    var ep2 = e2 / (1 - e2);

    var p = (lat * PI) / 180.0;
    var dl = ((lng - cm) * PI) / 180.0;
    var sinP = Math.sin(p);
    var cosP = Math.cos(p);
    var tanP = Math.tan(p);

    var n = a / Math.sqrt(1 - e2 * sinP * sinP);
    var t = tanP * tanP;
    var c = ep2 * cosP * cosP;
    var aa = dl * cosP;
    var m =
      a *
      ((1 - e2 / 4 - (3 * e2 * e2) / 64 - (5 * Math.pow(e2, 3)) / 256) * p -
        ((3 * e2) / 8 + (3 * e2 * e2) / 32 + (45 * Math.pow(e2, 3)) / 1024) * Math.sin(2 * p) +
        ((15 * e2 * e2) / 256 + (45 * Math.pow(e2, 3)) / 1024) * Math.sin(4 * p) -
        ((35 * Math.pow(e2, 3)) / 3072) * Math.sin(6 * p));

    var x =
      fe + n * (aa + ((1 - t + c) * Math.pow(aa, 3)) / 6 + ((5 - 18 * t + t * t + 72 * c - 58 * ep2) * Math.pow(aa, 5)) / 120);
    var y =
      fn +
      m +
      n * tanP * ((aa * aa) / 2 + ((5 - t + 9 * c + 4 * c * c) * Math.pow(aa, 4)) / 24 + ((61 - 58 * t + t * t + 600 * c - 330 * ep2) * Math.pow(aa, 6)) / 720);
    return [round4(x), round4(y)];
  }

  function inverseGaussKruger(x, y, opts) {
    opts = opts || {};
    var ellipsoid = ELLIPSOIDS[opts.ellipsoid || "cgcs2000"];
    if (!ellipsoid) throw new Error("未知椭球: " + opts.ellipsoid);
    if (opts.centralMeridian === undefined || opts.centralMeridian === null) {
      throw new Error("反算必须指定中央经线");
    }
    var a = ellipsoid.a;
    var f = 1.0 / ellipsoid.rf;
    var fe = opts.falseEasting === undefined ? 500000 : opts.falseEasting;
    var fn = opts.falseNorthing || 0;
    var e2 = f * (2 - f);
    var ep2 = e2 / (1 - e2);

    var m = y - fn;
    var mu = m / (a * (1 - e2 / 4 - (3 * e2 * e2) / 64 - (5 * Math.pow(e2, 3)) / 256));
    var e1 = (1 - Math.sqrt(1 - e2)) / (1 + Math.sqrt(1 - e2));

    var p1 =
      mu +
      ((3 * e1) / 2 - (27 * Math.pow(e1, 3)) / 32) * Math.sin(2 * mu) +
      ((21 * e1 * e1) / 16 - (55 * Math.pow(e1, 4)) / 32) * Math.sin(4 * mu) +
      ((151 * Math.pow(e1, 3)) / 96) * Math.sin(6 * mu) +
      ((1097 * Math.pow(e1, 4)) / 512) * Math.sin(8 * mu);

    var sinP1 = Math.sin(p1);
    var cosP1 = Math.cos(p1);
    var tanP1 = Math.tan(p1);
    var c1 = ep2 * cosP1 * cosP1;
    var t1 = tanP1 * tanP1;
    var n1 = a / Math.sqrt(1 - e2 * sinP1 * sinP1);
    var r1 = (a * (1 - e2)) / Math.pow(1 - e2 * sinP1 * sinP1, 1.5);
    var d = (x - fe) / n1;

    var p =
      p1 -
      ((n1 * tanP1) / r1) *
        ((d * d) / 2 -
          ((5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * ep2) * Math.pow(d, 4)) / 24 +
          ((61 + 90 * t1 + 298 * c1 + 45 * t1 * t1 - 252 * ep2 - 3 * c1 * c1) * Math.pow(d, 6)) / 720);
    var l =
      (d -
        ((1 + 2 * t1 + c1) * Math.pow(d, 3)) / 6 +
        ((5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * ep2 + 24 * t1 * t1) * Math.pow(d, 5)) / 120) /
      cosP1;

    var lng = ((l + (opts.centralMeridian * PI) / 180.0) * 180.0) / PI;
    var lat = (p * 180.0) / PI;
    return [round9(lng), round9(lat)];
  }

  function round4(v) {
    return Math.round(v * 10000) / 10000;
  }

  function round9(v) {
    return Math.round(v * 1e9) / 1e9;
  }

  var api = {
    outOfChina: outOfChina,
    wgs2gcj: wgs2gcj,
    gcj2wgs: gcj2wgs,
    gcj2wgsPrecise: gcj2wgsPrecise,
    gcj2bd: gcj2bd,
    bd2gcj: bd2gcj,
    wgs2bd: wgs2bd,
    bd2wgs: bd2wgs,
    bd2wgsPrecise: bd2wgsPrecise,
    distance: distance,
    bearing: bearing,
    destinationPoint: destinationPoint,
    toDMS: toDMS,
    fromDMS: fromDMS,
    zoneMeridian: zoneMeridian,
    gaussKruger: gaussKruger,
    inverseGaussKruger: inverseGaussKruger
  };

  if (typeof module !== "undefined" && module.exports) {
    module.exports = api;
  } else {
    root.CC = api;
  }
})(typeof self !== "undefined" ? self : this);
