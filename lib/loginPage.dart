import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _registraUtente() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      setState(() {
        _errorMessage =
            'Controlla la tua email per confermare la registrazione.';
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Si è verificato un errore inaspettato');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithProvider(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _supabase.auth.signInWithOAuth(
        provider == 'facebook' ? OAuthProvider.facebook : OAuthProvider.google,
        redirectTo: 'io.supabase.galleria://login-callback/',
      );
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Errore durante il login social');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _logIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _isLoading ? null : _registraUtente,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Registrati', style: TextStyle(fontSize: 16)),
            ),

            // ...existing code...
            const SizedBox(height: 30),
            // ...existing code...
            const SizedBox(height: 30),
            Text(
              'Oppure accedi con:',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.facebook, size: 50),
                  onPressed: () => _signInWithProvider('facebook'),
                  color: Colors.blue,
                  iconSize: 32,
                  tooltip: 'Accedi con Facebook',
                ),
                SizedBox(width: 24),
                IconButton(
                  icon: Icon(Icons.g_mobiledata, size: 50),
                  onPressed: () => _signInWithProvider('google'),
                  color: Colors.red,
                  iconSize: 32,
                  tooltip: 'Accedi con Google',
                ),
              ],
            ),
            // ...existing code...

            // ...existing code...
          ],
        ),
      ),
    );
  }
}
