import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html_unescape/html_unescape.dart'; // Ensure this import is present
import 'item.dart'; // Import ItemPage

class ArtistPage extends StatefulWidget {
  final int artistId;
  final String artistName;
  final String currency;
  final String logoImageUrl; // Added logoImageUrl parameter

  const ArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.currency,
    required this.logoImageUrl, // Added logoImageUrl parameter
  });

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  final Dio _dio = Dio();
  List<Map<String, dynamic>> notices = [];
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  bool isLoadingNotices = true;
  bool isLoadingEvents = true;
  bool isLoadingCategories = true;
  bool isLoadingProducts = true;
  int selectedCategoryId = -1;

  @override
  void initState() {
    super.initState();
    _fetchNotices();
    _fetchEvents();
    _fetchCategories();
  }

  Future<void> _fetchNotices() async {
    final String noticesUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}/notices';

    try {
      final response = await _dio.get(noticesUrl);
      final html = response.data;

      final RegExp noticeRegex = RegExp(
          r'<li data-id="(\d+)" class=".*?"><a .*?><div .*?><ul .*?><li .*?">(.*?)</li></ul><p .*?">(.*?)</p><footer .*?></footer></div></a></li>',
          dotAll: true);
      final matches = noticeRegex.allMatches(html);

      setState(() {
        notices = matches.map((match) {
          final unescape = HtmlUnescape();
          final title = unescape.convert(
              match.group(3)?.replaceAll(RegExp(r'<br\s*/?>'), '\n').replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? '');
          return {
            'dataId': match.group(1),
            'title': title,
          };
        }).toList();
        isLoadingNotices = false;
      });
    } catch (e) {
      print('Error fetching notices: $e');
      setState(() {
        isLoadingNotices = false;
      });
    }
  }

  Future<void> _fetchEvents() async {
    final String eventsUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}/events';

    try {
      final response = await _dio.get(eventsUrl);
      final html = response.data;

      final RegExp eventRegex = RegExp(
          r'<li data-id="(\d+)" class=".*?"><a .*?><div .*?><ul .*?><li .*?">(.*?)</li></ul><p .*?">(.*?)</p><footer .*?></footer></div></a></li>',
          dotAll: true);
      final matches = eventRegex.allMatches(html);

      setState(() {
        events = matches.map((match) {
          final unescape = HtmlUnescape();
          final title = unescape.convert(
              match.group(3)?.replaceAll(RegExp(r'<br\s*/?>'), '\n').replaceAll(RegExp(r'<[^>]+>'), '').trim() ?? '');
          return {
            'dataId': match.group(1),
            'title': title,
          };
        }).toList();
        isLoadingEvents = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoadingEvents = false;
      });
    }
  }

  Future<void> _fetchCategories() async {
    final String homeUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}';
    final String categoriesUrl =
        'https://shop.weverse.io/api/wvs/display/api/v1/artist-home/categories?displayPlatform=WEB';

    try {
      // Fetch cookies by hitting the home URL
      final responseHome = await _dio.get(homeUrl);
      final cookies = responseHome.headers['set-cookie']?.join('; ') ?? '';

      // Fetch categories with headers
      final response = await _dio.get(
        categoriesUrl,
        options: Options(
          headers: {
            'Cookie': cookies,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),
      );

      // Ensure response.data contains 'categories' key
      if (response.data != null) {

        final List<dynamic> categoryData = response.data;

        setState(() {
          categories = categoryData.map((category) {
            return {
              'categoryId': category['categoryId'], // Directly use categoryId
              'name': category['name'],
              'orderNo': category['orderNo'],
            };
          }).toList();
          isLoadingCategories = false;

          if (categories.isNotEmpty) {
            selectedCategoryId = categories.first['categoryId'];
            _fetchProducts(selectedCategoryId);
          }
        });
      } else {
        throw Exception('Categories data is missing or incomplete.');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      setState(() {
        isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchProducts(int categoryId) async {
    final String categoryUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}/categories/$categoryId';
    final String productsUrl =
        'https://shop.weverse.io/api/wvs/display/api/v1/artist-home/categories/$categoryId/sales?displayPlatform=WEB';

    try {
      setState(() {
        isLoadingProducts = true;
      });

      // Fetch cookies by hitting the category URL
      final responseHome =await _dio.get(categoryUrl);
      final cookies = responseHome.headers['set-cookie']?.join('; ') ?? '';
      // Fetch products
      final response = await _dio.get(
        productsUrl,
        options: Options(
          headers: {
            'Cookie': cookies,
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          },
        ),);
      // Print JSON data for debugging

      final List<dynamic> productData = response.data['productCards'];

      setState(() {
        products = productData.map((product) {
          return {
            'saleId': product['saleId'],
            'status': product['status'],
            'thumbnailImageUrl': product['thumbnailImageUrl'],
            'name': product['name'],
            'price': product['price']['salePrice'], // Extract only salePrice
          };
        }).toList();
        isLoadingProducts = false;
      });
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoadingProducts = false;
      });
    }
  }

  void _showNoticeDetails(String dataId, String title) async {
    print('Fetching details for notice with dataId: $dataId'); // Debugging

    final String noticeUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}/notices/$dataId';

    try {
      final response = await _dio.get(noticeUrl);
      final html = response.data;

      final RegExp contentRegex =
          RegExp(r'<div[^>]*>(?:\s*<p>.*?</p>\s*)+</div>', dotAll: true);
      final match = contentRegex.firstMatch(html);

      if (match == null) {
        print('No match found for notice details.');
        throw Exception('Failed to extract notice details.');
      }

      var contentHtml = match.group(0) ?? '無法載入內容';
      final List<String> imageUrls = [];
      final RegExp imgRegex = RegExp(r'<img[^>]*src=(.*?)>', caseSensitive: false);
      
      imgRegex.allMatches(contentHtml).forEach((imgMatch) {
        final String? imgUrl = imgMatch.group(1);
        if (imgUrl != null && imgUrl.isNotEmpty) {
          var imgUrl1= imgUrl.replaceAll('"', '').replaceFirst(RegExp(r'/$'), '');;
          
          imageUrls.add(imgUrl1);
        }
      });
      
      contentHtml = contentHtml.replaceAll(RegExp(r'<br\s*/?>'), '\n');
      contentHtml = contentHtml.replaceAll(RegExp(r'<[^>]+>', dotAll: true), '');

      final unescape = HtmlUnescape();
      contentHtml = unescape.convert(contentHtml);

      final paragraphs = contentHtml.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

      if (paragraphs.isEmpty && imageUrls.isEmpty) {
        print('No content found in the event details.');
        throw Exception('No content found in event details.');
      }
      
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black,
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...paragraphs.map((paragraph) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              paragraph,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          )),
                          if (imageUrls.isNotEmpty) const SizedBox(height: 16),
                          ...imageUrls.map((imgUrl) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Column(
                                children: [
                                  Icon(Icons.broken_image, size: 64),
                                  Text('無法載入圖片: $error'),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error fetching event details: $e');
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black,
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '無法載入內容',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  void _showEventDetails(String dataId, String title) async {
    print('Fetching details for event with dataId: $dataId'); // Debugging

    final String eventUrl =
        'https://shop.weverse.io/zh-tw/shop/${widget.currency}/artists/${widget.artistId}/events/$dataId';

    try {
      final response = await _dio.get(eventUrl);
      final html = response.data;

      final RegExp contentRegex =
          RegExp(r'<div[^>]*>(?:\s*<p>.*?</p>\s*)+</div>', dotAll: true);
      final match = contentRegex.firstMatch(html);

      if (match == null) {
        print('No match found for event details.');
        throw Exception('Failed to extract event details.');
      }

      var contentHtml = match.group(0) ?? '無法載入內容';
      
      final List<String> imageUrls = [];
      final RegExp imgRegex = RegExp(r'<img[^>]*src=(.*?)>', caseSensitive: false);
      
      imgRegex.allMatches(contentHtml).forEach((imgMatch) {
        final String? imgUrl = imgMatch.group(1);
        if (imgUrl != null && imgUrl.isNotEmpty) {
          var imgUrl1= imgUrl.replaceAll('"', '').replaceFirst(RegExp(r'/$'), '');;
          
          imageUrls.add(imgUrl1);
        }
      });
      
      contentHtml = contentHtml.replaceAll(RegExp(r'<br\s*/?>'), '\n');
      contentHtml = contentHtml.replaceAll(RegExp(r'<[^>]+>', dotAll: true), '');

      final unescape = HtmlUnescape();
      contentHtml = unescape.convert(contentHtml);

      final paragraphs = contentHtml.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();

      if (paragraphs.isEmpty && imageUrls.isEmpty) {
        print('No content found in the event details.');
        throw Exception('No content found in event details.');
      }
      
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black,
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...paragraphs.map((paragraph) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              paragraph,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          )),
                          if (imageUrls.isNotEmpty) const SizedBox(height: 16),
                          ...imageUrls.map((imgUrl) => Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => Column(
                                children: [
                                  Icon(Icons.broken_image, size: 64),
                                  Text('無法載入圖片: $error'),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      print('Error fetching event details: $e');
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        color: Colors.black,
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      '無法載入內容',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white, // Set body background color to white
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: widget.logoImageUrl, // Use logoImageUrl from JSON://shop.weverse.io/assets/images/artists/${widget.artistId}/logo.png: 40,
                  height: 40,
                  width: 40,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.artistName,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            DropdownButton<String>(
              value: widget.currency,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: ['KRW', 'USD', 'JPY', 'CNY']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ArtistPage(
                        artistId: widget.artistId,
                        artistName: widget.artistName,
                        currency: newValue,
                        logoImageUrl: widget.logoImageUrl, // Pass logoImageUrl
                      ),
                    ),
                  );
                }
              },
            ),
          ],
          backgroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Notices'),
              Tab(text: 'Events'),
            ],
          ),
        ),
        body: Container(
          color: Colors.white, // Set white background
          child: TabBarView(
            children: [
              // Tab 1: Products
              Column(
                children: [
                  // Categories (Horizontal Scrollable List)
                  if (isLoadingCategories)
                    const Center(child: CircularProgressIndicator())
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final isSelected =
                              category['categoryId'] == selectedCategoryId;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryId = category['categoryId'];
                              });
                              _fetchProducts(selectedCategoryId);
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.purple
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: SizedBox(
                                width: 100, // Set a fixed width for the marquee effect
                                child: isSelected
                                    ? MarqueeText(
                                        text: category['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : Text(
                                        category['name'],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  // Products (Grid View)
                  if (isLoadingProducts)
                    const Expanded(child: Center(child: CircularProgressIndicator()))
                  else if (products.isEmpty)
                    const Expanded(child: Center(child: Text('目前沒有商品')))
                  else
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 2 / 3,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final isSoldOut = product['status'] == 'SOLD_OUT';
                          final isSaleEnd = product['status'] == 'SALE_END';
                          final overlayText = isSoldOut ? '售罄' : isSaleEnd ? '結束販售' : null;

                          // Format price to omit decimals if unnecessary
                          final price = product['price'] % 1 == 0
                              ? product['price'].toInt().toString()
                              : product['price'].toString();

                          return GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ItemPage(
                                    productId: product['saleId'],
                                    productName: product['name'],
                                    productPrice: product['price'],
                                    productImageUrl: product['thumbnailImageUrl'],
                                    artistId: widget.artistId,
                                    artistName: widget.artistName,
                                    artistImageUrl: widget.logoImageUrl,
                                    currency: widget.currency,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              child: Stack(
                                children: [
                                  // Product Image
                                  CachedNetworkImage(
                                    imageUrl: product['thumbnailImageUrl'],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: (isSoldOut || isSaleEnd)
                                        ? Colors.black.withOpacity(0.5)
                                        : null,
                                    colorBlendMode: (isSoldOut || isSaleEnd)
                                        ? BlendMode.darken
                                        : null,
                                  ),
                                  // Reserved space for product details
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.white.withOpacity(0.8), // Background for text
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: 20, // Set a fixed height for the marquee effect
                                            child: MarqueeText(
                                              text: product['name'],
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${widget.currency} $price',
                                            style: const TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Overlay for SOLD_OUT or SALE_END
                                  if (overlayText != null)
                                    Center(
                                      child: Text(
                                        overlayText,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          backgroundColor: Colors.black.withOpacity(0.5),
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
                ],
              ),
              // Tab 2: Notices
              isLoadingNotices
                  ? const Center(child: CircularProgressIndicator())
                  : notices.isEmpty
                      ? const Center(child: Text('目前沒有公告'))
                      : ListView.builder(
                          itemCount: notices.length,
                          itemBuilder: (context, index) {
                            final notice = notices[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  notice['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  _showNoticeDetails(
                                      notice['dataId'], notice['title']);
                                },
                              ),
                            );
                          },
                        ),
              // Tab 3: Events
              isLoadingEvents
                  ? const Center(child: CircularProgressIndicator())
                  : events.isEmpty
                      ? const Center(child: Text('目前沒有活動'))
                      : ListView.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) {
                            final event = events[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  event['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                onTap: () {
                                  _showEventDetails(
                                      event['dataId'], event['title']);
                                },
                              ),
                            );
                          },
                        ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add this helper widget for the marquee effect
class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;

  const MarqueeText({required this.text, required this.style, Key? key})
      : super(key: key);

  @override
  _MarqueeTextState createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: false);

    _animationController.addListener(() {
      _scrollController.jumpTo(
        _animationController.value *
            (_scrollController.position.maxScrollExtent -
                _scrollController.position.minScrollExtent),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Text(
        widget.text,
        style: widget.style,
      ),
    );
  }
}
