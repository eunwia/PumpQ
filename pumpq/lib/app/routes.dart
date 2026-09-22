import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/features/auth/presentation/login_screen.dart';
import 'package:pumpq/features/auth/presentation/register_screen.dart';
import 'package:pumpq/features/home/presentation/home_screen.dart';
import 'package:pumpq/features/station_map/presentation/station_map_screen.dart'; 
import 'package:pumpq/features/price_comparison/presentation/price_comparison_screen.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/features/qr_express/presentation/my_orders_screen.dart';
import 'package:pumpq/features/qr_express/presentation/qr_display_screen.dart';
import 'package:pumpq/features/loyalty_rewards/presentation/loyalty_screen.dart'; 


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
      GoRoute(
        path: '/price-comparison',
        name: AppRoute.priceComparison,
        builder: (context, state) => const PriceComparisonScreen(),
      ),
      GoRoute(
        path: '/pre-order',
        name: AppRoute.preOrder,
        builder: (context, state) => PreOrderScreen(args: state.extra as PreOrderArgs),
      ),
      GoRoute(
        path: '/my-orders',
        name: AppRoute.myOrders,
        builder: (context, state) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: '/qr-express/:orderId',
        name: AppRoute.qrExpress,
        builder: (context, state) => QrDisplayScreen(
          orderId: int.parse(state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: '/loyalty',
        name: AppRoute.loyaltyRewards,
        builder: (context, state) => const LoyaltyScreen(),
      ),
    ],
  );
});