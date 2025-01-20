import 'package:flutter/material.dart';
import 'package:qabas/utils/app_colors.dart';
import 'package:qabas/widgets/login_button.dart';
import 'package:qabas/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final String userType;
  final Color buttonColor;
  final IconData icon;

  const LoginPage({
    Key? key,
    required this.userType,
    required this.buttonColor,
    required this.icon,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.green1),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        backgroundColor: const Color(0xFFFFFBF7),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildLogo(),
                  const SizedBox(height: 20),
                  Text(
                    'تسجيل الدخول ${widget.userType}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.green1),
                  ),
                  const SizedBox(height: 40),
                  _buildTextField('اسم المستخدم', controller: _usernameController),
                  const SizedBox(height: 20),
                  _buildTextField('كلمة المرور', isPassword: true, controller: _passwordController),
                  const SizedBox(height: 40),
                  LoginButton(
                    text: 'تسجيل الدخول',
                    color: widget.buttonColor,
                    icon: widget.icon,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Image.asset('lib/assets/logo.jpg', width: 80, height: 80),
      ),
    );
  }

    Widget _buildTextField(String hint, {bool isPassword = false, required TextEditingController controller}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    );
  }

  void _handleLogin() async {
    final isLoggedIn = await _authService.login(context,
      widget.userType,
      _usernameController.text,
      _passwordController.text,
    );

    if (isLoggedIn) {
      print('${widget.userType} logged in successfully');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login successful')),
      );
      // TODO: Implement navigation to appropriate dashboard based on user type
    } else {
      print('Login failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}