import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/catalog.dart';
import 'core/theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.onTheme, required this.onProfile});
  final VoidCallback onTheme, onProfile;
  @override
  Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.fromLTRB(24,12,20,14),
    child:Row(children:[
      Container(width:38,height:38,decoration:BoxDecoration(color:mint,borderRadius:BorderRadius.circular(13)),child:const Icon(Icons.roofing_rounded,color:Color(0xFF063B29),size:28)),
      const SizedBox(width:10),
      Text('悠居',style:TextStyle(fontSize:22,fontWeight:FontWeight.w800,color:context.colors.onSurface)),
      const SizedBox(width:7),
      Text('YOUJU',style:TextStyle(fontSize:11,letterSpacing:2,fontWeight:FontWeight.w600,color:context.colors.onSurfaceVariant)),
      const Spacer(),
      IconButton(key:const Key('theme-toggle'),tooltip:context.isDark?'切换浅色模式':'切换深色模式',onPressed:onTheme,icon:Icon(context.isDark?Icons.light_mode_outlined:Icons.dark_mode_outlined,size:21)),
      IconButton(tooltip:'个人页面',onPressed:onProfile,icon:const Icon(Icons.person_outline_rounded,size:23)),
    ]),
  );
}

class FloatingNavigation extends StatelessWidget {
  const FloatingNavigation({super.key, required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    const labels=['首页','地图','AI 找房','收藏','我的'];
    const icons=[Icons.home_outlined,Icons.map_outlined,Icons.auto_awesome_outlined,Icons.favorite_border_rounded,Icons.person_outline_rounded];
    return SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(20,6,20,14),
      child:Center(heightFactor:1,child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:540),
        child:Container(padding:const EdgeInsets.all(7),height:76,
          decoration:BoxDecoration(color:context.isDark?const Color(0xF21B2822):const Color(0xF2223029),borderRadius:BorderRadius.circular(40),border:Border.all(color:Colors.white.withValues(alpha:.09)),boxShadow:[BoxShadow(color:Colors.black.withValues(alpha:.15),blurRadius:28,offset:const Offset(0,8))]),
          child:Row(children:List.generate(5,(i) => Expanded(child:Semantics(selected:i==index,button:true,label:labels[i],
            child:InkWell(key:Key('nav-$i'),borderRadius:BorderRadius.circular(32),onTap:() => onChanged(i),
              child:AnimatedContainer(duration:const Duration(milliseconds:200),decoration:BoxDecoration(color:i==index?mint:Colors.transparent,borderRadius:BorderRadius.circular(32)),
                child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icons[i],size:24,color:i==index?const Color(0xFF073B2B):const Color(0xFFB5C2BA)),const SizedBox(height:3),Text(labels[i],style:TextStyle(fontSize:10,fontWeight:i==index?FontWeight.w700:FontWeight.w400,color:i==index?const Color(0xFF073B2B):const Color(0xFFB5C2BA)))])),
            ),
          )))),
        ),
      )),
    ));
  }
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key,required this.controller,required this.onChanged,required this.onFilter,this.filterCount=0});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilter;
  final int filterCount;
  @override
  Widget build(BuildContext context) => Row(children:[
    Expanded(child:TextField(key:const Key('property-search'),controller:controller,onChanged:onChanged,
      decoration:InputDecoration(hintText:'搜索城市、社区或地址',prefixIcon:const Icon(Icons.search_rounded,size:23),suffixIcon:controller.text.isEmpty?null:IconButton(tooltip:'清空搜索',onPressed:(){controller.clear();onChanged('');},icon:const Icon(Icons.close_rounded,size:18))))),
    const SizedBox(width:10),
    Badge(isLabelVisible:filterCount>0,label:Text('$filterCount'),child:IconButton.filledTonal(key:const Key('open-filters'),tooltip:'筛选房源',onPressed:onFilter,style:IconButton.styleFrom(padding:const EdgeInsets.all(17),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17))),icon:const Icon(Icons.tune_rounded,size:22))),
  ]);
}

class HomePage extends StatelessWidget {
  const HomePage({super.key,required this.properties,required this.favorites,required this.filter,required this.search,required this.onQuery,required this.onFilter,required this.onKind,required this.onMap,required this.onAI,required this.onOpen,required this.onFavorite,required this.history});
  final List<Property> properties,history;
  final Set<String> favorites;
  final SearchFilter filter;
  final TextEditingController search;
  final ValueChanged<String> onQuery;
  final ValueChanged<ListingKind?> onKind;
  final VoidCallback onFilter,onMap,onAI;
  final ValueChanged<Property> onOpen,onFavorite;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding:const EdgeInsets.only(bottom:120),
    child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1080),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Padding(padding:const EdgeInsets.fromLTRB(24,10,24,20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Icon(Icons.location_on_outlined,size:15,color:context.colors.primary),const SizedBox(width:4),Text('大多伦多地区',style:TextStyle(fontSize:12,color:context.colors.onSurfaceVariant)),const SizedBox(width:4),Icon(Icons.keyboard_arrow_down_rounded,size:16,color:context.colors.onSurfaceVariant),const Spacer(),const DemoBadge()]),
        const SizedBox(height:15),
        const Text('好生活，从这里开始。',style:TextStyle(fontSize:28,fontWeight:FontWeight.w800,letterSpacing:-.8,height:1.35)),
        const SizedBox(height:6),
        Text('在喜欢的城市，找到属于你的家。',style:TextStyle(fontSize:13,color:context.colors.onSurfaceVariant)),
        const SizedBox(height:22),
        SearchBox(controller:search,onChanged:onQuery,onFilter:onFilter,filterCount:filter.activeCount),
        const SizedBox(height:12),
        Wrap(spacing:8,children:[
          _KindChip(label:'全部房源',selected:filter.kind==null,onTap:()=>onKind(null)),
          _KindChip(label:'买房',selected:filter.kind==ListingKind.sale,onTap:()=>onKind(ListingKind.sale)),
          _KindChip(label:'租房',selected:filter.kind==ListingKind.rent,onTap:()=>onKind(ListingKind.rent)),
        ]),
      ])),
      Padding(padding:const EdgeInsets.symmetric(horizontal:24),child:_Hero(onMap:onMap)),
      Padding(padding:const EdgeInsets.symmetric(horizontal:18,vertical:22),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
        _QuickAction(icon:Icons.cottage_outlined,label:'精选出售',onTap:(){onKind(ListingKind.sale);}),
        _QuickAction(icon:Icons.key_outlined,label:'品质出租',onTap:(){onKind(ListingKind.rent);}),
        _QuickAction(icon:Icons.map_outlined,label:'地图找房',onTap:onMap),
        _QuickAction(icon:Icons.auto_awesome_outlined,label:'AI 找房',onTap:onAI),
      ])),
      Padding(padding:const EdgeInsets.fromLTRB(24,2,24,15),child:SectionTitle(title:'为你发现',subtitle:'${properties.length} 套演示房源',action:'地图探索',onAction:onMap)),
      if(properties.isEmpty) const Padding(padding:EdgeInsets.all(28),child:EmptyState(icon:Icons.search_off_rounded,title:'暂时没有匹配的房源',description:'试试其他地址，或调整筛选条件。'))
      else SizedBox(height:306,child:ListView.separated(padding:const EdgeInsets.symmetric(horizontal:24),scrollDirection:Axis.horizontal,itemCount:properties.length,separatorBuilder:(_,index)=>const SizedBox(width:16),itemBuilder:(context,i)=>SizedBox(width:MediaQuery.sizeOf(context).width<380?268:292,child:PropertyCard(property:properties[i],saved:favorites.contains(properties[i].id),onOpen:()=>onOpen(properties[i]),onFavorite:()=>onFavorite(properties[i]))))),
      Padding(padding:const EdgeInsets.fromLTRB(24,26,24,16),child:_AIInvitation(onTap:onAI)),
      if(history.isNotEmpty)...[
        const Padding(padding:EdgeInsets.fromLTRB(24,10,24,16),child:SectionTitle(title:'最近浏览',subtitle:'再看看心动的家')),
        ...history.take(3).map((p)=>Padding(padding:const EdgeInsets.fromLTRB(24,0,24,12),child:PropertyRow(property:p,saved:favorites.contains(p.id),onOpen:()=>onOpen(p),onFavorite:()=>onFavorite(p)))),
      ],
      Padding(padding:const EdgeInsets.fromLTRB(24,10,24,0),child:Text('设计预览 · 房源、价格及位置均为演示数据\n图片摘自你提供的旧版视频，仅用于内部 UI 参考。',style:TextStyle(fontSize:10,height:1.8,color:context.colors.onSurfaceVariant))),
    ]))),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.onMap});
  final VoidCallback onMap;
  @override
  Widget build(BuildContext context) => ClipRRect(borderRadius:BorderRadius.circular(26),child:SizedBox(height:218,child:Stack(fit:StackFit.expand,children:[
    Image.asset('assets/images/courtyard.jpg',fit:BoxFit.cover),
    const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(colors:[Color(0xF0083D2C),Color(0xB00B4831),Color(0x22000000)],stops:[0,.48,1]))),
    Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text('A PLACE TO CALL HOME',style:TextStyle(fontSize:9,letterSpacing:2,color:Color(0xFFB3EBD1),fontWeight:FontWeight.w600)),
      const SizedBox(height:12),
      const Text('有些地方，\n一眼就是家。',style:TextStyle(fontSize:25,height:1.35,fontWeight:FontWeight.w700,color:Colors.white)),
      const Spacer(),
      InkWell(onTap:onMap,borderRadius:BorderRadius.circular(30),child:Container(padding:const EdgeInsets.symmetric(horizontal:15,vertical:10),decoration:BoxDecoration(color:mint,borderRadius:BorderRadius.circular(30)),child:const Row(mainAxisSize:MainAxisSize.min,children:[Text('探索附近好房',style:TextStyle(color:Color(0xFF063B29),fontWeight:FontWeight.w700,fontSize:12)),SizedBox(width:9),Icon(Icons.arrow_forward_rounded,size:16,color:Color(0xFF063B29))]))),
    ])),
  ])));
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label,required this.selected,required this.onTap});
  final String label;final bool selected;final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>ChoiceChip(label:Text(label),selected:selected,onSelected:(_)=>onTap(),showCheckmark:false,labelStyle:TextStyle(fontSize:12,fontWeight:selected?FontWeight.w700:FontWeight.w400,color:selected?context.colors.primary:context.colors.onSurfaceVariant),selectedColor:context.colors.primary.withValues(alpha:.12),backgroundColor:Colors.transparent,side:BorderSide(color:selected?Colors.transparent:context.colors.outlineVariant));
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon,required this.label,required this.onTap});
  final IconData icon;final String label;final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(18),child:Padding(padding:const EdgeInsets.all(5),child:Column(children:[Container(width:53,height:53,decoration:BoxDecoration(color:context.colors.primary.withValues(alpha:.08),borderRadius:BorderRadius.circular(19)),child:Icon(icon,color:context.colors.primary,size:25)),const SizedBox(height:9),Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w500))])));
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key,required this.title,required this.subtitle,this.action,this.onAction});
  final String title,subtitle;final String? action;final VoidCallback? onAction;
  @override
  Widget build(BuildContext context)=>Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w700)),const SizedBox(height:4),Text(subtitle,style:TextStyle(fontSize:11,color:context.colors.onSurfaceVariant))])),if(action!=null)TextButton(onPressed:onAction,child:Row(children:[Text(action!,style:const TextStyle(fontSize:11)),const SizedBox(width:3),const Icon(Icons.arrow_forward_rounded,size:15)]))]);
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({super.key});
  @override
  Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),decoration:BoxDecoration(border:Border.all(color:context.colors.outlineVariant),borderRadius:BorderRadius.circular(20)),child:Text('UI 预览',style:TextStyle(fontSize:9,color:context.colors.onSurfaceVariant)));
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key,required this.saved,required this.onTap});
  final bool saved;final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>IconButton(tooltip:saved?'取消收藏':'收藏房源',onPressed:onTap,style:IconButton.styleFrom(backgroundColor:context.colors.surface.withValues(alpha:.95)),icon:Icon(saved?Icons.favorite_rounded:Icons.favorite_border_rounded,color:saved?forest:context.colors.onSurface,size:20));
}

class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key,required this.property,required this.saved,required this.onOpen,required this.onFavorite});
  final Property property;final bool saved;final VoidCallback onOpen,onFavorite;
  @override
  Widget build(BuildContext context)=>Material(color:context.colors.surface,borderRadius:BorderRadius.circular(24),clipBehavior:Clip.antiAlias,child:InkWell(onTap:onOpen,child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    SizedBox(height:170,child:Stack(fit:StackFit.expand,children:[Image.asset(property.image,fit:BoxFit.cover),Positioned(left:12,top:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:context.colors.surface.withValues(alpha:.94),borderRadius:BorderRadius.circular(20)),child:Text(property.tag,style:TextStyle(fontSize:10,color:context.colors.primary,fontWeight:FontWeight.w600)))),Positioned(right:7,top:6,child:FavoriteButton(saved:saved,onTap:onFavorite)),Positioned(bottom:10,left:12,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:3),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(5)),child:const Text('演示房源',style:TextStyle(color:Colors.white,fontSize:9))))])),
    Padding(padding:const EdgeInsets.fromLTRB(16,12,16,0),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(property.formattedPrice,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w800,letterSpacing:-.6)),const SizedBox(height:4),Text(property.address,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:13,fontWeight:FontWeight.w600)),const SizedBox(height:3),Text(property.area,style:TextStyle(fontSize:10,color:context.colors.onSurfaceVariant)),const SizedBox(height:11),PropertyFacts(property:property)])),
  ])));
}

class PropertyFacts extends StatelessWidget {
  const PropertyFacts({super.key,required this.property});
  final Property property;
  @override
  Widget build(BuildContext context)=>Wrap(spacing:12,runSpacing:8,children:[
    _Fact(icon:Icons.bed_outlined,text:'${property.beds} 卧'),_Fact(icon:Icons.bathtub_outlined,text:'${property.baths} 卫'),_Fact(icon:Icons.square_foot_rounded,text:'${property.sqft} ft²'),
  ]);
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon,required this.text});final IconData icon;final String text;
  @override
  Widget build(BuildContext context)=>Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:15,color:context.colors.onSurfaceVariant),const SizedBox(width:4),Text(text,style:TextStyle(fontSize:10,color:context.colors.onSurfaceVariant))]);
}

class PropertyRow extends StatelessWidget {
  const PropertyRow({super.key,required this.property,required this.saved,required this.onOpen,required this.onFavorite});
  final Property property;final bool saved;final VoidCallback onOpen,onFavorite;
  @override
  Widget build(BuildContext context)=>Material(color:context.colors.surface,borderRadius:BorderRadius.circular(20),clipBehavior:Clip.antiAlias,child:InkWell(onTap:onOpen,child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[ClipRRect(borderRadius:BorderRadius.circular(13),child:Image.asset(property.image,width:88,height:88,fit:BoxFit.cover)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(property.formattedPrice,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w700)),const SizedBox(height:5),Text(property.address,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11)),const SizedBox(height:5),Text('${property.beds} 卧 · ${property.baths} 卫 · ${property.type}',style:TextStyle(fontSize:10,color:context.colors.onSurfaceVariant))])),FavoriteButton(saved:saved,onTap:onFavorite)]))));
}

class _AIInvitation extends StatelessWidget {
  const _AIInvitation({required this.onTap});final VoidCallback onTap;
  @override
  Widget build(BuildContext context)=>Material(color:context.colors.primary.withValues(alpha:.07),borderRadius:BorderRadius.circular(22),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(22),child:Padding(padding:const EdgeInsets.all(20),child:Row(children:[Icon(Icons.auto_awesome_outlined,color:context.colors.primary,size:29),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('理想的家，从一句话开始',style:TextStyle(fontWeight:FontWeight.w700,fontSize:14)),const SizedBox(height:5),Text('AI 找房 · 即将接入',style:TextStyle(fontSize:11,color:context.colors.onSurfaceVariant))])),Icon(Icons.arrow_outward_rounded,size:19,color:context.colors.primary)]))));
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key,required this.icon,required this.title,required this.description});
  final IconData icon;final String title,description;
  @override
  Widget build(BuildContext context)=>Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:context.colors.primary.withValues(alpha:.08),shape:BoxShape.circle),child:Icon(icon,size:36,color:context.colors.primary)),const SizedBox(height:22),Text(title,textAlign:TextAlign.center,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:10),Text(description,textAlign:TextAlign.center,style:TextStyle(fontSize:12,height:1.8,color:context.colors.onSurfaceVariant))]));
}

class SavedPage extends StatelessWidget {
  const SavedPage({super.key,required this.properties,required this.onOpen,required this.onFavorite,required this.onExplore});
  final List<Property> properties;final ValueChanged<Property> onOpen,onFavorite;final VoidCallback onExplore;
  @override
  Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,20,24,130),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:820),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[SectionTitle(title:'收藏的家',subtitle:'${properties.length} 套心动房源 · 仅本次会话保存'),const SizedBox(height:28),if(properties.isEmpty)...[const SizedBox(height:30),const EmptyState(icon:Icons.favorite_border_rounded,title:'把心动的家留在这里',description:'点击房源上的爱心，即可加入收藏。\n账号和云端同步将在后续接入。'),const SizedBox(height:24),Center(child:FilledButton(onPressed:onExplore,child:const Text('去发现好房')))]else ...properties.map((p)=>Padding(padding:const EdgeInsets.only(bottom:12),child:PropertyRow(property:p,saved:true,onOpen:()=>onOpen(p),onFavorite:()=>onFavorite(p))))]))));
}

class ComingPage extends StatelessWidget {
  const ComingPage({super.key,required this.icon,required this.title,required this.description,this.suggestions=const []});
  final IconData icon;final String title,description;final List<String> suggestions;
  @override
  Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(28,65,28,130),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:560),child:Column(children:[EmptyState(icon:icon,title:title,description:description),const SizedBox(height:35),...suggestions.map((s)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:context.colors.surface,borderRadius:BorderRadius.circular(17),border:Border.all(color:context.colors.outlineVariant)),child:Row(children:[Expanded(child:Text(s,style:TextStyle(fontSize:12,color:context.colors.onSurfaceVariant))),const SizedBox(width:10),const Icon(Icons.north_west_rounded,size:16)]))),const SizedBox(height:22),TextField(enabled:false,decoration:InputDecoration(hintText:'AI 服务尚未连接',prefixIcon:const Icon(Icons.add_rounded),suffixIcon:const Icon(Icons.arrow_upward_rounded)))]))));
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key,required this.onTheme});final VoidCallback onTheme;
  @override
  Widget build(BuildContext context)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(24,35,24,130),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:600),child:Column(children:[const EmptyState(icon:Icons.person_outline_rounded,title:'欢迎来到悠居',description:'当前为访客预览。\n账号、通知和云端同步将在后续开放。'),const SizedBox(height:35),Card(elevation:0,color:context.colors.surface,child:Column(children:[ListTile(leading:Icon(context.isDark?Icons.dark_mode_outlined:Icons.light_mode_outlined),title:const Text('外观模式',style:TextStyle(fontSize:14)),subtitle:Text(context.isDark?'当前：深色':'当前：浅色',style:const TextStyle(fontSize:12)),trailing:const Icon(Icons.chevron_right_rounded),onTap:onTheme),const Divider(height:1),const ListTile(leading:Icon(Icons.language_rounded),title:Text('语言',style:TextStyle(fontSize:14)),subtitle:Text('当前：简体中文 · 多语言后续接入',style:TextStyle(fontSize:12)))])),const SizedBox(height:25),Text('YOUJU · UI PREVIEW 0.1',style:TextStyle(fontSize:10,letterSpacing:2,color:context.colors.onSurfaceVariant))]))));
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key,required this.initial});final SearchFilter initial;
  @override
  State<FilterSheet> createState()=>_FilterSheetState();
}
class _FilterSheetState extends State<FilterSheet> {
  ListingKind? _kind;String? _type;int _beds=0;double? _max;
  @override
  void initState(){super.initState();_kind=widget.initial.kind;_type=widget.initial.type;_beds=widget.initial.minBeds;_max=widget.initial.maxPrice;}
  @override
  Widget build(BuildContext context)=>SafeArea(child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(24,0,24,24+MediaQuery.viewInsetsOf(context).bottom),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
    Row(children:[const Text('找到更适合的家',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700)),const Spacer(),IconButton(tooltip:'关闭筛选',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded))]),
    const SizedBox(height:18),const Text('交易类型'),const SizedBox(height:8),Wrap(spacing:8,children:[_KindChip(label:'全部',selected:_kind==null,onTap:()=>setState((){_kind=null;_max=null;})),_KindChip(label:'出售',selected:_kind==ListingKind.sale,onTap:()=>setState((){_kind=ListingKind.sale;_max=null;})),_KindChip(label:'出租',selected:_kind==ListingKind.rent,onTap:()=>setState((){_kind=ListingKind.rent;_max=null;}))]),
    const SizedBox(height:20),const Text('物业类型'),const SizedBox(height:8),Wrap(spacing:8,children:[_KindChip(label:'不限',selected:_type==null,onTap:()=>setState(()=>_type=null)),...['公寓','联排别墅','独立屋'].map((t)=>_KindChip(label:t,selected:_type==t,onTap:()=>setState(()=>_type=t)))]),
    const SizedBox(height:20),const Text('卧室数量'),const SizedBox(height:8),Wrap(spacing:8,children:List.generate(5,(i)=>_KindChip(label:i==0?'不限':'$i+',selected:_beds==i,onTap:()=>setState(()=>_beds=i)))),
    const SizedBox(height:20),Text(_kind==ListingKind.rent?'最高月租（CAD）':'最高价格（CAD；全部类型时含租金）'),const SizedBox(height:8),Wrap(spacing:8,children:[_KindChip(label:'不限',selected:_max==null,onTap:()=>setState(()=>_max=null)),...(_kind==ListingKind.rent?<double>[2500,3000,4000]:<double>[700000,900000,1500000]).map((v)=>_KindChip(label:_kind==ListingKind.rent?'\$${v.toInt()}':'${(v/10000).round()} 万',selected:_max==v,onTap:()=>setState(()=>_max=v)))]),
    const SizedBox(height:28),Row(children:[OutlinedButton(onPressed:()=>setState((){_kind=null;_type=null;_beds=0;_max=null;}),child:const Text('重置')),const SizedBox(width:12),Expanded(child:FilledButton(key:const Key('apply-filters'),onPressed:()=>Navigator.pop(context,SearchFilter(query:widget.initial.query,kind:_kind,type:_type,minBeds:_beds,maxPrice:_max)),style:FilledButton.styleFrom(padding:const EdgeInsets.all(16)),child:const Text('查看房源')))]),
  ])));
}

class PropertyPage extends StatefulWidget {
  const PropertyPage({super.key,required this.property,required this.isFavorite,required this.onFavorite});
  final Property property;final bool isFavorite;final VoidCallback onFavorite;
  @override
  State<PropertyPage> createState()=>_PropertyPageState();
}
class _PropertyPageState extends State<PropertyPage> {
  late bool _saved;int _photo=0;
  final _photos=['assets/images/courtyard.jpg','assets/images/townhouse.jpg','assets/images/living.jpg','assets/images/interior.jpg'];
  @override
  void initState(){super.initState();_saved=widget.isFavorite;_photos.remove(widget.property.image);_photos.insert(0,widget.property.image);}
  void _favorite(){widget.onFavorite();setState(()=>_saved=!_saved);}
  @override
  Widget build(BuildContext context){final p=widget.property;return Scaffold(
    body:CustomScrollView(slivers:[
      SliverAppBar(expandedHeight:345,pinned:true,backgroundColor:Theme.of(context).scaffoldBackgroundColor,
        leading:Padding(padding:const EdgeInsets.all(7),child:IconButton.filledTonal(tooltip:'返回',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.arrow_back_rounded,size:19))),
        actions:[IconButton.filledTonal(tooltip:'复制地址',onPressed:() async {await Clipboard.setData(ClipboardData(text:p.address));if(context.mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('地址已复制')));},icon:const Icon(Icons.copy_outlined,size:19)),const SizedBox(width:6),FavoriteButton(saved:_saved,onTap:_favorite),const SizedBox(width:12)],
        flexibleSpace:FlexibleSpaceBar(background:Stack(fit:StackFit.expand,children:[PageView.builder(itemCount:_photos.length,onPageChanged:(i)=>setState(()=>_photo=i),itemBuilder:(_,i)=>GestureDetector(onTap:()=>showDialog<void>(context:context,builder:(_)=>_PhotoViewer(photos:_photos,initial:i)),child:Image.asset(_photos[i],fit:BoxFit.cover))),Positioned(bottom:18,right:20,child:Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:7),decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(25)),child:Text('${_photo+1} / ${_photos.length}  · 点击看大图',style:const TextStyle(color:Colors.white,fontSize:11))))])),
      ),
      SliverToBoxAdapter(child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:820),child:Padding(padding:const EdgeInsets.all(24),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:context.colors.primary.withValues(alpha:.1),borderRadius:BorderRadius.circular(20)),child:Text('${p.kind==ListingKind.sale?'出售':'出租'} · ${p.type}',style:TextStyle(fontSize:11,color:context.colors.primary,fontWeight:FontWeight.w600))),const Spacer(),const DemoBadge()]),
        const SizedBox(height:16),Text(p.formattedPrice,style:const TextStyle(fontSize:34,fontWeight:FontWeight.w800,letterSpacing:-1)),const SizedBox(height:7),Text(p.address,style:const TextStyle(fontSize:21,fontWeight:FontWeight.w600)),const SizedBox(height:7),Text(p.area,style:TextStyle(fontSize:13,color:context.colors.onSurfaceVariant)),
        const SizedBox(height:24),Container(padding:const EdgeInsets.all(20),width:double.infinity,decoration:BoxDecoration(color:context.colors.surface,borderRadius:BorderRadius.circular(20)),child:PropertyFacts(property:p)),
        const SizedBox(height:28),const Text('家的样子',style:TextStyle(fontSize:20,fontWeight:FontWeight.w700)),const SizedBox(height:12),Text('明亮的生活空间，舒适的居住尺度。这里展示的是新悠居的房源浏览体验，支持图片浏览与收藏。',style:TextStyle(fontSize:13,height:1.9,color:context.colors.onSurfaceVariant)),
        const SizedBox(height:22),Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:context.colors.primary.withValues(alpha:.06),borderRadius:BorderRadius.circular(16)),child:Text('演示说明：价格、地址、位置及物业属性为界面样例，不构成真实挂牌信息。照片来自你提供的参考视频，并不代表当前样例物业。AMPRE、学校、新闻及经纪联系尚未接入。',style:TextStyle(fontSize:11,height:1.8,color:context.colors.onSurfaceVariant))),
        const SizedBox(height:25),..._photos.skip(1).map((image)=>Padding(padding:const EdgeInsets.only(bottom:14),child:ClipRRect(borderRadius:BorderRadius.circular(20),child:Image.asset(image,width:double.infinity,fit:BoxFit.cover)))),
      ]))))),
    ]),
    bottomNavigationBar:SafeArea(top:false,child:Padding(padding:const EdgeInsets.fromLTRB(24,12,24,14),child:FilledButton.icon(onPressed:_favorite,style:FilledButton.styleFrom(padding:const EdgeInsets.all(17)),icon:Icon(_saved?Icons.favorite_rounded:Icons.favorite_border_rounded),label:Text(_saved?'已收藏 · 点击取消':'收藏这套房源')))),
  );}
}

class _PhotoViewer extends StatefulWidget {
  const _PhotoViewer({required this.photos,required this.initial});final List<String> photos;final int initial;
  @override
  State<_PhotoViewer> createState()=>_PhotoViewerState();
}
class _PhotoViewerState extends State<_PhotoViewer> {
  late final PageController _controller;
  @override
  void initState(){super.initState();_controller=PageController(initialPage:widget.initial);}
  @override
  void dispose(){_controller.dispose();super.dispose();}
  @override
  Widget build(BuildContext context)=>Dialog.fullscreen(backgroundColor:Colors.black,child:Stack(children:[PageView.builder(controller:_controller,itemCount:widget.photos.length,itemBuilder:(_,i)=>InteractiveViewer(child:Center(child:Image.asset(widget.photos[i],fit:BoxFit.contain)))),SafeArea(child:Align(alignment:Alignment.topRight,child:IconButton(tooltip:'关闭图片',onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close_rounded,color:Colors.white))))]));
}
