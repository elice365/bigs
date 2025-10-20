import 'package:bigs/api/auth_repository.dart';
import 'package:bigs/api/bigs_api_client.dart';
import 'package:bigs/api/board_repository.dart';
import 'package:bigs/providers/auth_provider.dart';
import 'package:bigs/providers/board_provider.dart';
import 'package:bigs/screens/auth/auth_screen.dart';
import 'package:bigs/screens/board/board_list_screen.dart';
import 'package:bigs/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final apiClient = BigsApiClient();
  runApp(BigsApp(
    preferences: preferences,
    apiClient: apiClient,
  ));
}

class BigsApp extends StatefulWidget {
  const BigsApp({
    super.key,
    required this.preferences,
    required this.apiClient,
  });

  final SharedPreferences preferences;
  final BigsApiClient apiClient;

  @override
  State<BigsApp> createState() => _BigsAppState();
}

class _BigsAppState extends State<BigsApp> {
  late final AuthRepository _authRepository;
  late final BoardRepository _boardRepository;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(widget.apiClient);
    _boardRepository = BoardRepository(widget.apiClient);
  }

  @override
  void dispose() {
    widget.apiClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: _authRepository),
        Provider<BoardRepository>.value(value: _boardRepository),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthRepository>(),
            widget.preferences,
          )..loadSession(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, BoardProvider>(
          create: (context) =>
              BoardProvider(context.read<BoardRepository>()),
          update: (context, auth, boardProvider) {
            boardProvider ??=
                BoardProvider(context.read<BoardRepository>());
            boardProvider.updateAuth(auth);
            return boardProvider;
          },
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'BIGS 게시판',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            home: _buildHome(auth),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      useMaterial3: true,
    );
    return base.copyWith(
      scaffoldBackgroundColor: Colors.grey[50],
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildHome(AuthProvider auth) {
    if (!auth.isInitialized) {
      return const SplashScreen();
    }
    if (auth.isAuthenticated) {
      return const BoardListScreen();
    }
    return const AuthScreen();
  }
}
