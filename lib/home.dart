import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'artist.dart';
import 'item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCurrency = 'KRW';
  List<String> currencies = ['KRW', 'USD', 'JPY', 'CNY'];

  bool _isLoading = true;
  String _errorMessage = '';
  List<Map<String, dynamic>> promotions = [];
  List<Map<String, dynamic>> artists = [];
  List<Map<String, dynamic>> hotItems = [];
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;

  final Dio _dio = Dio();
  late PersistCookieJar _cookieJar;

  @override
  void initState() {
    super.initState();

    // Initialize PersistCookieJar with FileStorage
    final Directory appDocDir = Directory.systemTemp; // Use a temporary directory for simplicity
    _cookieJar = PersistCookieJar(storage: FileStorage('${appDocDir.path}/cookies'));
    _dio.interceptors.add(CookieManager(_cookieJar));

    _fetchPromotions();
    _fetchArtists();
    _fetchHotItems();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  Future<void> _fetchPromotions() async {
    print('_cookieJar runtimeType: ${_cookieJar.runtimeType}'); // Debug 用
    if (_cookieJar is! PersistCookieJar) {
      print("🚨 _cookieJar 不是 PersistCookieJar，可能初始化錯誤！");
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Step 1: Visit the main page to get cookies
      final mainPageResponse = await _dio.get(
        'https://shop.weverse.io/',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
            'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7',
            'Referer': 'https://shop.weverse.io/',
          },
        ),
      );

      //print('Main page response status: ${mainPageResponse.statusCode}');
      //print('Response headers: ${mainPageResponse.headers}');
      final cookies = await _cookieJar.loadForRequest(Uri.parse('https://shop.weverse.io/'));
      //print('Cookies: $cookies');

      // Step 2: Use the cookies to access the API
      final response = await _dio.get(
        'https://shop.weverse.io/api/wvs/display/api/v1/home/banners?displayPlatform=WEB',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
            'Accept': 'application/json, text/plain, */*',
            'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7',
            'Referer': 'https://shop.weverse.io/',
            'Origin': 'https://shop.weverse.io',
          },
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> banners = data['banners'];

        setState(() {
          promotions = banners.map((banner) {
            return {
              'artistName': banner['artistName'] ?? 'Unknown Artist',
              'title': banner['title'] ?? 'No Title',
              'subtitle': banner['subTitle'] ?? '',
              'imageUrl': banner['bannerImageUrl'] ?? '',
              'link': banner['landingUrl'] ?? '',
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load promotions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load promotions: $e';
        _isLoading = false;
      });
      print('Error fetching promotions: $e');
    }
  }

  Future<void> _fetchArtists() async {
    try {
      final String jsonString = await DefaultAssetBundle.of(context).loadString('assets/data/artists.json');
      final jsonMap = json.decode(jsonString);
      final artistsData = jsonMap['artists'] as List;

      setState(() {
        artists = artistsData.map((artist) {
          return {
            'artistId': artist['artistId'] ?? 0,
            'name': artist['name'] ?? 'Unknown',
            'logoImageUrl': artist['logoImageUrl'] ?? '',
          };
        }).toList();
      });
    } catch (e) {
      print('Error loading artist data: $e');
    }
  }

  Future<void> _fetchHotItems() async {
    try {
      // Step 1: Visit the main page to get cookies
      try {
        final mainPageResponse = await _dio.get(
          'https://shop.weverse.io/',
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
              'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7',
              'Referer': 'https://shop.weverse.io/',
            },
          ),
        );
        // ...existing code...
      } catch (e) {
        print('Error during main page request: $e');
        rethrow;
      }

      // Step 2: Load cookies
      try {
        final cookies = await _cookieJar.loadForRequest(Uri.parse('https://shop.weverse.io/'));
        print('Cookies: $cookies');
      } catch (e) {
        print('Error loading cookies: $e');
        rethrow;
      }

      // Step 3: Use the cookies to access the API
      try {
        final response = await _dio.get(
          'https://shop.weverse.io/api/wvs/display/api/v1/home/recommend-sales?artistIds=2%2C3%2C5%2C50%2C7%2C35%2C67%2C73%2C165%2C10&displayPlatform=WEB&size=1',
          options: Options(
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
              'Accept': 'application/json, text/plain, */*',
              'Accept-Language': 'zh-TW,zh;q=0.9,en-US;q=0.8,en;q=0.7',
              'Referer': 'https://shop.weverse.io/',
              'Origin': 'https://shop.weverse.io',
            },
          ),
        );
        print('Hot items response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = response.data;

          // Ensure the structure of the response is as expected
          if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
            final List<dynamic> artistsData = data['data'];
            List<Map<String, dynamic>> parsedHotItems = [];

            // Load artist data from JSON
            final String jsonString = await DefaultAssetBundle.of(context).loadString('assets/data/artists.json');
            final jsonMap = json.decode(jsonString);
            final List<dynamic> artistsDataFromJson = jsonMap['artists'];

            for (var artistData in artistsData) {
              if (artistData is Map<String, dynamic> && artistData['sales'] is List<dynamic>) {
                final List<dynamic> sales = artistData['sales'];
                final int artistId = artistData['artist']['artistId'] ?? 0;

                // Find the artist in the JSON data
                final artistFromJson = artistsDataFromJson.firstWhere(
                  (artist) => artist['artistId'] == artistId,
                  orElse: () => null,
                );
                
                final artistLogoUrl = artistFromJson?['logoImageUrl'] ?? '';
                
                for (var sale in sales) {
                  if (sale is Map<String, dynamic>) {
                    parsedHotItems.add({
                      'artistId': sale['labelArtistId'] ?? 0,
                      'artistName': sale['artistName'] ?? 'Unknown Artist',
                      'saleId': sale['saleId'] ?? 0,
                      'thumbnailImageUrl': sale['thumbnailImageUrl'] ?? '',
                      'productName': sale['name'] ?? 'No Name',
                      'price': sale['price']?['salePrice'] ?? 0.0,
                      'artistLogoUrl': artistLogoUrl, // Add artist logo URL
                    });
                  }
                }
              }
            }

            setState(() {
              hotItems = parsedHotItems;
            });
          } else {
            print('Error: Unexpected response structure');
            setState(() {
              hotItems = [];
            });
          }
        } else {
          throw Exception('Failed to load hot items. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error during hot items API request: $e');
        rethrow;
      }
    } catch (e) {
      print('Error fetching hot items: $e');
    }
  }

  void _showArtistDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: SizedBox(
            height: 600,
            child: ArtistGridPage(artists: artists),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Image.asset(
                'assets/images/logo.png',
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Text(
                    'Weverse Shop',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  );
                },
              ),
              const Spacer(),
              DropdownButton<String>(
                value: selectedCurrency,
                underline: Container(),
                icon: const Icon(Icons.arrow_drop_down),
                items: currencies.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedCurrency = newValue;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        backgroundColor: Colors.white,
      ),
      body: Container(
        color: Colors.white, // Set white background
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
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
                        ElevatedButton(
                          onPressed: _fetchPromotions,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchPromotions,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '推薦活動',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (promotions.isNotEmpty)
                                  Text(
                                    '${_currentPage + 1}/${promotions.length}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          SizedBox(
                            height: 350,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: promotions.length,
                              itemBuilder: (context, index) {
                                final promo = promotions[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: PromotionCardCarousel(
                                    artistName: promo['artistName'],
                                    title: promo['title'],
                                    subtitle: promo['subtitle'],
                                    imageUrl: promo['imageUrl'],
                                    link: promo['link'],
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                promotions.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 8,
                                  width: _currentPage == index ? 24 : 8,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index
                                        ? Colors.purple
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              '熱門商品',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: hotItems.length,
                              itemBuilder: (context, index) {
                                final item = hotItems[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ItemPage(

                                          artistId: item['artistId'],
                                          artistName: item['artistName'],
                                          productName: item['productName'],
                                          
                                          productId: item['saleId'] ?? 0,
                                          productPrice: item['price'] ?? 0.0,
                                          productImageUrl: item['thumbnailImageUrl'] ?? '',
                                          artistImageUrl: item['artistLogoUrl'] ?? '',
                                          currency: selectedCurrency,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 150,
                                    margin: const EdgeInsets.only(right: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                      image: DecorationImage(
                                        image: NetworkImage(item['thumbnailImageUrl']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(0.6),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item['artistName'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 8,
                                          left: 8,
                                          right: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.8),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item['productName'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              '藝人清單',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          SizedBox(
                            height: 150,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              itemCount: artists.length,
                              itemBuilder: (context, index) {
                                final artist = artists[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ArtistPage(
                                          artistId: artist['artistId'],
                                          artistName: artist['name'],
                                          currency: selectedCurrency,
                                          logoImageUrl: artist['logoImageUrl'], // Pass logoImageUrl
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 16),
                                    child: Column(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: artist['logoImageUrl'],
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          artist['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showArtistDialog,
                                icon: const Icon(Icons.search, color: Colors.black),
                                label: const Text(
                                  '查看藝人',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.black),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class PromotionCardCarousel extends StatelessWidget {
  final String artistName;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String link;

  const PromotionCardCarousel({
    super.key,
    required this.artistName,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final Uri url = Uri.parse(link);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open link: $link')),
          );
        }
      },
      child: Container(
        height: 350,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(
                  color: Colors.purple[200],
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image, size: 50),
              ),
            ),
            // Artist name at the top-left
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  artistName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            // Title and subtitle block with white background
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20.0),
                    bottomRight: Radius.circular(20.0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WebViewPage extends StatelessWidget {
  final String url;

  const WebViewPage({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView'),
        backgroundColor: Colors.purple[100],
      ),
      body: Center(
        child: Text('Navigate to: $url'), // Replace with WebView implementation
      ),
    );
  }
}

class ArtistGridPage extends StatefulWidget {
  final List<Map<String, dynamic>> artists;

  const ArtistGridPage({super.key, required this.artists});

  @override
  State<ArtistGridPage> createState() => _ArtistGridPageState();
}

class _ArtistGridPageState extends State<ArtistGridPage> {
  List<Map<String, dynamic>> _filteredArtists = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredArtists = widget.artists;
    _searchController.addListener(_filterArtists);
  }

  void _filterArtists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArtists = widget.artists.where((artist) {
        return artist['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text(
          '藝人清單',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '搜尋藝人',
                hintText: '輸入藝人名稱...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredArtists.isEmpty
                ? const Center(
                    child: Text(
                      '找不到符合的藝人',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 3 / 4,
                    ),
                    itemCount: _filteredArtists.length,
                    itemBuilder: (context, index) {
                      final artist = _filteredArtists[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ArtistPage(
                                artistId: artist['artistId'],
                                artistName: artist['name'],
                                currency: 'KRW',
                                logoImageUrl: artist['logoImageUrl'],
                              ),
                            ),
                          );
                        },
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: artist['logoImageUrl'],
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
