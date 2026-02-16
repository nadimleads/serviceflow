import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serviceflow/provider/auth_provider.dart';

class LoginCEO extends StatefulWidget {
  const LoginCEO({super.key});

  @override
  State<LoginCEO> createState() => _LoginCEOState();
}

class _LoginCEOState extends State<LoginCEO> {
  final _formKey = GlobalKey<FormState>();

  var _enteredEmail = '';
  var _enteredPassword = '';

  Future<void> _login() async {
    final isValid = _formKey.currentState!.validate();
    // if valid na hoy
    if (!isValid) return;

    _formKey.currentState!.save();

    final auth = Provider.of<AuthProvider>(context, listen: false);

    final error = await auth.login(_enteredEmail, _enteredPassword);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    // ❌ NO Navigator.push here
    // AuthWrapper will automatically redirect to CEO dashboard
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CEO Login',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(50),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(
                  Icons.manage_accounts_outlined,
                  size: 80,
                  color: Colors.deepOrange,
                ),

                const SizedBox(height: 10),

                const Text(
                  'Welcome CEO!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),

                const SizedBox(height: 10),

                const Text(
                  'Login to manage your system',
                  style: TextStyle(fontSize: 16),
                ),

                const SizedBox(height: 30),

                // Email
                TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.mail_outline),
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty ||
                        !value.contains('@')) {
                      return 'Please enter a valid email.';
                    }
                    return null;
                  },
                  onSaved: (value) => _enteredEmail = value!.trim(),
                ),

                const SizedBox(height: 15),

                // Password
                TextFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.trim().length < 6) {
                      return 'Password must be at least 6 characters.';
                    }
                    return null;
                  },
                  onSaved: (value) => _enteredPassword = value!,
                ),

                const SizedBox(height: 30),

                auth.isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 17),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
