import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'pagina_utente.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  final _supabase = Supabase.instance.client;
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = _supabase.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        //Lo snapshot contiene lo stato attuale dell'autenticazione
        // cioè l'ogetto della variabile _authStateStream
        if (snapshot.connectionState == ConnectionState.active) {
          final session = snapshot.data?.session;
          return session == null
              ? const LoginPage()
              : const UserPage(); //La StreamBuilder ascolta i cambiamenti di stato dell'autenticazione
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
