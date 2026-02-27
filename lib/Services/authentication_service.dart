import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:peanut/App/data_store.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/Models/user_model.dart';
import 'package:peanut/Services/firestore_service.dart';
import 'package:peanut/Ui/Entrance/login_page.dart';
import 'package:peanut/Ui/Entrance/verify_page.dart';
import 'package:peanut/Utils/text_utils.dart';
import 'dart:developer';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthenticationService {
  static final _auth = FirebaseAuth.instance;

  static Future<bool> checkForLogin({bool redirect = false}) async {
    Future<bool> handleNullUser() async {
      await logout();
      if (redirect) Navigation.navigator?.routeManager.clearAndPush(Uri.parse(LoginPage.routeName));
      return false;
    }

    bool handleUnverifiedUser() {
      if (redirect) Navigation.navigator?.routeManager.clearAndPushAll([Uri.parse(LoginPage.routeName), Uri.parse(VerifyPage.routeName)]);
      return false;
    }

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return await handleNullUser();
      if (currentUser.providerData.first.providerId == EmailAuthProvider.PROVIDER_ID && !currentUser.emailVerified) return handleUnverifiedUser();
      if (redirect) {
        //Double check that user doc exist
        final doc = await FirestoreService.usersCol.doc(currentUser.uid).get();
        if (!doc.exists) return await handleNullUser();
      }

      return true;
    } catch (e) {
      log("failed login -  $e");
      return await handleNullUser();
    }
  }

  static Future<void> logout() async {
    Future<void> checkIfGoogleSignIn() async {
      GoogleSignInAccount? googleSignInAccount = GoogleSignIn().currentUser;
      bool googleSignIn = await GoogleSignIn().isSignedIn();
      if (googleSignInAccount != null && googleSignIn) await GoogleSignIn().disconnect();
    }

    await DataStore().setDataInitialized(false);
    await checkIfGoogleSignIn().catchError((e) => log("Google Sign In Error: $e"));
    await FirebaseAuth.instance.signOut().catchError((e) => log("FirebaseAuth Logout Error: $e"));
    Navigation.navigator?.routeManager.clearAndPush(Uri.parse(LoginPage.routeName));
  }

  static Future<void> loginWithEmail(String email, String password, {String? displayName, bool signup = false}) async {
    const errorMsg1 = "An existing account is already associated with this email.";
    final errorMsg2 = "Error ${signup ? "signing up" : "logging in"} with Email.";
    try {
      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signup && signInMethods.isNotEmpty) throw errorMsg1;

      if (signup) {
        await _auth.createUserWithEmailAndPassword(email: email, password: password);
        final nutUser = NutUser(
          uid: _auth.currentUser!.uid,
          displayName: TextUtil.convertTitleCase(displayName!),
          email: email.toLowerCase(),
          createdOn: DateTime.now().millisecondsSinceEpoch,
        );
        await FirestoreService.runTransaction(
          (transaction) async {
            nutUser.create(transaction);
            nutUser.updatePeanutCurrency(1000, transaction);
          },
        );
        await _auth.currentUser?.sendEmailVerification();
      } else {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
      }

      final user = _auth.currentUser;

      log("Logged In with - ${user?.uid}");
    } catch (e) {
      log(e.toString());
      if (!e.toString().contains(errorMsg1)) throw errorMsg2;
      throw e.toString();
    }
  }

  static Future<void> loginWithApple({bool signup = false}) async {
    final errorMsg1 = "Apple ${signup ? "Sign Up" : "Log In"} is not available for your device.";
    final errorMsg2 = "Error ${signup ? "signing up" : "logging in"} with Apple.";
    try {
      if (!await SignInWithApple.isAvailable()) throw errorMsg1;

      final credential = await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
      final oauthCredential = OAuthProvider("apple.com").credential(idToken: credential.identityToken);
      final authResult = await _auth.signInWithCredential(oauthCredential);
      final user = authResult.user;
      final doc = await FirestoreService.usersCol.doc(user!.uid).get();
      final userExist = doc.exists;

      if (signup && !userExist) {
        final nutUser = NutUser(
          displayName: TextUtil.convertTitleCase(credential.givenName!),
          email: credential.email!.toLowerCase(),
          uid: user.uid,
          verified: true,
          createdOn: DateTime.now().millisecondsSinceEpoch,
        );
        await FirestoreService.runTransaction(
          (transaction) async {
            nutUser.create(transaction);
            nutUser.updatePeanutCurrency(1000, transaction);
          },
        );
      }

      log("Logged In with - ${user.uid}");
    } catch (e) {
      log(e.toString());
      if (!e.toString().contains(errorMsg1)) throw errorMsg2;
      throw e.toString();
    }
  }

  static Future<void> loginWithGoogle({bool signup = false}) async {
    final errorMsg1 = "Error ${signup ? "signing up" : "logging in"} with Google.";
    final errorMsg2 = "Error ${signup ? "signing up" : "logging in"} with Google.";
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final account = await googleSignIn.signIn();
      if (account == null) throw errorMsg1;

      final userCredential = await _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: (await account.authentication).idToken, accessToken: (await account.authentication).accessToken));
      final user = userCredential.user;
      final doc = await FirestoreService.usersCol.doc(user!.uid).get();
      final userExist = doc.exists;

      if (signup && !userExist) {
        final nutUser = NutUser(
          displayName: TextUtil.convertTitleCase(user.displayName!),
          email: user.email!.toLowerCase(),
          uid: user.uid,
          verified: true,
          createdOn: DateTime.now().millisecondsSinceEpoch,
        );
        await FirestoreService.runTransaction(
          (transaction) async {
            nutUser.create(transaction);
            nutUser.updatePeanutCurrency(1000, transaction);
          },
        );
      }

      log("Logged In with - ${user.uid}");
    } catch (e) {
      log(e.toString());
      if (!e.toString().contains(errorMsg1)) throw errorMsg2;
      throw e.toString();
    }
  }

  static Future<void> resetPassword(String email) async {
    try {
      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isEmpty) throw "Error with password reset.";
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      log(e.toString());
      throw "Error with password reset.";
    }
  }
}
