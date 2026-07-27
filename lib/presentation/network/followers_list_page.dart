import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FollowersListPage extends StatefulWidget {
  final String userId;
  const FollowersListPage({super.key, required this.userId});
  @override State<FollowersListPage> createState() => _FollowersListPageState();
}

class _FollowersListPageState extends State<FollowersListPage> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  Set<String> _myFollowing = {};
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final _search = TextEditingController();
  int _page = 0;
  final int _limit = 30;
  bool _hasMore = true;
  final _scrollCtrl = ScrollController();

  @override void initState() {
    super.initState();
    _load(initial: true);
    _search.addListener(_filter);
    _scrollCtrl.addListener(_onScroll);
  }

  @override void dispose() {
    _search.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _filter() {
    final q = _search.text.toLowerCase().trim();
    if (!mounted) return;
    setState(() {
      _filtered = q.isEmpty ? _all : _all.where((e) {
        final p = e['profiles'] as Map<String, dynamic>?;
        final name = (p?['display_name'] ?? '').toString().toLowerCase();
        return name.contains(q);
      }).toList();
    });
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 300 && !_loadingMore && _hasMore) {
      _load();
    }
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) {
      setState(() { _loading = true; _error = null; _page = 0; _hasMore = true; });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() { _loadingMore = true; });
    }

    try {
      final supa = Supabase.instance.client;
      final from = _page * _limit;

      final res = await supa.from('follows')
          .select('follower_id, created_at, profiles!follows_follower_id_fkey(id, display_name, photo_url, avatar_url, profession)')
          .eq('following_id', widget.userId)
          .order('created_at', ascending: false)
          .range(from, from + _limit - 1);

      final me = supa.auth.currentUser?.id;
      if (initial && me != null) {
        try {
          final myF = await supa.from('follows').select('following_id').eq('follower_id', me).limit(1000);
          _myFollowing = (myF as List).map((e) => e['following_id'] as String).toSet();
        } catch (_) {}
      }

      final list = (res as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        if (initial) { _all = list; } else { _all.addAll(list); }
        _filtered = _search.text.isEmpty ? _all : _filtered;
        _filter();
        _hasMore = list.length == _limit;
        _page++;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _toggleFollow(String otherId) async {
    final me = Supabase.instance.client.auth.currentUser?.id;
    if (me == null || otherId == me) return;
    final isFollowing = _myFollowing.contains(otherId);
    setState(() { isFollowing ? _myFollowing.remove(otherId) : _myFollowing.add(otherId); });
    try {
      if (isFollowing) {
        await Supabase.instance.client.from('follows').delete().eq('follower_id', me).eq('following_id', otherId);
      } else {
        await Supabase.instance.client.from('follows').insert({'follower_id': me, 'following_id': otherId});
      }
    } catch (_) {
      if (mounted) setState(() { isFollowing ? _myFollowing.add(otherId) : _myFollowing.remove(otherId); });
    }
  }

  Future<void> _removeFollower(String fid) async {
    if (Supabase.instance.client.auth.currentUser?.id != widget.userId) return;
    final confirm = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Retirer ce follower ?'), content: const Text('Il ne sera plus abonné à vous.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')), ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Retirer'))]));
    if (confirm != true) return;
    setState(() { _all.removeWhere((e) => e['follower_id'] == fid); _filtered.removeWhere((e) => e['follower_id'] == fid); });
    try { await Supabase.instance.client.from('follows').delete().eq('follower_id', fid).eq('following_id', widget.userId); } catch (_) { _load(initial: true); }
  }

  @override Widget build(BuildContext context) {
    final isOwner = Supabase.instance.client.auth.currentUser?.id == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: Text('Abonnés (${_all.length})', style: const TextStyle(color: Color(0xFF0B1B3D), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF0B1B3D)),
      ),
      body: Column(children: [
        Container(color: Colors.white, padding: const EdgeInsets.all(12), child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Rechercher', prefixIcon: const Icon(Icons.search), filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none)))),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator()) : _error != null ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.error_outline, size: 48, color: Colors.grey), const SizedBox(height: 8), Text(_error!), const SizedBox(height: 12), ElevatedButton(onPressed: () => _load(initial: true), child: const Text('Réessayer'))])) : _filtered.isEmpty ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people, size: 80, color: Colors.grey), SizedBox(height: 12), Text('Aucun abonné')])) : RefreshIndicator(onRefresh: () => _load(initial: true), child: ListView.builder(controller: _scrollCtrl, padding: const EdgeInsets.all(12), itemCount: _filtered.length + (_hasMore ? 1 : 0), itemBuilder: (_, i) {
          if (i == _filtered.length) return const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()));
          final item = _filtered[i];
          final p = item['profiles'] as Map<String, dynamic>?;
          final fid = item['follower_id'] as String;
          final name = p?['display_name'] ?? 'Utilisateur';
          final avatar = p?['photo_url'] ?? p?['avatar_url'];
          final followsBack = _myFollowing.contains(fid);

          return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: ListTile(
            leading: CircleAvatar(radius: 22, backgroundColor: Colors.grey.shade200, child: ClipOval(child: avatar != null ? Image.network(avatar, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person)) : const Icon(Icons.person))),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: p?['profession'] != null ? Text(p!['profession'], style: const TextStyle(fontSize: 11), maxLines: 1) : null,
            trailing: isOwner ? Row(mainAxisSize: MainAxisSize.min, children: [ElevatedButton(onPressed: () => _toggleFollow(fid), style: ElevatedButton.styleFrom(backgroundColor: followsBack ? Colors.grey.shade200 : const Color(0xFF2B5CFF), foregroundColor: followsBack ? Colors.black : Colors.white, minimumSize: const Size(70, 32), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), padding: const EdgeInsets.symmetric(horizontal: 12)), child: Text(followsBack ? 'Suivi' : 'Suivre', style: const TextStyle(fontSize: 11))), IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => _removeFollower(fid))]) : ElevatedButton(onPressed: () => _toggleFollow(fid), style: ElevatedButton.styleFrom(backgroundColor: followsBack ? Colors.grey.shade200 : const Color(0xFF2B5CFF)), child: Text(followsBack ? 'Suivi' : 'Suivre')),
            onTap: () => context.push('/network/member/$fid'),
          ));
        }))),
      ]),
    );
  }
}
