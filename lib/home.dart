import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class WallpaperScreen extends StatefulWidget {
  @override
  _WallpaperScreenState createState() => _WallpaperScreenState();
}

class _WallpaperScreenState extends State<WallpaperScreen> {
  List wallpapers = [];
  int page = 1;
  bool isLoading = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchWallpapers();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchMoreWallpapers();
      }
    });
  }

  Future<void> fetchWallpapers() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('https://wallhaven.cc/api/v1/search?q=cats&page=$page');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        wallpapers.addAll(data['data']);
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load wallpapers');
    }
  }

  Future<void> fetchMoreWallpapers() async {
    page++;
    await fetchWallpapers();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Wallhaven Wallpapers'),
      ),
      body: wallpapers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: wallpapers.length,
                    itemBuilder: (context, index) {
                      final wallpaper = wallpapers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WallpaperDetailScreen(
                                imageUrl: wallpaper['path'],
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(wallpaper['thumbs']['small'], fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
    );
  }
}

class WallpaperDetailScreen extends StatelessWidget {
  final String imageUrl;

  WallpaperDetailScreen({required this.imageUrl});

  Future<void> _downloadImage(BuildContext context) async {
    // Meminta izin penyimpanan
    var status = await Permission.storage.request();
    if (status.isGranted) {
      // Mendownload gambar
      try {
        var response = await http.get(Uri.parse(imageUrl));
        var documentDirectory = await getExternalStorageDirectory();
        var firstPath = documentDirectory?.path ?? '';
        var filePathAndName = '$firstPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
        var file = File(filePathAndName);
        await file.writeAsBytes(response.bodyBytes);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gambar berhasil didownload di $filePathAndName')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendownload gambar')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Izin penyimpanan ditolak')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Image.network(imageUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  _downloadImage(context);
                },
                icon: Icon(Icons.download),
                label: Text('Download'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
