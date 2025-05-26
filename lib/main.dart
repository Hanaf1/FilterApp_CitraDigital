import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';


import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo Filter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PhotoFilterScreen(),
    );
  }
}

class PhotoFilterScreen extends StatefulWidget {
  const PhotoFilterScreen({Key? key}) : super(key: key);

  @override
  _PhotoFilterScreenState createState() => _PhotoFilterScreenState();
}

class _PhotoFilterScreenState extends State<PhotoFilterScreen> {
  File? _image;
  Uint8List? _filteredImage;
  final picker = ImagePicker();
  String _currentFilter = 'Normal';
  double _brightness = 0;
  double _contrast = 1;
  double _saturation = 1;

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _applyFilter();
      }
    });
  }

  Future<void> _applyFilter() async {
    if (_image == null) return;

    final bytes = await _image!.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) return;

    late img.Image processedImage;

    switch (_currentFilter) {
      case 'Normal':
        processedImage = image.clone();
        break;
      case 'Grayscale':
        processedImage = img.grayscale(image);
        break;
      case 'Sepia':
        processedImage = _applySepia(image);
        break;
      case 'Invert':
        processedImage = img.invert(image);
        break;
      case 'Emboss':
        processedImage = _applyEmboss(image);
        break;
      default:
        processedImage = image.clone();
    }

    // Apply brightness
    if (_brightness != 0) {
      processedImage = _applyBrightness(processedImage, _brightness.toInt());
    }

    // Apply contrast
    if (_contrast != 1) {
      processedImage = _applyContrast(processedImage, _contrast);
    }

    // Apply saturation
    if (_saturation != 1) {
      processedImage = _applySaturation(processedImage, _saturation);
    }

    setState(() {
      _filteredImage = Uint8List.fromList(img.encodePng(processedImage));
    });
  }

  // Implementasi brightness karena tidak tersedia di image 4.x.x
  img.Image _applyBrightness(img.Image src, int brightness) {
    final result = src.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        final r = ((pixel.r.toInt() + brightness).clamp(0, 255));
        final g = ((pixel.g.toInt() + brightness).clamp(0, 255));
        final b = ((pixel.b.toInt() + brightness).clamp(0, 255));

        result.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
      }
    }

    return result;
  }

  // Implementasi emboss karena tidak tersedia di image 4.x.x
  img.Image _applyEmboss(img.Image src) {
    final result = src.clone();
    final temp = src.clone();

    // Kernel emboss
    final kernel = [
      [-2, -1, 0],
      [-1, 1, 1],
      [0, 1, 2]
    ];

    for (int y = 1; y < temp.height - 1; y++) {
      for (int x = 1; x < temp.width - 1; x++) {
        int r = 128;
        int g = 128;
        int b = 128;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = src.getPixel(x + kx, y + ky);
            final kernelValue = kernel[ky + 1][kx + 1];

            r += (pixel.r.toInt() * kernelValue);
            g += (pixel.g.toInt() * kernelValue);
            b += (pixel.b.toInt() * kernelValue);
          }
        }

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        result.setPixel(x, y, img.ColorRgba8(r, g, b, src.getPixel(x, y).a.toInt()));
      }
    }

    return result;
  }

  img.Image _applySepia(img.Image src) {
    final result = src.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        int tr = (r * 0.393 + g * 0.769 + b * 0.189).round();
        int tg = (r * 0.349 + g * 0.686 + b * 0.168).round();
        int tb = (r * 0.272 + g * 0.534 + b * 0.131).round();

        tr = tr.clamp(0, 255);
        tg = tg.clamp(0, 255);
        tb = tb.clamp(0, 255);

        result.setPixel(x, y, img.ColorRgba8(tr, tg, tb, pixel.a.toInt()));
      }
    }

    return result;
  }

  img.Image _applyContrast(img.Image src, double contrast) {
    final factor = (259 * (contrast * 255 + 255)) / (255 * (259 - contrast * 255));
    final result = src.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        r = ((factor * (r - 128)) + 128).round();
        g = ((factor * (g - 128)) + 128).round();
        b = ((factor * (b - 128)) + 128).round();

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        result.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
      }
    }

    return result;
  }

  img.Image _applySaturation(img.Image src, double saturation) {
    final result = src.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        int r = pixel.r.toInt();
        int g = pixel.g.toInt();
        int b = pixel.b.toInt();

        // Calculate luminance (grayscale value)
        final luminance = (0.299 * r + 0.587 * g + 0.114 * b).round();

        // Apply saturation
        r = (luminance + saturation * (r - luminance)).round().clamp(0, 255);
        g = (luminance + saturation * (g - luminance)).round().clamp(0, 255);
        b = (luminance + saturation * (b - luminance)).round().clamp(0, 255);

        result.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
      }
    }

    return result;
  }

  Future<void> _saveImage() async {
    if (_filteredImage == null) return;

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/filtered_image_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(_filteredImage!);

    // Menggunakan share_plus untuk berbagi gambar
    // User dapat menyimpan gambar dari dialog berbagi
    await Share.shareXFiles([XFile(path)],
        text: 'Gambar hasil edit dengan Photo Filter App'
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Filter App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _image == null
                ? Container(
              height: 300,
              color: Colors.grey[300],
              child: const Center(
                child: Text('Belum ada gambar dipilih'),
              ),
            )
                : _filteredImage == null
                ? Image.file(_image!)
                : Image.memory(_filteredImage!),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _filterChip('Normal'),
                _filterChip('Grayscale'),
                _filterChip('Sepia'),
                _filterChip('Invert'),
                _filterChip('Emboss'),
              ],
            ),
            const SizedBox(height: 20),
            if (_image != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Kecerahan: '),
                        Expanded(
                          child: Slider(
                            min: -255,
                            max: 255,
                            value: _brightness,
                            onChanged: (value) {
                              setState(() {
                                _brightness = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _applyFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Kontras: '),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 2,
                            value: _contrast,
                            onChanged: (value) {
                              setState(() {
                                _contrast = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _applyFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Saturasi: '),
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: 2,
                            value: _saturation,
                            onChanged: (value) {
                              setState(() {
                                _saturation = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _applyFilter();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveImage,
                child: const Text('Bagikan Gambar'),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Pilih Gambar',
        child: const Icon(Icons.add_photo_alternate),
      ),
    );
  }

  Widget _filterChip(String label) {
    return FilterChip(
      label: Text(label),
      selected: _currentFilter == label,
      onSelected: (bool selected) {
        setState(() {
          _currentFilter = label;
          _applyFilter();
        });
      },
    );
  }
}