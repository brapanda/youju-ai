import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/catalog.dart';
import 'core/theme.dart';
import 'features/map/property_map.dart';
import 'ui.dart';

void main() => runApp(const YoujuApp());

class YoujuApp extends StatefulWidget {
  const YoujuApp({super.key});
  @override
  State<YoujuApp> createState() => _YoujuAppState();
}

class _YoujuAppState extends State<YoujuApp> {
  ThemeMode _mode = ThemeMode.light;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '悠居 Youju', debugShowCheckedModeBanner: false,
    locale: const Locale('zh'), supportedLocales: const [Locale('zh'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: youjuTheme(Brightness.light), darkTheme: youjuTheme(Brightness.dark), themeMode: _mode,
    home: AppShell(onTheme: () => setState(() => _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark)),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onTheme});
  final VoidCallback onTheme;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  final _saved = <String>{};
  SearchFilter _filter = const SearchFilter();
  final _search = TextEditingController();
  final _history = <String>[];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _favorite(Property p) => setState(() => _saved.contains(p.id) ? _saved.remove(p.id) : _saved.add(p.id));

  void _open(Property p) {
    setState(() { _history.remove(p.id); _history.insert(0, p.id); });
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PropertyPage(
      property:p, isFavorite: _saved.contains(p.id), onFavorite: () => _favorite(p),
    )));
  }

  void _query(String q) => setState(() => _filter = SearchFilter(query:q, kind:_filter.kind, type:_filter.type, minBeds:_filter.minBeds, maxPrice:_filter.maxPrice));

  void _kind(ListingKind? kind) => setState(() {
    _filter = SearchFilter(query:_filter.query, kind:kind, type:_filter.type, minBeds:_filter.minBeds);
  });

  Future<void> _filters() async {
    final result = await showModalBottomSheet<SearchFilter>(context:context, isScrollControlled:true,
      builder: (_) => FilterSheet(initial:_filter));
    if (result != null && mounted) setState(() { _filter = result; _search.text = result.query; });
  }

  @override
  Widget build(BuildContext context) {
    final results = _filter.apply(demoProperties);
    return Scaffold(
      extendBody:true,
      body: SafeArea(bottom:false, child: Column(children:[
        BrandHeader(onTheme:widget.onTheme, onProfile:() => setState(() => _tab=4)),
        Expanded(child: AnimatedSwitcher(duration:const Duration(milliseconds:180), child: switch (_tab) {
          0 => HomePage(key:const ValueKey('home'), properties:results, favorites:_saved, filter:_filter,
            search:_search, onQuery:_query, onFilter:_filters, onKind:_kind,
            onMap:() => setState(() => _tab=1), onAI:() => setState(() => _tab=2), onOpen:_open, onFavorite:_favorite,
            history:_history.map((id) => demoProperties.firstWhere((p) => p.id==id)).toList()),
          1 => Padding(key:const ValueKey('map'), padding:const EdgeInsets.only(bottom:108),
            child:Column(children:[
              Padding(padding:const EdgeInsets.fromLTRB(20,4,20,12), child:SearchBox(controller:_search, onChanged:_query, onFilter:_filters, filterCount:_filter.activeCount)),
              Expanded(child:PropertyMap(properties:results, favorites:_saved, onOpen:_open, onFavorite:_favorite, onFilter:_filters)),
            ])),
          2 => const ComingPage(key:ValueKey('ai'), icon:Icons.auto_awesome_outlined, title:'把理想的家，说给悠居听',
            description:'未来你可以用自然语言描述预算、通勤和生活偏好。\n本版先呈现界面，尚未连接 AI 服务。', suggestions:['80 万以内，适合家庭的联排别墅','帮我找地铁附近的两居室','想要采光好的市中心公寓']),
          3 => SavedPage(key:const ValueKey('saved'), properties:demoProperties.where((p) => _saved.contains(p.id)).toList(), onOpen:_open, onFavorite:_favorite, onExplore:() => setState(() => _tab=0)),
          _ => ProfilePage(key:const ValueKey('profile'), onTheme:widget.onTheme),
        })),
      ])),
      bottomNavigationBar: FloatingNavigation(index:_tab, onChanged:(i) => setState(() => _tab=i)),
    );
  }
}
