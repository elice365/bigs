import 'package:bigs/providers/auth_provider.dart';
import 'package:bigs/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _signupUsernameController = TextEditingController();
  final _signupNameController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      context.read<AuthProvider>().clearError();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _signupUsernameController.dispose();
    _signupNameController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, _) => LoadingOverlay(
                      isLoading: auth.isLoading,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'BIGS 커뮤니티',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '로그인 또는 회원가입 후 게시판을 이용해주세요.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              TabBar(
                                controller: _tabController,
                                labelColor: theme.colorScheme.primary,
                                labelStyle: theme.textTheme.titleMedium,
                                tabs: const [
                                  Tab(text: '로그인'),
                                  Tab(text: '회원가입'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: _tabController.index == 0
                                    ? _buildLoginForm(context, auth)
                                    : _buildSignUpForm(context, auth),
                              ),
                              if (auth.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  auth.errorMessage!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.error,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginUsernameController,
            decoration: const InputDecoration(
              labelText: '아이디 (이메일)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: _validatePassword,
            onFieldSubmitted: (_) => _submitLogin(auth),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading ? null : () => _submitLogin(auth),
            child: const Text('로그인'),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpForm(BuildContext context, AuthProvider auth) {
    return Form(
      key: _signupFormKey,
      child: Column(
        key: const ValueKey('signup_form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _signupUsernameController,
            decoration: const InputDecoration(
              labelText: '아이디 (이메일)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupNameController,
            decoration: const InputDecoration(
              labelText: '이름',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '이름을 입력해주세요.';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupPasswordController,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: _validatePassword,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupConfirmPasswordController,
            decoration: const InputDecoration(
              labelText: '비밀번호 확인',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '비밀번호 확인을 입력해주세요.';
              }
              if (value != _signupPasswordController.text) {
                return '비밀번호가 일치하지 않습니다.';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submitSignUp(auth),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: auth.isLoading ? null : () => _submitSignUp(auth),
            child: const Text('회원가입'),
          ),
        ],
      ),
    );
  }

  void _submitLogin(AuthProvider auth) async {
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }
    final success = await auth.signIn(
      username: _loginUsernameController.text.trim(),
      password: _loginPasswordController.text,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('로그인되었습니다.')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? '로그인에 실패했습니다.'),
        ),
      );
    }
  }

  void _submitSignUp(AuthProvider auth) async {
    if (!_signupFormKey.currentState!.validate()) {
      return;
    }
    final success = await auth.signUp(
      username: _signupUsernameController.text.trim(),
      name: _signupNameController.text.trim(),
      password: _signupPasswordController.text,
      confirmPassword: _signupConfirmPasswordController.text,
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        const SnackBar(content: Text('회원가입이 완료되었습니다. 로그인해주세요.')),
      );
      _tabController.index = 0;
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? '회원가입에 실패했습니다.'),
        ),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해주세요.';
    }
    final emailRegex =
        RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    return null;
  }
}
