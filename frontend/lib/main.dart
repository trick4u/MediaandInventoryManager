import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

void main() {
  runApp(MediaAndInventoryManagerApp());
}

class MediaAndInventoryManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media & Inventory Manager',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: HomeScreen(),
    );
  }
}

class Movie {
  final int id;
  final String title;
  final String? genre;
  final double? rating;
  final bool reviewed;
  final String? reviewText;

  Movie({
    required this.id,
    required this.title,
    this.genre,
    this.rating,
    required this.reviewed,
    this.reviewText,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      genre: json['genre'],
      rating: double.tryParse(json['rating'].toString()),
      reviewed: json['reviewed'] == 1 || json['reviewed'] == true,
      reviewText: json['review_text'],
    );
  }
}

class InventoryItem {
  final int id;
  final String itemName;
  final int quantity;
  final String? supplier;
  final int reorderLevel;

  InventoryItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    this.supplier,
    required this.reorderLevel,
  });

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      itemName: json['item_name'],
      quantity: json['quantity'],
      supplier: json['supplier'],
      reorderLevel: json['reorder_level'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Movie> movies = [];
  List<InventoryItem> inventory = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchMovies();
    fetchInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchMovies() async {
    final response = await http.get(Uri.parse('http://localhost:3000/movies'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        movies = data.map((json) => Movie.fromJson(json)).toList();
      });
    }
  }

  Future<void> fetchInventory() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/inventory?lowStock=true'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        inventory = data.map((json) => InventoryItem.fromJson(json)).toList();
      });
    }
  }

  Future<void> addMovie(
    String title,
    String? genre,
    double? rating,
    bool reviewed,
    String? reviewText,
  ) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/movies'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'genre': genre,
        'rating': rating,
        'reviewed': reviewed,
        'review_text': reviewText,
      }),
    );
    if (response.statusCode == 201) {
      fetchMovies();
    }
  }

  Future<void> updateMovie(
    int id,
    String title,
    String? genre,
    double? rating,
    bool reviewed,
    String? reviewText,
  ) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/movies/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'genre': genre,
        'rating': rating,
        'reviewed': reviewed,
        'review_text': reviewText,
      }),
    );
    if (response.statusCode == 200) {
      fetchMovies();
    }
  }

  Future<void> addInventoryItem(
    String itemName,
    int quantity,
    String? supplier,
    int reorderLevel,
  ) async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/inventory'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'item_name': itemName,
        'quantity': quantity,
        'supplier': supplier,
        'reorder_level': reorderLevel,
      }),
    );
    if (response.statusCode == 201) {
      fetchInventory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media & Inventory Manager'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'Movie Watchlist'), Tab(text: 'Inventory')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Movie Watchlist Tab
          ListView.builder(
            itemCount: movies.length,
            itemBuilder: (context, index) {
              final movie = movies[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(movie.title),
                  subtitle: Text(
                    '${movie.genre ?? 'N/A'} - Rating: ${movie.rating ?? 'N/A'} - Reviewed: ${movie.reviewed ? 'Yes' : 'No'}\nReview: ${movie.reviewText ?? 'N/A'}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showEditMovieDialog(context, movie),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Inventory Tab
          ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              final isLowStock = item.quantity <= item.reorderLevel;
              return Card(
                margin: EdgeInsets.all(8.0),
                color: isLowStock ? Colors.red[100] : null,
                child: ListTile(
                  title: Text(item.itemName),
                  subtitle: Text(
                    'Quantity: ${item.quantity} - Supplier: ${item.supplier ?? 'N/A'} - Reorder Level: ${item.reorderLevel}',
                  ),
                  trailing:
                      isLowStock
                          ? Icon(Icons.warning, color: Colors.red)
                          : null,
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) {
          return FloatingActionButton(
            onPressed: () {
              final tabIndex = _tabController.index;
              if (tabIndex == 0) {
                _showAddMovieDialog(context);
              } else {
                _showAddInventoryDialog(context);
              }
            },
            child: Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddMovieDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String? genre;
    double? rating;
    bool reviewed = false;
    String? reviewText;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Movie'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Title'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter a title'
                                : null,
                    onSaved: (value) => title = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Genre (optional)'),
                    onSaved: (value) => genre = value,
                  ),
                  RatingBar.builder(
                    initialRating: rating ?? 0,
                    minRating: 0,
                    maxRating: 10,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 10,
                    itemBuilder:
                        (context, _) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (value) => rating = value,
                  ),
                  SwitchListTile(
                    title: Text('Reviewed'),
                    value: reviewed,
                    onChanged: (value) => setState(() => reviewed = value),
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Review (optional)'),
                    onSaved: (value) => reviewText = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  addMovie(title, genre, rating, reviewed, reviewText);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMovieDialog(BuildContext context, Movie movie) {
    final _formKey = GlobalKey<FormState>();
    String title = movie.title;
    String? genre = movie.genre;
    double? rating = movie.rating;
    bool reviewed = movie.reviewed;
    String? reviewText = movie.reviewText;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Movie'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    decoration: InputDecoration(labelText: 'Title'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter a title'
                                : null,
                    onSaved: (value) => title = value!,
                  ),
                  TextFormField(
                    initialValue: genre,
                    decoration: InputDecoration(labelText: 'Genre (optional)'),
                    onSaved: (value) => genre = value,
                  ),
                  RatingBar.builder(
                    initialRating: rating ?? 0,
                    minRating: 0,
                    maxRating: 10,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 10,
                    itemBuilder:
                        (context, _) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (value) => rating = value,
                  ),
                  SwitchListTile(
                    title: Text('Reviewed'),
                    value: reviewed,
                    onChanged: (value) => setState(() => reviewed = value),
                  ),
                  TextFormField(
                    initialValue: reviewText,
                    decoration: InputDecoration(labelText: 'Review (optional)'),
                    onSaved: (value) => reviewText = value,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  updateMovie(
                    movie.id,
                    title,
                    genre,
                    rating,
                    reviewed,
                    reviewText,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showAddInventoryDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String itemName = '';
    int? quantity;
    String? supplier;
    int? reorderLevel;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Inventory Item'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Item Name'),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Enter an item name'
                                : null,
                    onSaved: (value) => itemName = value!,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter quantity';
                      final val = int.tryParse(value);
                      return val == null || val < 0
                          ? 'Enter a valid quantity'
                          : null;
                    },
                    onSaved: (value) => quantity = int.parse(value!),
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Supplier (optional)',
                    ),
                    onSaved: (value) => supplier = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Reorder Level'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return 'Enter reorder level';
                      final val = int.tryParse(value);
                      return val == null || val < 0
                          ? 'Enter a valid reorder level'
                          : null;
                    },
                    onSaved: (value) => reorderLevel = int.parse(value!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  addInventoryItem(
                    itemName,
                    quantity!,
                    supplier,
                    reorderLevel!,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
