
// lib/presentation/thix_reservation/delivery/pages/client/delivery_home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:thix_id/nav.dart';
import '../../providers/delivery_client_provider.dart';
import '../../data/delivery_models.dart';

class DeliveryHomePage extends StatefulWidget {
  const DeliveryHomePage({super.key});
  @override State<DeliveryHomePage> createState() => _DeliveryHomePageState();
}

class _DeliveryHomePageState extends State<DeliveryHomePage> {
  String _selectedCat = "Livraison colis";
  final ScrollController _scrollCtrl = ScrollController();
  final GlobalKey _formKey = GlobalKey();

  @override void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeliveryClientProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      appBar: _buildAppBar(),
      body: Consumer<DeliveryClientProvider>(builder: (context, prov, _) {
        if (prov.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF5B2BD6)));
        return RefreshIndicator(
          onRefresh: () => prov.loadRoutes(),
          child: SingleChildScrollView(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(12,10,12,0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHero(prov),
              const SizedBox(height:12),
              _buildCategories(),
              const SizedBox(height:12),
              _buildFormCard(prov),
              const SizedBox(height:12),
              _buildOffres(prov),
              const SizedBox(height:90),
            ]),
          ),
        );
      }),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: Colors.white, elevation:0,
    title: Row(children: [
      Container(width:28,height:28,decoration:BoxDecoration(color:const Color(0xFF5B2BD6),borderRadius:BorderRadius.circular(6)),child:const Icon(Icons.inventory_2_rounded,color:Colors.white,size:14)),
      const SizedBox(width:6),
      const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text("THIX RESERVATION",style:TextStyle(fontSize:11,fontWeight:FontWeight.w800,color:Color(0xFF5B2BD6))),
        Text("Routes créées par Admin",style:TextStyle(fontSize:7.5,color:Color(0xFF8B8BA3))),
      ])
    ]),
    actions: [
      InkWell(onTap:()=>context.push(AppRoutes.deliveryAdminDashboard),child:Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),decoration:BoxDecoration(color:const Color(0xFF5B2BD6),borderRadius:BorderRadius.circular(20)),child:const Text("ADMIN",style:TextStyle(color:Colors.white,fontSize:8,fontWeight:FontWeight.w800)))),
      const SizedBox(width:8),
    ],
  );

  Widget _buildHero(DeliveryClientProvider prov) => Container(
    height:120,decoration:BoxDecoration(borderRadius:BorderRadius.circular(16),gradient:const LinearGradient(colors:[Color(0xFF5B2BD6),Color(0xFF7C4DFF)])),
    child: Padding(padding:const EdgeInsets.all(12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text("${prov.popularRoutes.length} trajets disponibles",style:const TextStyle(color:Color(0xFFD9CCFF),fontSize:9)),
      const SizedBox(height:6),
      const Text("Choisis parmi les trajets créés par l'admin",style:TextStyle(color:Colors.white,fontSize:13,fontWeight:FontWeight.w800)),
    ])),
  );

  Widget _buildCategories() => Container(padding:const EdgeInsets.all(8),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12)),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:["Hôtels","Vols","Bus","Livraison","Évènements"].map((l)=>Column(children:[Container(width:32,height:32,decoration:BoxDecoration(color:const Color(0xFFF0EBFF),borderRadius:BorderRadius.circular(8)),child:Icon(l=="Livraison"?Icons.inventory_2_rounded:Icons.event,size:14,color:const Color(0xFF5B2BD6))),Text(l,style:TextStyle(fontSize:7,fontWeight:l==_selectedCat?FontWeight.w700:FontWeight.w400))])).toList()));

  Widget _buildFormCard(DeliveryClientProvider prov) => Container(
    key:_formKey,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        const Text("Envoyer un colis",style:TextStyle(fontSize:11,fontWeight:FontWeight.w800)),
        Text("${prov.popularRoutes.length} routes",style:const TextStyle(fontSize:8,color:Color(0xFF5B2BD6),fontWeight:FontWeight.w700)),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:_field("De",prov.fromCity.isEmpty?"Choisir":prov.fromCity,()=>_pickFrom(prov))),
        const SizedBox(width:6),
        InkWell(onTap:()=>prov.swapCities(),child:Container(width:26,height:26,decoration:BoxDecoration(border:Border.all(color:const Color(0xFFE8E8F0)),shape:BoxShape.circle),child:const Icon(Icons.swap_horiz_rounded,size:12,color:Color(0xFF5B2BD6)))),
        const SizedBox(width:6),
        Expanded(child:_field("Vers",prov.toCity.isEmpty?"Choisir":prov.toCity,()=>_pickTo(prov))),
      ]),
      const SizedBox(height:8),
      Row(children:[
        Expanded(child:_field("Poids",prov.weightKg==0?"Choisir":"${prov.weightKg} kg",()=>_pickWeight(prov))),
        const SizedBox(width:6),
        Expanded(child:_field("Mode",prov.deliveryMode.label,()=>_pickMode(prov))),
      ]),
      const SizedBox(height:10),
      SizedBox(width:double.infinity,height:36,child:ElevatedButton(
        style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF5B2BD6),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(8))),
        onPressed:(){
          if(prov.fromCity.isEmpty||prov.toCity.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Choisis les villes admin")));return;}
          if(prov.calculatedPrice==0){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text("Trajet ${prov.fromCity} → ${prov.toCity} non tarifé")));return;}
          context.push(AppRoutes.deliveryCheckout);
        },
        child:Text(prov.calculatedPrice>0?"${prov.calculatedPrice} FCFA - Continuer":"Trajet non tarifé par admin",style:const TextStyle(color:Colors.white,fontSize:9.5,fontWeight:FontWeight.w700)),
      )),
      if(prov.popularRoutes.isNotEmpty)...[
        const SizedBox(height:8),
        Wrap(spacing:4,children:prov.popularRoutes.map((r)=>Chip(label:Text("${r.fromCity} → ${r.toCity}",style:const TextStyle(fontSize:7)),visualDensity:VisualDensity.compact,materialTapTargetSize:MaterialTapTargetSize.shrinkWrap)).toList()),
      ]
    ]),
  );

  Widget _field(String h,String v,VoidCallback tap)=>InkWell(onTap:tap,child:Container(padding:const EdgeInsets.all(7),decoration:BoxDecoration(border:Border.all(color:const Color(0xFFF0EBFF)),borderRadius:BorderRadius.circular(7)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(h,style:const TextStyle(fontSize:6.5,color:Color(0xFF8B8BA3))),Text(v,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:8.5,fontWeight:FontWeight.w700))])));

  Widget _buildOffres(DeliveryClientProvider prov){
    if(prov.offers.isEmpty) return const SizedBox();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      const Text("Offres",style:TextStyle(fontSize:10,fontWeight:FontWeight.w800)),
      const SizedBox(height:6),
      SizedBox(height:80,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:prov.offers.length,separatorBuilder:(_,__)=>const SizedBox(width:6),itemBuilder:(_,i){final o=prov.offers[i];return Container(width:110,padding:const EdgeInsets.all(7),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(9)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text("-${o.discountPercent}%",style:const TextStyle(fontSize:7,color:Color(0xFF00B26A),fontWeight:FontWeight.w700)),Text(o.title,style:const TextStyle(fontSize:8,fontWeight:FontWeight.w700)),const Spacer(),Text("${o.newPrice} F",style:const TextStyle(fontSize:9,fontWeight:FontWeight.w800))]));})),
    ]);
  }

  Widget _buildBottomNav()=>Container(height:58,decoration:const BoxDecoration(color:Colors.white),child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[IconButton(icon:const Icon(Icons.home_rounded,size:16),onPressed:()=>context.go(AppRoutes.home)),Container(width:38,height:38,decoration:const BoxDecoration(color:Color(0xFF5B2BD6),shape:BoxShape.circle),child:const Icon(Icons.add_rounded,color:Colors.white,size:20)),IconButton(icon:const Icon(Icons.person_outline_rounded,size:16),onPressed:()=>context.go('/user/dashboard'))]));

  void _pickFrom(DeliveryClientProvider prov){
    final list = prov.popularRoutes.map((e)=>e.fromCity).toSet().toList();
    if(list.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Aucune route - Admin doit créer")));return;}
    showModalBottomSheet(context:context,builder:(_)=>ListView(children:list.map((c)=>ListTile(title:Text(c),onTap:(){prov.setFromCity(c);Navigator.pop(context);})).toList()));
  }
  void _pickTo(DeliveryClientProvider prov){
    final list = prov.popularRoutes.map((e)=>e.toCity).toSet().toList();
    if(list.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text("Aucune route - Admin doit créer")));return;}
    showModalBottomSheet(context:context,builder:(_)=>ListView(children:list.map((c)=>ListTile(title:Text(c),onTap:(){prov.setToCity(c);Navigator.pop(context);})).toList()));
  }
  void _pickWeight(DeliveryClientProvider prov)=>showModalBottomSheet(context:context,builder:(_)=>Column(mainAxisSize:MainAxisSize.min,children:[1,3,5,10,20].map((w)=>ListTile(title:Text("$w kg"),onTap:(){prov.setWeight(w);Navigator.pop(context);})).toList()));
  void _pickMode(DeliveryClientProvider prov)=>showModalBottomSheet(context:context,builder:(_)=>Column(mainAxisSize:MainAxisSize.min,children:DeliveryMode.values.map((m)=>ListTile(title:Text(m.label),onTap:(){prov.setMode(m);Navigator.pop(context);})).toList()));
}
