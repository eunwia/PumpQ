import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/features/auth/presentation/login_screen.dart';
import 'package:pumpq/features/auth/presentation/register_screen.dart';
import 'package:pumpq/features/home/presentation/home_screen.dart';
import 'package:pumpq/features/station_map/presentation/station_map_screen.dart'; // ADD THIS IMPORT


final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        name: AppRoute.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: AppRoute.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        name: AppRoute.home,
        builder: (context, state) => const HomeScreen(),
      ),
       GoRoute(
        path: '/station-map',
        name: AppRoute.stationMap,
        builder: (context, state) => const StationMapScreen(),
      ),
    ],
  );
});