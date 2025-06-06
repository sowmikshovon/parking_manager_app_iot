import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/error_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/app_constants.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;

  // Form validation
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  void _validateFirstName(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _firstNameError = AppStrings.firstNameRequired;
      } else if (value.trim().length < 2) {
        _firstNameError = AppStrings.firstNameMinLength;
      } else {
        _firstNameError = null;
      }
    });
  }

  void _validateLastName(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _lastNameError = AppStrings.lastNameRequired;
      } else if (value.trim().length < 2) {
        _lastNameError = AppStrings.lastNameMinLength;
      } else {
        _lastNameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.trim().isEmpty) {
        _emailError = AppStrings.emailRequired;
      } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(value.trim())) {
        _emailError = AppStrings.validEmailRequired;
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = AppStrings.requiredField;
      } else if (value.length < 6) {
        _passwordError = AppStrings.invalidPassword;
      } else {
        _passwordError = null;
      }
    });
  }

  bool get _isFormValid {
    return _firstNameError == null &&
        _lastNameError == null &&
        _emailError == null &&
        _passwordError == null &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty;
  }

  Future<void> _signUp() async {
    // Validate all fields
    _validateFirstName(_firstNameController.text);
    _validateLastName(_lastNameController.text);
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);

    if (!_isFormValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ErrorService.executeWithErrorHandling<User?>(
      context,
      () async {
        // Create user account
        final UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final User? user = userCredential.user;
        if (user != null) {
          // Save additional user data to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'name':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'email': user.email,
          });
        }
        return user;
      },
      operationName: AppStrings.createAccount,
      showSnackBar: false, // We'll handle UI updates manually
    );

    setState(() {
      _isLoading = false;
    });

    if (result != null) {
      if (mounted) {
        Navigator.pop(context); // Go back to LoginPage
        SnackBarUtils.showSuccess(context, AppStrings.signUpSuccessful);
      }
    } else {
      setState(() {
        _error = AppStrings.signUpFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signUp)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.createAccount,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.firstName,
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _firstNameError,
                    ),
                    onChanged: _validateFirstName,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: AppStrings.lastName,
                      prefixIcon: const Icon(Icons.person),
                      errorText: _lastNameError,
                    ),
                    onChanged: _validateLastName,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: AppStrings.email,
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppStrings.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    onChanged: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(AppStrings.signUp),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
