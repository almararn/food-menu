import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream to listen to auth state changes
  Stream<User?> get user => _auth.authStateChanges();

  // 1. Check if Email is Whitelisted
  Future<bool> isEmailWhitelisted(String email) async {
    // TEMPORARY: Allow everyone to pass for now
    return true;

    /* // We will uncomment this later to enable security
    try {
      final snapshot = await _db
          .collection('whitelist')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print("Whitelist check error: $e");
      return false;
    }
    */
  }

  // 2. Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    try {
      final UserCredential userCredential = await _auth.signInWithPopup(
        googleProvider,
      );

      // Verification logic
      final bool allowed = await isEmailWhitelisted(
        userCredential.user?.email ?? "",
      );
      if (!allowed) {
        await _auth.signOut();
        throw Exception("Email not authorized. Please contact HR.");
      }
      return userCredential;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  // 3. Email & Password Sign In
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } catch (e) {
      print("Email Sign-In Error: $e");
      rethrow;
    }
  }

  // 4. Email & Password Register
  Future<UserCredential?> registerWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update Display Name
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
      }
      
      return userCredential;
    } catch (e) {
      print("Email Register Error: $e");
      rethrow;
    }
  }

  // 5. Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
