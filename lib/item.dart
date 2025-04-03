import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html;
import 'package:url_launcher/url_launcher.dart';

class ItemPage extends StatefulWidget {
  final int productId;
  final String productName;
  final double productPrice;
  final String productImageUrl;
  final int artistId;
  final String artistName;
  final String artistImageUrl;
  final String currency;

  const ItemPage({
    super.key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productImageUrl,
    required this.artistId,
    required this.artistName,
    required this.artistImageUrl,
    required this.currency,
  });

  @override
  State<ItemPage> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final Dio _dio = Dio();
  String currentCurrency = '';
  String productPrice = '';
  List<Map<String, String>> productDetails = [];
  String productNotices = '';
  String noticesText = '';
  List<String> productImages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    currentCurrency = widget.currency;
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    final String productUrl =
        'https://shop.weverse.io/zh-tw/shop/$currentCurrency/artists/${widget.artistId}/sales/${widget.productId}';

    try {
      setState(() {
        isLoading = true;
      });

      final response = await _dio.get(productUrl);
      final document = html.parse(response.data);

      // Extract price from <strong> tag
      final priceElement = document.querySelector('strong');
      final priceText = priceElement?.text.trim() ?? 'N/A';

      // Extract details from the second <section>
      final sectionElements = document.querySelectorAll('section');
      final sectionElement = sectionElements.length > 1 ? sectionElements[1] : null;
      String noticesText = '';
      List<String> images = [];

      if (sectionElement != null) {
        // First <div>: Extract text for notices
        final firstDiv = sectionElement.children.isNotEmpty ? sectionElement.children[0] : null;
        if (firstDiv != null) {
          final noticeElements = firstDiv.querySelectorAll('dl > dt, dl > dd');
          for (var element in noticeElements) {
            noticesText += element.text.trim() + '\n';
          }
        }

        // Second <div>: Extract images
        final secondDiv = sectionElement.children.length > 1 ? sectionElement.children[1] : null;

        if (secondDiv != null) {
          final contentHtml = secondDiv.outerHtml;
          final RegExp imgRegex = RegExp(r'<noscript><img[^>]*src=(.*?)>', caseSensitive: false);

          imgRegex.allMatches(contentHtml).forEach((imgMatch) {
            final String? imgUrl = imgMatch.group(1);
            if (imgUrl != null && imgUrl.isNotEmpty) {
              final imgUrlCleaned = imgUrl.replaceAll('"', '').replaceFirst(RegExp(r'/$'), '');
              images.add(imgUrlCleaned);
            }
          });

          
        }
      }

      if (sectionElements.length > 2) {
        final section = sectionElements[2];

        // Extract header (h3) for section title
        final headerElement = section.querySelector('h3');
        final sectionTitle = headerElement?.text.trim() ?? 'Notices';

        // Extract table content (dl > div)
        final tableElements = section.querySelectorAll('dl > div');
        List<Map<String, String>> tableData = [];
        for (var row in tableElements) {
          final dt = row.querySelector('dt')?.text.trim() ?? '';
          final dd = row.querySelector('dd')?.text.trim() ?? '';
          tableData.add({'title': dt, 'content': dd});
        }

        // Assign the formatted table data to productDetails
        setState(() {
          noticesText = noticesText; // Keep the section title as a string
          noticesText= noticesText;// Keep the section title as a string
          productDetails = tableData;   // Ensure productDetails is a list of maps
        });
      }

      setState(() {
        productPrice = priceText;
        productImages = images; // Store the extracted image URLs
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
                  imageUrl: widget.artistImageUrl,
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
              Expanded(
                child: Text(
                  widget.artistName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            DropdownButton<String>(
              value: currentCurrency,
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
                  setState(() {
                    currentCurrency = newValue;
                  });
                  _fetchProductDetails();
                }
              },
            ),
          ],
          backgroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.black,
            indicatorColor: Colors.purple,
            tabs: [
              Tab(text: '詳情'),
              Tab(text: '注意事項'),
            ],
          ),
        ),
        body: Container(
          color: Colors.white,
          child: Stack(
            children: [
              TabBarView(
                children: [
                  // Tab 1: Details
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.productImageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.broken_image),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.productName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: $productPrice',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        if (noticesText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              noticesText,
                              style: const TextStyle(fontSize: 16, color: Colors.black),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (productImages.isNotEmpty)
                          
                        const SizedBox(height: 8),
                        ...productImages.map((imageUrl) => Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => Column(
                                  children: [
                                    const Icon(Icons.broken_image, size: 64),
                                    Text('Failed to load image: $error'),
                                  ],
                                ),
                              ),
                            )),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  // Tab 2: Notices
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '商品公告資訊',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        if (productDetails.isNotEmpty)
                          Table(
                            border: TableBorder.all(color: Colors.black, width: 1),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(2),
                            },
                            children: [
                              for (var row in productDetails)
                                TableRow(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        row['title'] ?? '',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(row['content'] ?? ''),
                                    ),
                                  ],
                                ),
                            ],
                          )
                        else
                          const Text(
                            'No notices available.',
                            style: TextStyle(fontSize: 16),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final Uri url = Uri.parse(
                          'https://shop.weverse.io/zh-tw/shop/$currentCurrency/artists/${widget.artistId}/sales/${widget.productId}');
                      launchUrl(url);
                    },
                    child: const Text(
                      '購買',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
