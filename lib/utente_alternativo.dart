import 'package:flutter/material.dart';
import 'package:galleria/pagina_utente.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dettagli_foto.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class UtenteAlternativo extends StatefulWidget {
  const UtenteAlternativo({super.key});

  @override
  State<UtenteAlternativo> createState() => _UtenteAlternativoState();
}

class _UtenteAlternativoState extends State<UtenteAlternativo> {
  final _supabase = Supabase.instance.client;
  late Future<List<Photo>> _photosFuture;
  final _controller = PageController();
  late int conto;
  int _paginaCorrente = 0;

  @override
  void initState() {
    super.initState();
    _aggiornaFoto();
    conto = 0;
    _controller.addListener(() {
      setState(() {
        _paginaCorrente = _controller.page?.round() ?? 0;
      });
    });
  }

  Future<void> _cancellaFotoCorrente() async {
    final photos = await _photosFuture;
    if (_paginaCorrente < 0 || _paginaCorrente >= photos.length) return;
    final photoDaCancellare = photos[_paginaCorrente];
    final deleted = await _deletePhoto(photoDaCancellare);
    if (deleted) {
      _aggiornaFoto();
      // Se sei sull'ultima pagina e la cancelli, torna indietro di una
      if (_paginaCorrente >= photos.length - 1 && _paginaCorrente > 0) {
        _controller.jumpToPage(_paginaCorrente - 1);
      }
    }
  }

  void _aggiornaFoto() {
    setState(() {
      _photosFuture = _scaricaListaFoto();
    });
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

  Future<int> _contaFotoUtente() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        conto = 0;
        return 0;
      }

      final response = await _supabase
          .from('photos')
          .select()
          .eq('user_id', user.id);
      print((response as List).length);
      return (response as List).length;
    } catch (e) {
      print('Eccezione nel conteggio foto: $e');
      conto = 0;
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            //appbar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_circle_left_outlined, size: 40),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserPage()),
                    );
                  },
                ),
                IconButton(
                  onPressed: _cancellaFotoCorrente,
                  icon: Icon(Icons.delete),
                ),
              ],
            ),

            Divider(color: Colors.grey),

            SizedBox(height: 10),

            //scollabe horizontal list view
            Expanded(
              child: FutureBuilder<List<Photo>>(
                future: _photosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Errore: ${snapshot.error}'));
                  }

                  final photos = snapshot.data ?? [];
                  if (photos.isEmpty) {
                    return const Center(child: Text('Nessuna foto trovata'));
                  }

                  return PageView(
                    scrollDirection: Axis.horizontal,
                    controller: _controller,
                    children: [
                      for (int i = 0; i < photos.length; i++)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PhotoDetailPage(photo: photos[i]),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: (photos[i].publicUrl),
                                fit: BoxFit.contain,
                                width: 500,
                                height: 300,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Divider(color: Colors.blue, height: 2),
            // SizedBox(height: 20),
            FutureBuilder<int>(
              future: _contaFotoUtente(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SmoothPageIndicator(
                    controller: _controller,
                    count: count,
                    effect: ScrollingDotsEffect(
                      activeDotColor: Colors.blue,
                      dotColor: Colors.grey,
                      dotHeight: 10,
                      dotWidth: 10,
                      maxVisibleDots:
                          7, // Mostra al massimo 7 indicatori, il resto viene "compresso"
                      spacing: 6,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
