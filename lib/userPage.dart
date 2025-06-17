import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'photo.dart';
import 'photoDetailPage.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final _supabase = Supabase.instance.client;
  late Future<List<Photo>> _photosFuture;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _refreshPhotos();
  }

  void _refreshPhotos() {
    setState(() {
      _photosFuture = _fetchPhotos();
    });
  }

  Future<void> _takePhoto() async {
    setState(() => _isUploading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final file = File(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${user.id}/$fileName';

      // Upload file nello storage Supabase
      await _supabase.storage.from('photos').upload(filePath, file);

      // Inserisci i metadati nel database
      await _supabase.from('photos').insert({
        'user_id': user.id,
        'file_path': filePath,
        'location': null,
        'author': null,
        'description': null,
      });
    } catch (e) {
      print('Error taking photo: $e');
    } finally {
      setState(() => _isUploading = false);
      _refreshPhotos();
    }
  }

  Future<List<Photo>> _fetchPhotos() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final response = await _supabase
          .from('photos')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Photo.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching photos: $e');
      return [];
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() => _isUploading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final file = File(pickedFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${user.id}/$fileName';

      // Upload file to storage
      await _supabase.storage.from('photos').upload(filePath, file);

      // Insert metadata into database - AGGIUNGI user_id
      await _supabase.from('photos').insert({
        'user_id': user.id, // IMPORTANTE!
        'file_path': filePath,
        'location': null,
        'author': null,
        'description': null,
      });
    } catch (e) {
      print('Error uploading file: $e');
    } finally {
      setState(() => _isUploading = false);
      _refreshPhotos();
    }
  }

  Future<void> _signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galleria Personale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshPhotos();
          await Future.delayed(const Duration(seconds: 1));
        },
        child: FutureBuilder<List<Photo>>(
          future: _photosFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isUploading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Errore nel caricamento dell\'immagine',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshPhotos,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            final photos = snapshot.data ?? [];

            return photos.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna foto trovata',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return SizedBox.expand(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            children: [
                              Image.network(
                                photo.publicUrl,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: 100,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PhotoDetailPage(photo: photo),
                                    ),
                                  ).then((_) => _refreshPhotos());
                                },
                                child: Text('Dettagli'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
          },
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'upload',
              onPressed: _isUploading ? null : _uploadPhoto,
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.add_photo_alternate),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'camera',
              onPressed: _isUploading ? null : _takePhoto,
              tooltip: 'Scatta Foto',
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_enhance),
            ),
          ],
        ),
      ),
    );
  }
}
