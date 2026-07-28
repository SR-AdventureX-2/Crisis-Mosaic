import 'dart:async';
import 'dart:io';

import 'package:amap_flutter_location_plus/amap_flutter_location_plus.dart';
import 'package:amap_flutter_location_plus/amap_location_option.dart';
import 'package:amap_map/amap_map.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';
import 'package:x_amap_base/x_amap_base.dart';

import '../design_system.dart';

const _androidAmapKey = String.fromEnvironment('AMAP_ANDROID_KEY');
const _iosAmapKey = String.fromEnvironment('AMAP_IOS_KEY');
const _hangzhouCenter = LatLng(30.2741, 120.1551);

class AmapLocationMap extends StatefulWidget {
  const AmapLocationMap({
    super.key,
    required this.conflictResolved,
    required this.blindSpotResolved,
    required this.resolvedRoadColor,
  });

  final bool conflictResolved;
  final bool blindSpotResolved;
  final Color resolvedRoadColor;

  @override
  State<AmapLocationMap> createState() => _AmapLocationMapState();
}

class _AmapLocationMapState extends State<AmapLocationMap> {
  AMapController? _mapController;
  AMapFlutterLocation? _locationPlugin;
  StreamSubscription<Map<String, Object>>? _locationSubscription;
  LatLng? _currentPosition;
  String? _address;
  double? _accuracy;
  bool _privacyAccepted = false;
  bool _locating = false;
  String _statusText = '等待启用地图定位';

  bool get _isMobilePlatform => Platform.isAndroid || Platform.isIOS;

  bool get _hasPlatformKey {
    if (Platform.isAndroid) {
      return _androidAmapKey.trim().isNotEmpty;
    }
    if (Platform.isIOS) {
      return _iosAmapKey.trim().isNotEmpty;
    }
    return false;
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationPlugin?.stopLocation();
    _locationPlugin?.destroy();
    super.dispose();
  }

  Future<void> _requestConsentAndEnable() async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('启用高德地图与定位'),
        content: const Text(
          '为在首页地图显示你的当前位置，应用将调用高德地图与定位 SDK，并处理设备位置信息。仅在你点击同意后才会初始化 SDK 和申请系统定位权限。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('暂不启用'),
          ),
          FilledButton(
            key: const Key('accept-amap-privacy'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('同意并启用'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) {
      return;
    }

    AMapFlutterLocation.updatePrivacyShow(true, true);
    AMapFlutterLocation.updatePrivacyAgree(true);
    AMapFlutterLocation.setApiKey(_androidAmapKey, _iosAmapKey);
    AMapInitializer.updatePrivacyAgree(
      const AMapPrivacyStatement(
        hasContains: true,
        hasShow: true,
        hasAgree: true,
      ),
    );

    setState(() {
      _privacyAccepted = true;
      _statusText = '高德地图加载中';
    });
    await _locate();
  }

  Future<void> _locate() async {
    if (!_privacyAccepted || _locating) {
      return;
    }

    final requestedPermissions = await PermissionHandlerPlatform.instance
        .requestPermissions([Permission.locationWhenInUse]);
    final permission =
        requestedPermissions[Permission.locationWhenInUse] ??
        PermissionStatus.denied;
    if (!mounted) {
      return;
    }
    if (!permission.isGranted) {
      setState(() {
        _statusText = permission.isPermanentlyDenied
            ? '定位权限已被永久拒绝，请到系统设置中开启'
            : '未获得定位权限，无法显示当前位置';
      });
      return;
    }

    setState(() {
      _locating = true;
      _statusText = '正在获取高精度位置…';
    });

    final plugin = _locationPlugin ??= AMapFlutterLocation();
    _locationSubscription ??= plugin.onLocationChanged().listen(
      _handleLocationResult,
      onError: (Object error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _locating = false;
          _statusText = '定位服务异常：$error';
        });
      },
    );

    final option = AMapLocationOption(
      onceLocation: true,
      needAddress: true,
      locationMode: AMapLocationMode.Hight_Accuracy,
      desiredAccuracy: DesiredAccuracy.Best,
      pausesLocationUpdatesAutomatically: true,
    );
    plugin.setLocationOption(option);
    plugin.startLocation();
  }

  void _handleLocationResult(Map<String, Object> result) {
    if (!mounted) {
      return;
    }

    final errorCode = result['errorCode']?.toString();
    if (errorCode != null && errorCode.isNotEmpty && errorCode != '0') {
      _locationPlugin?.stopLocation();
      setState(() {
        _locating = false;
        _statusText = '定位失败（$errorCode）：${result['errorInfo'] ?? '请稍后重试'}';
      });
      return;
    }

    final latitude = _toDouble(result['latitude']);
    final longitude = _toDouble(result['longitude']);
    if (latitude == null || longitude == null) {
      return;
    }

    final position = LatLng(latitude, longitude);
    final description = result['description']?.toString().trim();
    final address = result['address']?.toString().trim();
    final resolvedAddress = description?.isNotEmpty == true
        ? description!
        : address?.isNotEmpty == true
        ? address!
        : '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

    _locationPlugin?.stopLocation();
    setState(() {
      _currentPosition = position;
      _address = resolvedAddress;
      _accuracy = _toDouble(result['accuracy']);
      _locating = false;
      _statusText = '当前位置已更新';
    });
    _mapController?.moveCamera(CameraUpdate.newLatLngZoom(position, 16));
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  void _onMapCreated(AMapController controller) {
    _mapController = controller;
    final position = _currentPosition;
    if (position != null) {
      controller.moveCamera(CameraUpdate.newLatLngZoom(position, 16));
    } else if (mounted) {
      setState(() => _statusText = _locating ? _statusText : '地图已就绪');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMobilePlatform) {
      return const _MapNotice(
        noticeKey: Key('amap-desktop-unsupported'),
        icon: Icons.phone_android_outlined,
        title: '请在 Android 或 iOS 设备查看地图',
        message: '高德地图 SDK Flutter 插件不支持当前桌面平台。',
      );
    }
    if (!_hasPlatformKey) {
      final variable = Platform.isAndroid ? 'AMAP_ANDROID_KEY' : 'AMAP_IOS_KEY';
      return _MapNotice(
        noticeKey: const Key('amap-key-missing'),
        icon: Icons.key_outlined,
        title: '还需要配置高德 Key',
        message: '运行时通过 --dart-define=$variable=你的Key 注入，即可加载真实地图。',
      );
    }
    if (!_privacyAccepted) {
      return _ConsentPanel(onEnable: _requestConsentAndEnable);
    }

    final position = _currentPosition;
    AMapInitializer.init(
      context,
      apiKey: const AMapApiKey(
        androidKey: _androidAmapKey,
        iosKey: _iosAmapKey,
      ),
    );
    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          Positioned.fill(
            child: AMapWidget(
              initialCameraPosition: const CameraPosition(
                target: _hangzhouCenter,
                zoom: 12,
              ),
              trafficEnabled: true,
              compassEnabled: true,
              scaleEnabled: true,
              onMapCreated: _onMapCreated,
              markers: {
                if (position != null)
                  Marker(
                    position: position,
                    infoWindow: InfoWindow(title: '我的位置', snippet: _address),
                  ),
              },
            ),
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 58,
            child: _MapStatusBadge(text: _statusText, loading: _locating),
          ),
          Positioned(
            right: 10,
            bottom: 12,
            child: Material(
              color: MosaicColors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: IconButton(
                key: const Key('relocate-amap'),
                tooltip: '重新定位',
                onPressed: _locating ? null : _locate,
                icon: const Icon(Icons.my_location, color: MosaicColors.blue),
              ),
            ),
          ),
          if (_address != null)
            Positioned(
              left: 10,
              right: 64,
              bottom: 12,
              child: _LocationSummary(address: _address!, accuracy: _accuracy),
            ),
        ],
      ),
    );
  }
}

class _ConsentPanel extends StatelessWidget {
  const _ConsentPanel({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('amap-consent-panel'),
      width: double.infinity,
      height: 250,
      color: MosaicColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 38,
              color: MosaicColors.blue,
            ),
            const SizedBox(height: 9),
            const Text(
              '使用高德地图显示当前位置',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MosaicColors.lead,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              '启用后将先展示隐私说明，再申请系统前台定位权限。',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MosaicColors.mutedText,
                height: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('enable-amap-location'),
              onPressed: onEnable,
              icon: const Icon(Icons.near_me_outlined),
              label: const Text('启用地图定位'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapNotice extends StatelessWidget {
  const _MapNotice({
    required this.noticeKey,
    required this.icon,
    required this.title,
    required this.message,
  });

  final Key noticeKey;
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: noticeKey,
      width: double.infinity,
      height: 230,
      color: MosaicColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
        child: Column(
          children: [
            Icon(icon, size: 38, color: MosaicColors.blue),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MosaicColors.lead,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: MosaicColors.mutedText,
                height: 1.5,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapStatusBadge extends StatelessWidget {
  const _MapStatusBadge({required this.text, required this.loading});

  final String text;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: withOpacityValue(MosaicColors.white, 0.94),
          borderRadius: BorderRadius.circular(999),
          boxShadow: MosaicShadow.subtle,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading) ...[
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 7),
              ] else ...[
                const Icon(
                  Icons.location_on,
                  size: 15,
                  color: MosaicColors.blue,
                ),
                const SizedBox(width: 5),
              ],
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MosaicColors.lead,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationSummary extends StatelessWidget {
  const _LocationSummary({required this.address, required this.accuracy});

  final String address;
  final double? accuracy;

  @override
  Widget build(BuildContext context) {
    final accuracyText = accuracy == null ? '' : ' · ±${accuracy!.round()}米';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: withOpacityValue(MosaicColors.white, 0.94),
        borderRadius: BorderRadius.circular(12),
        boxShadow: MosaicShadow.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        child: Text(
          '$address$accuracyText',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MosaicColors.lead,
            height: 1.35,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
