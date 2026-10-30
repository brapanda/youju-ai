import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import '../../core/catalog.dart';
import '../../core/theme.dart';

/// UI prototype. The catalog and positions remain synthetic even with Mapbox.
class PropertyMap extends StatefulWidget {
  const PropertyMap({
    super.key,
    required this.properties,
    required this.onOpen,
    required this.favorites,
    required this.onFavorite,
    required this.onFilter,
  });

  final List<Property> properties;
  final ValueChanged<Property> onOpen;
  final Set<String> favorites;
  final ValueChanged<Property> onFavorite;
  final VoidCallback onFilter;

  @override
  State<PropertyMap> createState() => _PropertyMapState();
}

class _PropertyMapState extends State<PropertyMap> {
  static const _token = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');
  static const _sourceId = 'youju-demo-properties';
  static const _layerId = 'youju-demo-points';
  mb.MapboxMap? _map;
  Property? _selected;
  List<Property>? _inBounds;
  Timer? _idleDebounce;
  String? _error;
  bool _listMode = false;
  bool _mapReady = false;
  bool _styleReady = false;
  bool? _lastDark;
  int _boundsRevision = 0;
  double _zoom = 10;

  List<Property> get _results => _inBounds ?? widget.properties;

  @override
  void initState() {
    super.initState();
    if (_token.isNotEmpty) mb.MapboxOptions.setAccessToken(_token);
    _selected = widget.properties.firstOrNull;
  }

  @override
  void didUpdateWidget(covariant PropertyMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIds(oldWidget.properties, widget.properties)) {
      _idleDebounce?.cancel();
      _boundsRevision++; // Invalidate results before awaiting a source update.
      _inBounds = null;
      _selected = widget.properties
          .where((p) => p.id == _selected?.id)
          .firstOrNull ?? widget.properties.firstOrNull;
      if (_styleReady) unawaited(_refreshSource());
    }
  }

  bool _sameIds(List<Property> a, List<Property> b) =>
      a.length == b.length && a.asMap().entries.every((e) => e.value.id == b[e.key].id);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dark = context.isDark;
    if (_lastDark != null && _lastDark != dark && _map != null) {
      _styleReady = false;
      unawaited(_changeStyle(dark));
    }
    _lastDark = dark;
  }

  Future<void> _changeStyle(bool dark) async {
    try {
      await _map?.setStyleURI(dark ? mb.MapboxStyles.DARK : mb.MapboxStyles.LIGHT);
    } catch (_) {
      _showError();
    }
  }

  Map<String, Object> get _geojson => {
    'type': 'FeatureCollection',
    'features': widget.properties.asMap().entries.map((entry) {
      final p = entry.value;
      return {
        'type': 'Feature',
        'id': entry.key,
        'properties': {'listingId': p.id},
        'geometry': {'type': 'Point', 'coordinates': [p.longitude, p.latitude]},
      };
    }).toList(),
  };

  Future<void> _onCreated(mb.MapboxMap map) async {
    _map = map;
    try {
      // Keep legal ornaments above the selected-property preview.
      await map.logo.updateSettings(mb.LogoSettings(marginBottom: 176));
      await map.attribution.updateSettings(mb.AttributionSettings(marginBottom: 176));
      map.addInteraction(mb.TapInteraction(
        mb.FeaturesetDescriptor(layerId: _layerId),
        (feature, _) {
          final id = feature.properties['listingId'];
          final p = widget.properties.where((p) => p.id == id).firstOrNull;
          if (mounted && p != null) setState(() => _selected = p);
        },
        radius: 20,
      ), interactionID: 'youju-property-tap');
    } catch (_) {
      _showError();
    }
  }

  Future<void> _onStyleLoaded(mb.StyleLoadedEventData _) async {
    final map = _map;
    if (map == null) return;
    try {
      await map.addSource(mb.GeoJsonSource(id: _sourceId, data: jsonEncode(_geojson)));
      await map.addLayer(mb.CircleLayer(
        id: _layerId,
        sourceId: _sourceId,
        circleColor: mint.toARGB32(),
        circleRadius: 11,
        circleStrokeColor: Colors.white.toARGB32(),
        circleStrokeWidth: 3,
      ));
      _styleReady = true;
      if (mounted) setState(() { _mapReady = true; _error = null; });
      _scheduleBounds();
    } catch (_) {
      _showError();
    }
  }

  Future<void> _refreshSource() async {
    try {
      await _map?.setStyleSourceProperty(_sourceId, 'data', jsonEncode(_geojson));
      _scheduleBounds();
    } catch (_) {
      _showError();
    }
  }

  void _scheduleBounds() {
    _idleDebounce?.cancel();
    final revision = ++_boundsRevision;
    _idleDebounce = Timer(const Duration(milliseconds: 300), () async {
      final map = _map;
      if (map == null || !_styleReady) return;
      try {
        final state = await map.getCameraState();
        final bounds = await map.coordinateBoundsForCamera(mb.CameraOptions(
          center: state.center, zoom: state.zoom, pitch: state.pitch,
          bearing: state.bearing, padding: state.padding,
        ));
        if (!mounted || revision != _boundsRevision) return;
        final west = bounds.southwest.coordinates.lng.toDouble();
        final east = bounds.northeast.coordinates.lng.toDouble();
        final south = bounds.southwest.coordinates.lat.toDouble();
        final north = bounds.northeast.coordinates.lat.toDouble();
        final visible = widget.properties.where((p) {
          final withinLongitude = west <= east
              ? p.longitude >= west && p.longitude <= east
              : p.longitude >= west || p.longitude <= east;
          return withinLongitude && p.latitude >= south && p.latitude <= north;
        }).toList();
        setState(() {
          _zoom = state.zoom;
          _inBounds = visible;
          if (!visible.any((p) => p.id == _selected?.id)) _selected = visible.firstOrNull;
        });
      } catch (_) {
        // Keep existing results rather than fabricating new camera bounds.
        if (mounted) setState(() => _error = '地图范围读取失败，可切换列表浏览');
      }
    });
  }

  void _showError() {
    if (mounted) setState(() => _error = 'Mapbox 暂时无法连接，请检查 token 与网络；可切换列表浏览。');
  }

  Future<void> _zoomBy(double delta) async {
    final map = _map;
    if (map == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('示意地图不提供真实缩放；连接 Mapbox 后可缩放与拖动。'),
      ));
      return;
    }
    try {
      await map.easeTo(mb.CameraOptions(zoom: (_zoom + delta).clamp(2, 19).toDouble()),
          mb.MapAnimationOptions(duration: 300));
    } catch (_) { _showError(); }
  }

  Future<void> _resetCamera() async {
    if (_map == null) {
      setState(() => _selected = widget.properties.firstOrNull);
      return;
    }
    try {
      await _map?.flyTo(mb.CameraOptions(
        center: mb.Point(coordinates: mb.Position(-79.34, 43.77)), zoom: 9.5,
      ), mb.MapAnimationOptions(duration: 700));
    } catch (_) { _showError(); }
  }

  @override
  void dispose() {
    _idleDebounce?.cancel();
    _boundsRevision++;
    // MapWidget owns the map controller. Removing our own interaction releases
    // the callback immediately; platform-view disposal releases the map itself.
    _map?.removeInteraction('youju-property-tap');
    _map = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 350;
      return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 16, 8),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(narrow ? 'EXPLORE WITH YOUJU' : 'EXPLORE YOUR NEIGHBOURHOOD', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, letterSpacing: 1.6, color: colors.primary, fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(narrow ? '地图找房' : '让地图，带你找到家', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: narrow ? 21 : 23, fontWeight: FontWeight.w700)),
          ])),
          IconButton(onPressed: widget.onFilter, tooltip: '筛选房源', icon: const Icon(Icons.tune_rounded)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Row(children: [
          Expanded(child: Text(narrow ? '${_results.length} 套演示房源' : '${_results.length} 套演示房源 · 多伦多及周边', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant))),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            segments: [
              ButtonSegment(value: false, icon: const Icon(Icons.map_outlined, size: 16), label: narrow ? null : const Text('地图'), tooltip: '地图'),
              ButtonSegment(value: true, icon: const Icon(Icons.view_list_outlined, size: 16), label: narrow ? null : const Text('列表'), tooltip: '列表'),
            ], selected: {_listMode}, onSelectionChanged: (v) => setState(() => _listMode = v.first),
          ),
        ]),
      ),
      Expanded(child: IndexedStack(index: _listMode ? 1 : 0, children: [_buildMap(context), _buildList(context)])),
    ]);
    });
  }

  Widget _buildList(BuildContext context) {
    if (_results.isEmpty) return _empty(context);
    final sorted = [..._results]..sort((a, b) {
      final kindOrder = a.kind.index.compareTo(b.kind.index);
      return kindOrder == 0 ? a.price.compareTo(b.price) : kindOrder;
    });
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
      itemCount: sorted.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => i == 0
          ? Text('出售／出租分组 · 组内价格由低到高 · 演示数据', style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 11))
          : _PropertyPreview(property: sorted[i - 1], onOpen: widget.onOpen,
              favorite: widget.favorites.contains(sorted[i - 1].id), onFavorite: widget.onFavorite),
    );
  }

  Widget _buildMap(BuildContext context) {
    final dark = context.isDark;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(borderRadius: BorderRadius.circular(28), child: LayoutBuilder(builder: (context, bounds) {
        final short = bounds.maxHeight < 350;
        return Stack(children: [
        Positioned.fill(child: _token.isEmpty
            ? _SchematicMap(properties: widget.properties, selected: _selected,
                onSelect: (p) => setState(() => _selected = p), dark: dark)
            : mb.MapWidget(
                key: const ValueKey('youju-mapbox'),
                styleUri: dark ? mb.MapboxStyles.DARK : mb.MapboxStyles.LIGHT,
                viewport: mb.CameraViewportState(
                  center: mb.Point(coordinates: mb.Position(-79.34, 43.77)), zoom: 9.5,
                ),
                onMapCreated: _onCreated,
                onStyleLoadedListener: _onStyleLoaded,
                onMapIdleListener: (_) => _scheduleBounds(),
                onMapLoadErrorListener: (_) => _showError(),
              )),
        Positioned(top: 16, left: 14, right: 14,
          child: Align(alignment: Alignment.topLeft, child: DecoratedBox(
            decoration: BoxDecoration(color: colors.surface.withValues(alpha: .95), borderRadius: BorderRadius.circular(14)),
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Text(_token.isEmpty ? '示意地图 · 非实际地理定位' : 'Mapbox 地图 · 房源坐标为演示', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
            ),
          )),
        ),
        if (_token.isNotEmpty && !_mapReady && _error == null)
          const Center(child: CircularProgressIndicator()),
        if (_error != null) Positioned(top: 64, left: 14, right: 14,
          child: Material(color: colors.errorContainer, borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: TextStyle(fontSize: 11, color: colors.onErrorContainer))),
          )),
        Positioned(right: 14, top: short ? 54 : 112, child: Flex(
          direction: short ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapButton(icon: Icons.add, label: '放大地图', onTap: () => _zoomBy(1), compact: short),
            SizedBox(width: short ? 6 : 0, height: short ? 0 : 6),
            _MapButton(icon: Icons.remove, label: '缩小地图', onTap: () => _zoomBy(-1), compact: short),
            SizedBox(width: short ? 6 : 0, height: short ? 0 : 12),
            _MapButton(icon: Icons.center_focus_strong_outlined, label: '回到默认范围', onTap: _resetCamera, compact: short),
          ],
        )),
        if (_selected != null) Positioned(left: 12, right: 12, bottom: 12,
          child: _PropertyPreview(property: _selected!, onOpen: widget.onOpen,
              favorite: widget.favorites.contains(_selected!.id), onFavorite: widget.onFavorite),
        ),
        if (_results.isEmpty) Positioned(left: 24, right: 24, bottom: 20,
          child: Material(color: colors.surface, borderRadius: BorderRadius.circular(20), child: _empty(context)),
        ),
      ]);
      })),
    );
  }

  Widget _empty(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.travel_explore, color: context.colors.primary, size: 30),
      const SizedBox(height: 10),
      const Text('这个范围暂无匹配房源'),
      const SizedBox(height: 4),
      Text('调整筛选或移动地图，继续发现。', style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant)),
      TextButton(onPressed: widget.onFilter, child: const Text('调整筛选')),
    ]),
  );
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.label, required this.onTap, this.compact = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface, borderRadius: BorderRadius.circular(15), elevation: 2,
    child: IconButton(onPressed: onTap, tooltip: label, constraints: compact ? const BoxConstraints.tightFor(width: 40, height: 40) : null, icon: Icon(icon, size: 20)),
  );
}

class _PropertyPreview extends StatelessWidget {
  const _PropertyPreview({required this.property, required this.onOpen, required this.favorite, required this.onFavorite});
  final Property property;
  final ValueChanged<Property> onOpen, onFavorite;
  final bool favorite;
  @override
  Widget build(BuildContext context) => Material(
    color: context.colors.surface, borderRadius: BorderRadius.circular(22), elevation: 4,
    shadowColor: Colors.black.withValues(alpha: .12), clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: () => onOpen(property), child: Padding(
      padding: const EdgeInsets.all(10), child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.asset(property.image, width: 76, height: 96, fit: BoxFit.cover)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(property.tag, style: TextStyle(fontSize: 10, color: context.colors.primary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(property.formattedPrice, maxLines: 1, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const SizedBox(height: 3),
          Text(property.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text('${property.beds} 卧 · ${property.baths} 卫 · ${property.sqft} sqft', style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant)),
          const SizedBox(height: 3),
          Text('演示数据', style: TextStyle(fontSize: 9, color: context.colors.onSurfaceVariant)),
        ])),
        IconButton(tooltip: favorite ? '取消收藏' : '收藏房源', onPressed: () => onFavorite(property),
          icon: Icon(favorite ? Icons.favorite : Icons.favorite_border, color: favorite ? mint : context.colors.onSurfaceVariant, size: 21)),
      ]),
    )),
  );
}

class _SchematicMap extends StatelessWidget {
  const _SchematicMap({required this.properties, required this.selected, required this.onSelect, required this.dark});
  final List<Property> properties;
  final Property? selected;
  final ValueChanged<Property> onSelect;
  final bool dark;
  static const _positions = [Offset(.64, .29), Offset(.40, .40), Offset(.28, .68), Offset(.47, .77), Offset(.20, .25), Offset(.74, .51)];

  int _positionIndex(Property p) {
    final index = demoProperties.indexWhere((d) => d.id == p.id);
    return index < 0 ? 0 : index % _positions.length;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, bounds) => Stack(children: [
    Positioned.fill(child: CustomPaint(painter: _MapPainter(dark))),
    for (final p in properties)
      Positioned(
        left: _positions[_positionIndex(p)].dx * (bounds.maxWidth - 88),
        top: 84 + _positions[_positionIndex(p)].dy * math.max(20, bounds.maxHeight - 84 - 180),
        child: Semantics(button: true, label: '${p.address} ${p.formattedPrice}',
          child: Material(color: selected?.id == p.id ? mint : context.colors.surface,
            elevation: selected?.id == p.id ? 5 : 1,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => onSelect(p),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Text(p.kind == ListingKind.rent ? '\$${p.price}' : '\$${(p.price / 1000).round()}K',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: selected?.id == p.id ? const Color(0xFF073A28) : context.colors.onSurface))),
            ),
          ),
        ),
      ),
  ]));
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.dark);
  final bool dark;
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = dark ? const Color(0xFF1A2B23) : const Color(0xFFE9EDE2));
    final park = Paint()..color = dark ? const Color(0xFF243F2E) : const Color(0xFFD5E5CD);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .06, h * .16, w * .27, h * .22), const Radius.circular(40)), park);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .68, h * .43, w * .35, h * .25), const Radius.circular(55)), park);
    final lake = Path()..moveTo(0, h * .86)..cubicTo(w * .25, h * .70, w * .5, h * .85, w, h * .71)..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(lake, Paint()..color = dark ? const Color(0xFF1F3C3E) : const Color(0xFFD3E5E9));
    final road = Paint()..color = dark ? const Color(0xFF35473B) : const Color(0xFFF9FAF4)..strokeWidth = 6..style = PaintingStyle.stroke;
    for (var i = -2; i < 10; i++) {
      final x = i * w / 6;
      canvas.drawLine(Offset(x, -10), Offset(x + w * .22, h), road);
    }
    for (var i = 1; i < 11; i++) {
      final y = i * h / 11;
      canvas.drawLine(Offset(-10, y + h * .08), Offset(w + 10, y - h * .04), road);
    }
    final highway = Path()..moveTo(-20, h * .52)..cubicTo(w * .3, h * .65, w * .55, h * .30, w + 20, h * .36);
    canvas.drawPath(highway, Paint()..color = dark ? const Color(0xFF61774D) : const Color(0xFFDFCF9F)..strokeWidth = 10..style = PaintingStyle.stroke);
    canvas.drawPath(highway, Paint()..color = dark ? const Color(0xFF344933) : const Color(0xFFFFF7DD)..strokeWidth = 5..style = PaintingStyle.stroke);
    void label(String text, double x, double y, {double fontSize = 11, double spacing = 1}) {
      final painter = TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, letterSpacing: spacing, color: dark ? const Color(0xFF8AA091) : const Color(0xFF8D9E8B), fontWeight: FontWeight.w500)), textDirection: TextDirection.ltr)..layout();
      painter.paint(canvas, Offset(x, y));
    }
    label('RICHMOND HILL', w * .10, h * .12, fontSize: 9);
    label('MARKHAM', w * .55, h * .20, fontSize: 13, spacing: 2);
    label('NORTH YORK', w * .30, h * .50, fontSize: 10);
    label('TORONTO', w * .23, h * .70, fontSize: 16, spacing: 3);
    label('LAKE ONTARIO', w * .45, h * .88, fontSize: 10, spacing: 2);
  }
  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.dark != dark;
}
