import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// ─── Staff User Model ──────────────────────────────────────────────────────────
class StaffUser {
  final String uid;
  final String staffId;
  final String role; // 'admin' | 'staff'
  final bool isActive;
  final DateTime? createdAt;

  const StaffUser({
    required this.uid,
    required this.staffId,
    required this.role,
    required this.isActive,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory StaffUser.fromMap(String uid, Map<String, dynamic> data) {
    return StaffUser(
      uid: uid,
      staffId: data['staffId'] ?? '',
      role: data['role'] ?? 'staff',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// ─── Auth State ────────────────────────────────────────────────────────────────
class AuthState {
  final StaffUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({StaffUser? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ─── Auth Notifier ─────────────────────────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
    _seedDefaultAdmin();
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _init() {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = const AuthState(user: null);
      } else {
        await _loadStaffUser(firebaseUser.uid);
      }
    });
  }

  Future<void> _seedDefaultAdmin() async {
    try {
      final snap = await _firestore.collection('staff_users').limit(1).get();
      if (snap.docs.isEmpty) {
        // No staff users exist. Let's register a default admin account!
        final defaultStaffId = 'ADMIN';
        final defaultPassword = 'admin123';
        final email = _staffIdToEmail(defaultStaffId);

        // Try to create Firebase Auth user
        UserCredential credential;
        try {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: defaultPassword,
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Already created in Auth, sign in and rebuild Firestore record
            await _auth.signInWithEmailAndPassword(email: email, password: defaultPassword);
            final currentUid = _auth.currentUser!.uid;
            await _firestore.collection('staff_users').doc(currentUid).set({
              'staffId': defaultStaffId,
              'email': email,
              'role': 'admin',
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
            await _auth.signOut();
            return;
          } else {
            rethrow;
          }
        }

        final newUid = credential.user!.uid;
        await _firestore.collection('staff_users').doc(newUid).set({
          'staffId': defaultStaffId,
          'email': email,
          'role': 'admin',
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Sign out default admin so portal starts cleanly
        await _auth.signOut();
      }
    } catch (e) {
      print('Seeding default admin failed or skipped: $e');
    }
  }

  Future<void> _loadStaffUser(String uid) async {
    try {
      final doc = await _firestore.collection('staff_users').doc(uid).get().timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final staffUser = StaffUser.fromMap(uid, doc.data()!);
        state = AuthState(user: staffUser);
      } else {
        // Self-Healing Dynamic Seeder: If the Firestore document doesn't exist but they are the ADMIN user, create it on-the-fly!
        final firebaseUser = _auth.currentUser;
        if (firebaseUser != null && (firebaseUser.email == 'admin@shifa.internal' || firebaseUser.email?.toLowerCase().replaceAll(' ', '-') == 'admin@shifa.internal')) {
          final email = 'admin@shifa.internal';
          await _firestore.collection('staff_users').doc(uid).set({
            'staffId': 'ADMIN',
            'email': email,
            'role': 'admin',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 5));

          // Reload the document
          final newDoc = await _firestore.collection('staff_users').doc(uid).get().timeout(const Duration(seconds: 5));
          final staffUser = StaffUser.fromMap(uid, newDoc.data()!);
          state = AuthState(user: staffUser);
          return;
        }

        // User exists in Auth but not in Firestore — sign out
        await _auth.signOut();
        state = const AuthState(user: null, error: 'Account not found in staff registry.');
      }
    } catch (e) {
      print('=== ERROR IN _loadStaffUser: $e ===');
      await _auth.signOut();
      state = AuthState(user: null, error: e.toString());
    }
  }

  /// Login by staffId → find email → sign in with Firebase
  Future<void> loginWithStaffId({
    required String staffId,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final normalizedId = staffId.trim().toUpperCase();

      String email;
      String uid;
      Map<String, dynamic> staffData;

      // Step 1: Query Firestore document for this staffId
      var query = await _firestore
          .collection('staff_users')
          .where('staffId', isEqualTo: normalizedId)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 5));

      if (query.docs.isEmpty) {
        if (normalizedId == 'ADMIN') {
          // Bypassing check for default admin, set parameters directly
          email = 'admin@shifa.internal';
          staffData = {
            'staffId': 'ADMIN',
            'email': email,
            'role': 'admin',
            'isActive': true,
          };
          uid = 'ADMIN_TEMP_UID';
        } else {
          state = state.copyWith(isLoading: false, error: 'Staff ID not found. Please contact your administrator.');
          return;
        }
      } else {
        final staffDoc = query.docs.first;
        staffData = staffDoc.data();
        uid = staffDoc.id;

        // Check if active
        if (!(staffData['isActive'] ?? true)) {
          state = state.copyWith(isLoading: false, error: 'Your account has been deactivated. Contact admin.');
          return;
        }

        email = staffData['email'] as String? ?? '';
        if (email.isEmpty) {
          state = state.copyWith(isLoading: false, error: 'Account configuration error. Contact admin.');
          return;
        }
      }

      // Step 2: Sign in with Firebase Auth
      try {
        final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
        final realUid = credential.user!.uid;

        // DIRECT SEEDING: If this is the ADMIN user and the Firestore query was empty, write it directly right now!
        if (normalizedId == 'ADMIN' && query.docs.isEmpty) {
          print('=== DIRECT SEEDING ADMIN RECORD IN FIRESTORE ===');
          await _firestore.collection('staff_users').doc(realUid).set({
            'staffId': 'ADMIN',
            'email': email,
            'role': 'admin',
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 5));
          print('=== DIRECT SEEDING ADMIN SUCCESSFUL ===');
          
          final seededDoc = await _firestore.collection('staff_users').doc(realUid).get().timeout(const Duration(seconds: 5));
          staffData = seededDoc.data()!;
          uid = realUid;
        } else {
          uid = realUid;
        }
      } on FirebaseAuthException catch (ae) {
        if (normalizedId == 'ADMIN' && (ae.code == 'user-not-found' || ae.code == 'invalid-credential')) {
          try {
            final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
            final realUid = credential.user!.uid;

            print('=== DIRECT SEEDING ADMIN RECORD IN FIRESTORE FOR NEW USER ===');
            await _firestore.collection('staff_users').doc(realUid).set({
              'staffId': 'ADMIN',
              'email': email,
              'role': 'admin',
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
            }).timeout(const Duration(seconds: 5));
            print('=== DIRECT SEEDING ADMIN SUCCESSFUL ===');

            final seededDoc = await _firestore.collection('staff_users').doc(realUid).get().timeout(const Duration(seconds: 5));
            staffData = seededDoc.data()!;
            uid = realUid;
          } on FirebaseAuthException catch (createError) {
            if (createError.code == 'email-already-in-use') {
              throw FirebaseAuthException(code: 'wrong-password', message: 'Incorrect password.');
            } else {
              throw 'Setup Failed: $createError. Please ensure that Email/Password is enabled in your Firebase Console.';
            }
          } catch (createError) {
            throw 'Setup Failed: $createError. Please ensure that Email/Password is enabled in your Firebase Console.';
          }
        } else {
          rethrow;
        }
      }

      final staffUser = StaffUser.fromMap(uid, staffData);
      state = AuthState(user: staffUser);
    } on FirebaseAuthException catch (e) {
      print('=== FIREBASE AUTH EXCEPTION IN loginWithStaffId: ${e.code} - ${e.message} ===');
      String msg;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          msg = 'Incorrect password. Please try again.';
          break;
        case 'user-disabled':
          msg = 'Your account has been disabled.';
          break;
        case 'too-many-requests':
          msg = 'Too many failed attempts. Try again later.';
          break;
        case 'configuration-not-found':
          msg = 'Email/Password authentication is disabled in your new Firebase Console. Please go to Authentication -> Sign-in method and enable the "Email/Password" provider.';
          break;
        default:
          msg = 'Login failed: ${e.message}';
      }
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      print('=== GENERAL EXCEPTION IN loginWithStaffId: $e ===');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AuthState(user: null);
  }

  /// Admin creates a new staff/admin account
  Future<void> createStaffAccount({
    required String staffId,
    required String role,
    required String password,
  }) async {
    // Use a secondary auth instance to avoid signing out the current admin
    final secondaryApp = await _createSecondaryAuthInstance();
    try {
      final normalizedId = staffId.trim().toUpperCase();
      final email = _staffIdToEmail(normalizedId);

      // Check duplicate staffId
      final existing = await _firestore
          .collection('staff_users')
          .where('staffId', isEqualTo: normalizedId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) {
        throw 'Staff ID "$normalizedId" already exists.';
      }

      // Create Firebase Auth account on secondary instance
      final credential = await secondaryApp.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final newUid = credential.user!.uid;

      // Save Firestore document
      await _firestore.collection('staff_users').doc(newUid).set({
        'staffId': normalizedId,
        'email': email,
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out from secondary instance
      await secondaryApp.signOut();
    } catch (e) {
      await secondaryApp.signOut();
      rethrow;
    }
  }

  /// Admin disables a staff account
  Future<void> toggleStaffActive(String uid, bool isActive) async {
    await _firestore.collection('staff_users').doc(uid).update({'isActive': isActive});
  }

  /// Admin deletes a staff account
  Future<void> deleteStaffAccount(String uid) async {
    await _firestore.collection('staff_users').doc(uid).delete();
  }

  /// Admin resets staff password (by re-creating with new password)
  Future<void> resetStaffPassword(String uid, String newPassword) async {
    // Get the staff document to get email
    final doc = await _firestore.collection('staff_users').doc(uid).get();
    if (!doc.exists) throw 'Staff account not found.';
    final email = doc.data()!['email'] as String? ?? '';

    // Use Firebase Admin SDK isn't available in Flutter directly.
    // We use a workaround: sign in with the secondary instance isn't possible without old password.
    // Instead, we use sendPasswordResetEmail or store temp password approach.
    // For this app we'll update a 'pendingPasswordReset' flag - admin must know the new password.
    // In production, use Firebase Admin SDK via Cloud Functions.
    // Here we use the available approach: update a field and show instructions.
    await _firestore.collection('staff_users').doc(uid).update({
      'passwordResetAt': FieldValue.serverTimestamp(),
      'passwordResetBy': state.user?.staffId ?? 'Admin',
    });
    // Send password reset email as a practical alternative
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _staffIdToEmail(String staffId) {
    // Convert staffId like "NUR-102" to "nur-102@shifa.internal"
    return '${staffId.toLowerCase().replaceAll(' ', '-')}@shifa.internal';
  }

  Future<FirebaseAuth> _createSecondaryAuthInstance() async {
    try {
      FirebaseApp secondaryApp;
      try {
        secondaryApp = Firebase.app('SecondaryApp');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'SecondaryApp',
          options: Firebase.app().options,
        );
      }
      return FirebaseAuth.instanceFor(app: secondaryApp);
    } catch (e) {
      print('Secondary app initialization fallback: $e');
      return _auth;
    }
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final currentStaffUserProvider = Provider<StaffUser?>((ref) {
  return ref.watch(authProvider).user;
});

final currentStaffIdProvider = Provider<String>((ref) {
  return ref.watch(currentStaffUserProvider)?.staffId ?? '';
});

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(currentStaffUserProvider)?.isAdmin ?? false;
});

// All staff users stream for Admin Panel
final allStaffStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance
      .collection('staff_users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final data = doc.data();
            data['uid'] = doc.id;
            return data;
          }).toList());
});
