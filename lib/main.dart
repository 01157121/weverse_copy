import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weverse Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/artists': (context) => const ArtistListPage(),
      },
    );
  }
}

class Artist {
  final int artistId;
  final String name;
  final String shortName;
  final String logoImageUrl;

  Artist({
    required this.artistId,
    required this.name,
    required this.shortName,
    required this.logoImageUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    var logoUrl = json['logoImageUrl'] ?? '';
    if (logoUrl.isNotEmpty && !logoUrl.startsWith('http')) {
      logoUrl = 'https:' + logoUrl;
    }

    return Artist(
      artistId: json['artistId'] ?? 0,
      name: json['name'] ?? 'Unknown',
      shortName: json['shortName'] ?? json['name'] ?? 'Unknown',
      logoImageUrl: logoUrl,
    );
  }
}

class ArtistListPage extends StatefulWidget {
  const ArtistListPage({super.key});

  @override
  State<ArtistListPage> createState() => _ArtistListPageState();
}

class _ArtistListPageState extends State<ArtistListPage> {
  List<Artist> _allArtists = [];
  List<Artist> _filteredArtists = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String _errorMessage = '';
  bool _dataFetched = false;

  @override
  void initState() {
    super.initState();
    _loadArtistsData();
    _searchController.addListener(() {
      _filterArtists();
    });
  }

  Future<void> _loadArtistsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final String jsonString = await rootBundle.loadString('assets/data/artists.json');
      final jsonMap = json.decode(jsonString);
      final artistsData = jsonMap['artists'] as List;

      final artists = artistsData.map<Artist>((item) => Artist.fromJson(item)).toList();

      for (var artist in artists.take(3)) {
        print('Artist: ${artist.name}, URL: ${artist.logoImageUrl}');
      }

      setState(() {
        _allArtists = artists;
        _filteredArtists = List.from(artists);
        _isLoading = false;
        _dataFetched = true;
      });

      print('Successfully loaded ${artists.length} artists from assets');
    } catch (e) {
      print('Error loading JSON data from assets: $e');
      setState(() {
        _errorMessage = 'Error loading artist data: $e';
        _isLoading = false;
      });
    }
  }

  void _filterArtists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArtists = _allArtists.where((artist) {
        return artist.name.toLowerCase().contains(query) ||
            artist.shortName.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weverse Shop Artists'),
        backgroundColor: Colors.purple[100],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Artists',
                hintText: 'Enter artist name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage.isNotEmpty && _allArtists.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    : _filteredArtists.isEmpty
                        ? const Center(child: Text('No artists found matching your search'))
                        : ListView.builder(
                            itemCount: _filteredArtists.length,
                            itemBuilder: (context, index) {
                              final artist = _filteredArtists[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                elevation: 2,
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: Image.network(
                                        artist.logoImageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          print('Error loading image: $error for URL: ${artist.logoImageUrl}');
                                          return Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.broken_image),
                                          );
                                        },
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    artist.shortName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(artist.name),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ArtistDetailPage(artist: artist),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class ArtistDetailPage extends StatefulWidget {
  final Artist artist;

  const ArtistDetailPage({
    super.key,
    required this.artist,
  });

  @override
  State<ArtistDetailPage> createState() => _ArtistDetailPageState();
}

class _ArtistDetailPageState extends State<ArtistDetailPage> {
  bool _isLoading = false;
  List<dynamic> _products = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadMockProducts();
  }

  void _loadMockProducts() {
    setState(() {
      _isLoading = true;
    });

    try {
      final mockProductsJson = '''
      [
        {
          "productId": 1,
          "title": "${widget.artist.name} - 2024 Season's Greetings",
          "price": "₩35,000",
          "imageUrl": "https://via.placeholder.com/150?text=${Uri.encodeComponent(widget.artist.shortName)}"
        },
        {
          "productId": 2,
          "title": "${widget.artist.name} - Latest Album",
          "price": "₩25,000",
          "imageUrl": "https://via.placeholder.com/150?text=Album"
        },
        {
          "productId": 3,
          "title": "${widget.artist.name} - Official Light Stick",
          "price": "₩45,000",
          "imageUrl": "https://via.placeholder.com/150?text=Merch"
        },
        {
          "productId": 4,
          "title": "${widget.artist.name} - Photo Book",
          "price": "₩52,000",
          "imageUrl": "https://via.placeholder.com/150?text=Photos"
        },
        {
          "productId": 5,
          "title": "${widget.artist.name} - Concert T-Shirt",
          "price": "₩32,000",
          "imageUrl": "https://via.placeholder.com/150?text=T-Shirt"
        }
      ]
      ''';

      final products = json.decode(mockProductsJson);

      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading products: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artist.name),
        backgroundColor: Colors.purple[100],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
            ),
            child: Center(
              child: Image.network(
                widget.artist.logoImageUrl,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading detail image: $error for URL: ${widget.artist.logoImageUrl}');
                  return const Icon(Icons.broken_image, size: 80);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      )
                    : _products.isEmpty
                        ? const Center(
                            child: Text('No products available for this artist.'),
                          )
                        : ListView.builder(
                            itemCount: _products.length,
                            itemBuilder: (context, index) {
                              final product = _products[index];
                              String title = product['title'] ?? 'Unknown Product';
                              String price = product['price']?.toString() ?? 'No price information';
                              String imageUrl = product['imageUrl'] ?? 'https://via.placeholder.com/150';

                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        print('Error loading product image: $error for URL: $imageUrl');
                                        return Container(
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey[300],
                                          child: const Icon(Icons.broken_image),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  title: Text(title),
                                  subtitle: Text(price),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Selected: $title')),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
