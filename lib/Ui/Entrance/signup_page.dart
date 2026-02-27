import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:peanut/App/configs.dart';
import 'package:peanut/App/router.dart';
import 'package:peanut/App/theme.dart';
import 'package:peanut/Services/authentication_service.dart';
import 'package:peanut/Ui/Entrance/login_page.dart';
import 'package:peanut/Ui/Entrance/onboarding.dart';
import 'package:peanut/Ui/Entrance/splash_screen_page.dart';
import 'package:peanut/Ui/Entrance/verify_page.dart';
import 'package:peanut/Utils/common_utils.dart';
import 'package:peanut/Utils/text_utils.dart';

class SignUpPage extends StatefulWidget {
  static const routeName = "/signup";

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final auth = FirebaseAuth.instance;
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordController2 = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _passwordFocusNode2 = FocusNode();
  final FocusNode _displayNameFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _showPassword2 = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordController2.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordFocusNode2.dispose();
    _displayNameFocusNode.dispose();
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
          children: [
            _title("Sign Up", "Sign Up to Create a New Account"),
            const SizedBox(height: 45),
            _otherSigninOptions(displaySignInsInRow, otherSignIWidth),
            if (Configs.googleSignUp || (Platform.isIOS && Configs.appleSignUp)) _or(),
            _textForm("Display Name", _displayNameController, _displayNameFocusNode, _emailFocusNode),
            const SizedBox(height: 20),
            _textForm("Email", _emailController, _emailFocusNode, _passwordFocusNode),
            const SizedBox(height: 20),
            _textForm("Password", _passwordController, _passwordFocusNode, _passwordFocusNode2),
            const SizedBox(height: 20),
            _pwForm2("Confirm Password", _passwordController2, _passwordFocusNode2),
            const SizedBox(height: 45),
            _mainButton("sign up"),
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

  Widget _title(String header, String desc) {
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
          _haveAcc(),
        ],
      ),
    );
  }

  Widget _textForm(String hint, TextEditingController controller, FocusNode focus, FocusNode? nextFocus) {
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

    final length = hint == "Display Name"
        ? Configs.displayNameCharLimit
        : hint == "Password"
            ? Configs.passwordCharLimit
            : Configs.emailCharLimit;

    return TextFormField(
      autofocus: false,
      controller: controller,
      focusNode: focus,
      maxLength: length,
      obscureText: hint == "Password" && !_showPassword,
      textCapitalization: hint == "Display Name" ? TextCapitalization.words : TextCapitalization.none,
      inputFormatters: hint == "Display Name" ? [TitleCaseTextFormatter(), FilteringTextInputFormatter.allow(RegExp('[ a-zA-Z0-9]'))] : null,
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
        focus.unfocus();
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      validator: (value) {
        if (value!.isEmpty) return "Required";
        if (hint == "Password") {
          if (_passwordController.text != _passwordController2.text) return "Passwords do not match";
          if (!RegExp(r"^(?=.*?[a-zA-Z])(?=.*?[0-9]).{8,}$").hasMatch(value)) return "Password must be at least 8 characters long and contain more than one letter and one digit";
        }
        if (hint == "Email" && !RegExp(r"[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?").hasMatch(value)) {
          return "Email address has to be in format:\nsomeone@example.com";
        }
        return null;
      },
    );
  }

  Widget _pwForm2(String hint, TextEditingController controller, FocusNode focusNode) {
    return TextFormField(
      autofocus: false,
      controller: controller,
      focusNode: focusNode,
      maxLength: Configs.passwordCharLimit,
      obscureText: hint.contains("Password") && !_showPassword2,
      style: const TextStyle(color: PeanutTheme.almostBlack),
      decoration: InputDecoration(
        filled: true,
        counterText: "",
        fillColor: PeanutTheme.white,
        border: const OutlineInputBorder(),
        labelText: hint,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        suffixIcon: Visibility(
          visible: controller.text.isNotEmpty,
          child: IconButton(
            onPressed: () => setState(() => _showPassword2 = !_showPassword2),
            icon: Icon(_showPassword2 ? Icons.visibility_off : Icons.visibility, color: PeanutTheme.almostBlack),
          ),
        ),
      ),
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
            await AuthenticationService.loginWithEmail(_emailController.text, _passwordController.text, displayName: _displayNameController.text, signup: true).then((_) {
              context.loaderOverlay.hide();
              Navigation.push(context, VerifyPage.routeName, args: false);
            });
          } catch (e) {
            context.loaderOverlay.hide();
            CommonUtils.toast(context, e.toString(), backgroundColor: PeanutTheme.errorColor);
          }
        },
        child: Text(button.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _otherSigninOptions(bool displayInRow, double width) {
    width = !displayInRow ? width : width;

    var widgets = [
      Visibility(
        visible: Configs.googleSignUp,
        child: _otherSignin(FontAwesomeIcons.google, "google", width),
      ),
      Visibility(
        visible: Platform.isIOS && Configs.appleSignUp,
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
              await AuthenticationService.loginWithGoogle(signup: true);
            } else if (signInOption == "apple") {
              await AuthenticationService.loginWithApple(signup: true);
            }
          } catch (e) {
            rethrow;
          }
        }

        try {
          context.loaderOverlay.show();
          await login().then((value) {
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
                "SIGN UP",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _haveAcc() {
    var textSize = 12.0;

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text(
            "Have An Account? ",
            style: TextStyle(
              fontSize: textSize,
              color: PeanutTheme.almostBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: () async {
              Navigation.push(context, LoginPage.routeName);
              await Future.delayed(const Duration(milliseconds: 500), () => _formKey.currentState?.reset());
            },
            child: Text(
              "Log In",
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
