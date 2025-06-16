import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import 'photo.dart';


// Pagina per visualizzare i dettagli di una foto
// e permettere la modifica dei metadati.  

class PhotoDetailPage extends StatefulWidget {
  final Photo photo;

  const PhotoDetailPage({super.key, required this.photo});

  @override
  State<PhotoDetailPage> createState() => _PhotoDetailPageState();
}

class _PhotoDetailPageState extends State<PhotoDetailPage> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nomeController;
  late TextEditingController _luogoController;
  late TextEditingController _descrizioneController;
  bool _isEditing = false;



  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(
      text: widget.photo.location ?? '',
    );
    _luogoController = TextEditingController(text: widget.photo.author ?? '');
    _descrizioneController = TextEditingController(
      text: widget.photo.description ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _luogoController.dispose();
    _descrizioneController.dispose();
    super.dispose();
  }

  Future<void> shareImage() async {
  try {
    final url = widget.photo.publicUrl;
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Errore nel download dell\'immagine');
    }

    final bytes = response.bodyBytes;
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/shared_image.jpg';
    final file = await File(filePath).writeAsBytes(bytes);

    final box = context.findRenderObject() as RenderBox?;

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Guarda questa foto!',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Errore nella condivisione: $e')),
    );
  }
}


  Future<void> _deletePhoto() async {
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

    if (confirmed != true) return;

    try {
      
      String extractPathFromPublicUrl(String publicUrl) {
        final uri = Uri.parse(publicUrl);
        final index = uri.pathSegments.indexOf('photos');
        if (index == -1 || index + 1 >= uri.pathSegments.length) return '';
        return uri.pathSegments.sublist(index + 1).join('/');
      }

      final path = extractPathFromPublicUrl(widget.photo.publicUrl);
    
      await _supabase.storage.from('photos').remove([path]);

      // 2. Elimina dalla tabella 'photos'
      await _supabase.from('photos').delete().eq('id', widget.photo.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Foto eliminata')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante l\'eliminazione: $e')),
      );
    }
  }

  Future<void> _saveMetadata() async {
    if (!_isEditing) {
      setState(() => _isEditing = true);
      return;
    }

   

    try {
      await _supabase
          .from('photos')
          .update({
            'location': _nomeController.text.isEmpty
                ? null
                : _nomeController.text,
            'author': _luogoController.text.isEmpty
                ? null
                : _luogoController.text,
            'description': _descrizioneController.text.isEmpty
                ? null
                : _descrizioneController.text,
          })
          .eq('id', widget.photo.id);

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Metadata salvati con successo')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore durante il salvataggio: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettagli Foto'),
        actions: [
          TextButton(
            onPressed: () {
              _deletePhoto();
            },
            child: const Text('Cancella'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onDoubleTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FotoZoom(publicUrl: widget.photo.publicUrl),
                  ),
                );
              },
              child: Image.network(
                widget.photo.publicUrl,
                fit: BoxFit.fitHeight,
                width: double.infinity,
                height: 300,
              ),
            ),
            const SizedBox(height: 20),
            _buildEditableField(
              controller: _nomeController,
              label: 'Nome',
              icon: Icons.label,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              controller: _luogoController,
              label: 'Luogo',
              icon: Icons.location_on,
              enabled: _isEditing,
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              controller: _descrizioneController,
              label: 'Descrizione',
              icon: Icons.description,
              enabled: _isEditing,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'upload',
              onPressed: () {
                if (_isEditing) {
                  _saveMetadata();
                } else {
                  setState(() => _isEditing = true);
                }
              },
              tooltip: 'Edit',
              child: !_isEditing
                  ? const Icon(Icons.edit)
                  : const Icon(Icons.check),
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'condividi',
              onPressed: () async {
                if (_isEditing) {
                  await _saveMetadata();
                }
                await shareImage();
              },
              tooltip: 'Condividi',
              child: const Icon(Icons.share),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        enabled: enabled,
      ),
      maxLines: maxLines,
      enabled: enabled,
      readOnly: !enabled,
    );
  }
}

class FotoZoom extends StatelessWidget {
  const FotoZoom({super.key, required this.publicUrl});
  final String publicUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        onDoubleTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: num,
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 8.0,
              child: Image.network(
                publicUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
            ),
          ),
        ),
      ),
    )
    );
  }
}
