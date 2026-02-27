import 'dart:io';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Services/authentication_service.dart';
import 'package:peanut/Ui/Entrance/onboarding.dart';
import 'package:peanut/Ui/Entrance/signup_page.dart';
import 'package:peanut/Ui/Entrance/splash_screen_page.dart';
import 'package:peanut/Utils/common_utils.dart';

class LoginPage extends StatefulWidget {
  static const routeName = "/login";

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _resetEmail = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isResetPassword = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _resetEmail.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: PeanutTheme.transparent,
            body: PeanutTheme.background(
              Center(
                child: KeyboardDismissOnTap(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: _showLoginMenu(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Onboarding(),
        ],
      ),
    );
  }

  Widget _backButton() {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => setState(() {
          _formKey.currentState?.reset();
          _isResetPassword = false;
          _resetEmail.clear();
        }),
        icon: const Icon(
          Icons.arrow_back_rounded,
          size: 40,
        ),
      ),
    );
  }

  Widget _showLoginMenu() {
    var width = MediaQuery.of(context).size.width < 500 ? MediaQuery.of(context).size.width : 500.0;
    var menuPadding = 30.0;
    var otherSignIWidth = 120.0;
    var displaySignInsInRow = width - (menuPadding * 2) > otherSignIWidth * 3;

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(horizontal: menuPadding, vertical: 50),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _isResetPassword
              ? [
                  _backButton(),
                  _title("Password Reset", "Enter Registered Email to Continue", displaySignUp: false),
                  const SizedBox(height: 45),
                  _textForm("Email", _resetEmail, null, null),
                  const SizedBox(height: 45),
                  _mainButton("reset"),
                ]
              : [
                  _title("Login", "Sign In to Continue"),
                  const SizedBox(height: 45),
                  // _otherSigninOptions(displaySignInsInRow, otherSignIWidth),
                  // _or(),
                  _textForm("Email", _emailController, _emailFocusNode, _passwordFocusNode),
                  const SizedBox(height: 20),
                  _textForm("Password", _passwordController, _passwordFocusNode, null),
                  const SizedBox(height: 45),
                  _mainButton("sign in"),
                  _forgotPW(),
                ],
        ),
      ),
    );
  }

  Widget _or() {
    Widget divider = Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        color: PeanutTheme.white,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          divider,
          const Text(
            "OR",
            style: TextStyle(color: PeanutTheme.almostBlack),
          ),
          divider,
        ],
      ),
    );
  }

  Widget _title(String header, String desc, {bool displaySignUp = true}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            header,
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
          ),
          Text(
            desc,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          if (displaySignUp) _dontHaveAcc(),
        ],
      ),
    );
  }

  Widget _textForm(String hint, TextEditingController controller, FocusNode? focus, FocusNode? nextFocus) {
    Widget suffixIcon = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Visibility(
          visible: controller.text.isNotEmpty && hint != "Password",
          child: IconButton(
            onPressed: () {
              controller.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
          ),
        ),
        Visibility(
          visible: controller.text.isNotEmpty && hint == "Password",
          child: IconButton(
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility, color: PeanutTheme.almostBlack),
          ),
        ),
      ],
    );

    final length = hint == "Password" ? Configs.passwordCharLimit : Configs.emailCharLimit;

    return TextFormField(
      autofocus: false,
      controller: controller,
      focusNode: focus,
      maxLength: length,
      obscureText: hint == "Password" && !_showPassword,
      style: const TextStyle(color: PeanutTheme.almostBlack),
      decoration: InputDecoration(
        filled: true,
        counterText: "",
        fillColor: PeanutTheme.white,
        border: const OutlineInputBorder(),
        labelText: hint,
        suffixIcon: suffixIcon,
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onFieldSubmitted: (term) {
        focus?.unfocus();
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      validator: (value) => value!.isEmpty ? "Required" : null,
    );
  }

  Widget _mainButton(String button) {
    return SizedBox(
      height: 45,
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(20),
              ),
            ),
          ),
        ),
        onPressed: () async {
          FocusScope.of(context).unfocus();
          var validate = _formKey.currentState?.validate();
          if (!validate!) return;

          try {
            context.loaderOverlay.show();
            if (button == "reset") {
              await AuthenticationService.resetPassword(_resetEmail.text).then((_) async {
                context.loaderOverlay.hide();
                _resetEmail.clear();
                await showOkAlertDialog(context: context, message: "An email will be sent to your registered email shortly\nPlease check your email.");
                setState(() => _isResetPassword = false);
              });
            } else {
              await AuthenticationService.loginWithEmail(_emailController.text, _passwordController.text).then((_) {
                context.loaderOverlay.hide();
                Navigation.push(context, SplashScreenPage.routeName, clear: true);
              });
            }
          } catch (e) {
            context.loaderOverlay.hide();
            CommonUtils.toast(context, e.toString(), backgroundColor: PeanutTheme.errorColor);
          }
        },
        child: Text(button.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _forgotPW() {
    return TextButton(
      onPressed: () {
        setState(() {
          _formKey.currentState?.reset();
          _isResetPassword = true;
          _passwordController.clear();
        });
      },
      child: const Text(
        'Forgot Password?',
        style: TextStyle(fontSize: 13, decoration: TextDecoration.underline, color: PeanutTheme.darkOrange),
      ),
    );
  }

  Widget _otherSigninOptions(bool displayInRow, double width) {
    width = !displayInRow ? width : width;

    var widgets = [
      _otherSignin(FontAwesomeIcons.google, "google", width),
      Visibility(
        visible: Platform.isIOS,
        child: _otherSignin(FontAwesomeIcons.apple, "apple", width),
      ),
    ];

    return displayInRow
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widgets,
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widgets,
          );
  }

  Widget _otherSignin(IconData icon, String signInOption, double width) {
    return GestureDetector(
      onTap: () async {
        Future<void> login() async {
          try {
            if (signInOption == "google") {
              await AuthenticationService.loginWithGoogle();
            } else if (signInOption == "apple") {
              await AuthenticationService.loginWithApple();
            }
          } catch (e) {
            rethrow;
          }
        }

        try {
          context.loaderOverlay.show();
          await login().then((_) {
            context.loaderOverlay.hide();
            Navigation.push(context, SplashScreenPage.routeName);
          });
        } catch (e) {
          context.loaderOverlay.hide();
          CommonUtils.toast(context, e.toString(), backgroundColor: PeanutTheme.errorColor);
        }
      },
      child: Container(
        height: 35,
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        padding: const EdgeInsets.only(right: 20, left: 5, top: 5, bottom: 5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: PeanutTheme.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(width: 1, color: PeanutTheme.primaryColor),
        ),
        child: Row(
          children: [
            ClipRRect(
              child: SizedBox(
                height: 25,
                width: 40,
                child: signInOption == "google"
                    ? Image.asset(
                        "assets/google_logo.png",
                        fit: BoxFit.contain,
                      )
                    : Icon(icon, size: 20, color: PeanutTheme.black),
              ),
            ),
            const Expanded(
              child: Text(
                "SIGN IN",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dontHaveAcc() {
    var textSize = 12.0;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text(
            "Don't have account? ",
            style: TextStyle(
              fontSize: textSize,
              color: PeanutTheme.almostBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigation.push(context, SignUpPage.routeName);
              await Future.delayed(const Duration(milliseconds: 500), () => _formKey.currentState?.reset());
            },
            child: Text(
              "Sign up",
              style: TextStyle(
                color: PeanutTheme.darkOrange,
                fontSize: textSize + 3,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
