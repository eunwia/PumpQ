import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pumpq/app/main_shell.dart';
import 'package:pumpq/app/route_names.dart';
import 'package:pumpq/features/ai_insights/presentation/insights_screen.dart';
import 'package:pumpq/features/auth/presentation/login_screen.dart';
import 'package:pumpq/features/auth/presentation/register_screen.dart';
import 'package:pumpq/features/home/presentation/home_screen.dart';
import 'package:pumpq/features/loyalty_rewards/presentation/loyalty_screen.dart';
import 'package:pumpq/features/pre_order/presentation/pre_order_screen.dart';
import 'package:pumpq/features/price_comparison/presentation/price_comparison_screen.dart';
import 'package:pumpq/features/profile/presentation/profile_screen.dart';
import 'package:pumpq/features/qr_express/presentation/my_orders_screen.dart';
import 'package:pumpq/features/qr_express/presentation/order_detail_screen.dart';
import 'package:pumpq/features/qr_express/presentation/qr_display_screen.dart';
import 'package:pumpq/features/station_map/presentation/station_map_screen.dart';
import 'package:pumpq/features/wallet/presentation/wallet_screen.dart';
import 'package:pumpq/features/promotions/presentation/promotions_screen.dart';

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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              name: AppRoute.home,
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'price-comparison',
                  name: AppRoute.priceComparison,
                  builder: (context, state) => const PriceComparisonScreen(),
                ),
                GoRoute(
                  path: 'pre-order',
                  name: AppRoute.preOrder,
                  builder: (context, state) => PreOrderScreen(args: state.extra as PreOrderArgs),
                ),
                GoRoute(
                  path: 'insights',
                  name: AppRoute.insights,
                  builder: (context, state) => const InsightsScreen(),
                ),
                GoRoute(
                  path: 'promotions',
                  name: AppRoute.promotions,
                  builder: (context, state) => const PromotionsScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/map',
              name: AppRoute.stationMap,
              builder: (context, state) => const StationMapScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/orders',
              name: AppRoute.myOrders,
              builder: (context, state) => const MyOrdersScreen(),
              routes: [
                GoRoute(
                  path: ':orderId',
                  name: AppRoute.orderDetail,
                  builder: (context, state) => OrderDetailScreen(
                    orderId: int.parse(state.pathParameters['orderId']!),
                  ),
                ),
                GoRoute(
                  path: 'qr/:orderId',
                  name: AppRoute.qrExpress,
                  builder: (context, state) => QrDisplayScreen(
                    orderId: int.parse(state.pathParameters['orderId']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/wallet',
              name: AppRoute.wallet,
              builder: (context, state) => const WalletScreen(),
              routes: [
                GoRoute(
                  path: 'loyalty',
                  name: AppRoute.loyaltyRewards,
                  builder: (context, state) => const LoyaltyScreen(),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              name: AppRoute.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
});