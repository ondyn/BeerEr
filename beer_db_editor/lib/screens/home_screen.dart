import 'package:beer_db_editor/screens/beer_edit_screen.dart';
import 'package:beer_db_editor/screens/brewery_edit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beer DB Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.sports_bar), text: 'Beers'),
            Tab(icon: Icon(Icons.factory), text: 'Breweries'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name (min 3 chars)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _BeerList(query: _query),
                _BreweryList(query: _query),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNew(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addNew(BuildContext context) {
    final tab = _tabController.index;
    if (tab == 0) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BeerEditScreen()),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BreweryEditScreen()),
      );
    }
  }
}

class _BeerList extends StatelessWidget {
  const _BeerList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text('Type at least 3 characters to search beers.'),
      );
    }

    final db = FirebaseFirestore.instance;
    final ref = db
        .collection('beers')
        .where('name_lower', isGreaterThanOrEqualTo: query)
        .where('name_lower', isLessThan: '$query\uf8ff')
        .limit(50)
        .orderBy('name_lower');

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No beers found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data()! as Map<String, dynamic>;
            final name = data['name'] as String? ?? '';
            final brewery = data['brewery_name'] as String? ?? '';
            final alcohol = data['alcohol_percent'];
            final subtitle = [
              if (brewery.isNotEmpty) brewery,
              if (alcohol != null) '${alcohol}%',
              if (data['beer_style'] != null) data['beer_style'] as String,
            ].join(' · ');

            return ListTile(
              title: Text(name),
              subtitle: Text(subtitle),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, doc.reference, name),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BeerEditScreen(docId: doc.id, data: data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, DocumentReference ref, String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete beer?'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$name"')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _BreweryList extends StatelessWidget {
  const _BreweryList({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.length < 3) {
      return const Center(
        child: Text('Type at least 3 characters to search breweries.'),
      );
    }

    final db = FirebaseFirestore.instance;
    final ref = db
        .collection('breweries')
        .where('name_lower', isGreaterThanOrEqualTo: query)
        .where('name_lower', isLessThan: '$query\uf8ff')
        .limit(50)
        .orderBy('name_lower');

    return StreamBuilder<QuerySnapshot>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No breweries found.'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data()! as Map<String, dynamic>;
            final name = data['name'] as String? ?? '';
            final region = data['region'] as String? ?? '';
            final source = data['source'] as String? ?? '';

            return ListTile(
              title: Text(name),
              subtitle: Text([
                if (region.isNotEmpty) region,
                if (source.isNotEmpty) 'Source: $source',
              ].join(' · ')),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => _confirmDelete(context, doc.reference, name),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BreweryEditScreen(docId: doc.id, data: data),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(
      BuildContext context, DocumentReference ref, String name) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete brewery?'),
        content: Text(
          'Are you sure you want to delete "$name"? '
          'Beers from this brewery will NOT be automatically deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "$name"')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
