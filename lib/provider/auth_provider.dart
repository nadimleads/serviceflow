import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? _user;
  String? _role;
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthStateChanged,
    );
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;

    if (_user == null) {
      _role = null;
      notifyListeners();
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();

      if (doc.exists) {
        _role = doc.data()?['role'] as String?;
      } else {
        _role = null;
      }
    } catch (e) {
      debugPrint('Role fetch error: $e');
      _role = null;
    }

    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
    try {
      _setLoading(true);

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // ❌ Do NOT manually set _user here
      // authStateChanges will handle everything

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Authentication failed";
    } catch (_) {
      return "Something went wrong. Try again.";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<String?> register(String email, String password, String role) async {
    try {
      _setLoading(true);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'role': role,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed";
    } catch (_) {
      return "Something went wrong.";
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
