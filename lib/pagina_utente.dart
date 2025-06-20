import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'photo.dart';
import 'dettagli_foto.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    _aggiornaFoto();
  }

  void _aggiornaFoto() {
    setState(() {
      _photosFuture = _scaricaListaFoto();
    });
  }

  void _mostraIstruzioni() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Istruzioni'),
        content: const Text(
          'Per aggiungere foto, usa il pulsante "+" per caricare immagini dalla galleria o il pulsante della fotocamera per scattare una foto. '
          'Puoi eliminare le foto con un tap prolungato su di esse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _deletePhoto(Photo photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina foto'),
        content: const Text('Vuoi davvero eliminare questa foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;

    try {
      String extractPathFromPublicUrl(String publicUrl) {
        final uri = Uri.parse(publicUrl);
        final index = uri.pathSegments.indexOf('photos');
        if (index == -1 || index + 1 >= uri.pathSegments.length) return '';
        return uri.pathSegments.sublist(index + 1).join('/');
      }

      final path = extractPathFromPublicUrl(photo.publicUrl);

      await _supabase.storage.from('photos').remove([path]);
      await _supabase.from('photos').delete().eq('id', photo.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto eliminata')));
      }
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
      return false;
    }
  }

  void _cancellaTutto() async {
    setState(() => _isUploading = true);

    try {
      final listaFoto = await _scaricaListaFoto();

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (listaFoto.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessuna foto da eliminare')),
        );
        return;
      }

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancella tutto'),
          content: const Text('Vuoi davvero eliminare tutte le foto?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final confirmedSicuro = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancella tutto'),
          content: const Text(
            'Quest\'operazione eliminerà tutte le foto ed è irreversibile. Sei sicuro?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annulla'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Elimina'),
            ),
          ],
        ),
      );

      if (confirmedSicuro != true) return;

      // Cancella i file dallo storage

      for (final photo in listaFoto) {
        await _supabase.storage.from('photos').remove([photo.filePath]);
      }

      // Cancella tutte le foto dell'utente
      await _supabase.from('photos').delete().eq('user_id', user.id);
    } catch (e) {
      print('Error deleting photos: $e');
    } finally {
      setState(() => _isUploading = false);
      _aggiornaFoto();
    }
  }

  Future<void> _scattaFoto() async {
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
      _aggiornaFoto();
    }
  }

  Future<List<Photo>> _scaricaListaFoto() async {
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

  Future<void> _uploadFoto() async {
    setState(() => _isUploading = true);

    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles == null || pickedFiles.isEmpty) return;

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      for (final pickedFile in pickedFiles) {
        final file = File(pickedFile.path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        final filePath = '${user.id}/$fileName';

        // Upload file to storage
        await _supabase.storage.from('photos').upload(filePath, file);

        // Insert metadata into database
        await _supabase.from('photos').insert({
          'user_id': user.id,
          'file_path': filePath,
          'location': null,
          'author': null,
          'description': null,
        });
      }
    } catch (e) {
      print('Error uploading files: $e');
    } finally {
      setState(() => _isUploading = false);
      _aggiornaFoto();
    }
  }

  Future<void> _logOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galleria Personale'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _mostraIstruzioni,
            tooltip: 'Istruzioni',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logOut,
            tooltip: 'Logout',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _cancellaTutto,
            tooltip: 'Cancella Tutto',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _aggiornaFoto();
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
                      onPressed: _aggiornaFoto,
                      child: const Text('Riprova'),
                    ),
                  ],
                ),
              );
            }

            final photos = snapshot.data ?? [];

            // ...existing code...
            return photos.isEmpty
                ? const Center(
                    child: Text(
                      'Nessuna foto trovata',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(2.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 1,
                          mainAxisSpacing: 1,
                          childAspectRatio: 1,
                        ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PhotoDetailPage(photo: photo),
                              ),
                            ).then(
                              (_) => _aggiornaFoto(),
                            ); //Al ritorno aggiorna la lista
                          },

                          onLongPress: () async {
                            final deleted = await _deletePhoto(photo);
                            if (deleted) {
                              _aggiornaFoto();
                            }
                          },

                          child: AspectRatio(
                            aspectRatio: 1,
                            child: CachedNetworkImage(
                              imageUrl: photo.publicUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
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
              onPressed: _isUploading ? null : _uploadFoto,
              child: _isUploading
                  ? const CircularProgressIndicator(
                      color: Color.fromARGB(255, 0, 90, 150),
                    )
                  : const Icon(Icons.add_photo_alternate),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'camera',
              onPressed: _isUploading ? null : _scattaFoto,
              tooltip: 'Scatta Foto',
              child: _isUploading
                  ? const CircularProgressIndicator(
                      color: Color.fromARGB(255, 0, 90, 150),
                    )
                  : const Icon(Icons.camera_enhance),
            ),
          ],
        ),
      ),
    );
  }
}
