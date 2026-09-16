import 'package:flutter/material.dart';
import '../data/models/blood_request_model.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/activate_account_screen.dart';
import '../features/requester/screens/request_form_screen.dart';
import '../features/requester/screens/request_status_screen.dart';
import '../features/requester/screens/live_tracking_screen.dart';
import '../features/donor/screens/notification_screen.dart';
import '../features/donor/screens/respond_request_screen.dart';
import '../features/donor/screens/donation_history_screen.dart';
import '../features/admin/screens/dashboard_screen.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String activateAccountRoute = '/activate';

  // Requester
  static const String requestFormRoute = '/requester/form';
  static const String requestStatusRoute = '/requester/status';
  static const String liveTrackingRoute = '/requester/tracking';

  // Donor
  static const String donorNotificationRoute = '/donor/notifications';
  static const String respondRequestRoute = '/donor/respond';
  static const String donationHistoryRoute = '/donor/history';

  // Admin
  static const String adminDashboardRoute = '/admin/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initialRoute:
      case loginRoute:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case registerRoute:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case activateAccountRoute:
        return MaterialPageRoute(builder: (_) => const ActivateAccountScreen());

      case requestFormRoute:
        return MaterialPageRoute(builder: (_) => const RequestFormScreen());

      case requestStatusRoute:
        return MaterialPageRoute(builder: (_) => const RequestStatusScreen());

      case liveTrackingRoute:
        final requestId = settings.arguments as String? ?? '1';
        return MaterialPageRoute(
          builder: (_) => LiveTrackingScreen(requestId: requestId),
        );

      case donorNotificationRoute:
        return MaterialPageRoute(builder: (_) => const NotificationScreen());

      case respondRequestRoute:
        final request = settings.arguments as BloodRequestModel;
        return MaterialPageRoute(
          builder: (_) => RespondRequestScreen(request: request),
        );

      case donationHistoryRoute:
        return MaterialPageRoute(builder: (_) => const DonationHistoryScreen());

      case adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Halaman tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }

  static void navigateByRole(BuildContext context, String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        Navigator.pushReplacementNamed(context, adminDashboardRoute);
        break;
      case 'requester':
        Navigator.pushReplacementNamed(context, requestStatusRoute);
        break;
      case 'donor':
      default:
        Navigator.pushReplacementNamed(context, donorNotificationRoute);
        break;
    }
  }
}
