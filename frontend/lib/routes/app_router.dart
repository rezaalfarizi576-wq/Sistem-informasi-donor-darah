import 'package:flutter/material.dart';
import '../data/models/blood_request_model.dart';
import '../data/models/dispatch_ticket_model.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/activate_account_screen.dart';
import '../features/requester/screens/request_form_screen.dart';
import '../features/requester/screens/request_status_screen.dart';
import '../features/requester/screens/requester_profile_screen.dart';
import '../features/requester/screens/requester_request_screen.dart';
import '../features/requester/screens/requester_tracking_screen.dart';
import '../features/donor/screens/donor_dashboard_screen.dart';
import '../features/donor/screens/donor_dispatch_screen.dart';
import '../features/donor/screens/notification_screen.dart';
import '../features/donor/screens/respond_request_screen.dart';
import '../features/donor/screens/donation_history_screen.dart';
import '../features/donor/screens/donation_success_screen.dart';
import '../features/donor/screens/donor_live_tracking_screen.dart';
import '../features/admin/screens/admin_shell_screen.dart';

class AppRouter {
  static const String initialRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String activateAccountRoute = '/activate';

  // Requester
  static const String requesterRequestRoute = '/requester/permohonan';
  static const String requestFormRoute = '/requester/form';
  static const String requestStatusRoute = '/requester/status';
  static const String liveTrackingRoute = '/requester/tracking';
  static const String requesterPantauRoute = '/requester/pantau';
  static const String requesterProfileRoute = '/requester/profile';

  // Donor
  static const String donorDashboardRoute = '/donor/dashboard';
  static const String donorDispatchRoute = '/donor/dispatch';
  static const String donorNotificationRoute = '/donor/notifications';
  static const String respondRequestRoute = '/donor/respond';
  static const String donationHistoryRoute = '/donor/history';
  static const String donationSuccessRoute = '/donor/success';
  static const String donorLiveTrackingRoute = '/donor/tracking';

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

      case requesterRequestRoute:
        return MaterialPageRoute(builder: (_) => const RequesterRequestScreen());

      case requestFormRoute:
        return MaterialPageRoute(builder: (_) => const RequestFormScreen());

      case requestStatusRoute:
        return MaterialPageRoute(builder: (_) => const RequestStatusScreen());

      case liveTrackingRoute:
      case requesterPantauRoute:
        final requestId = settings.arguments as String? ?? '1';
        return MaterialPageRoute(
          builder: (_) => RequesterTrackingScreen(requestId: requestId),
        );

      case requesterProfileRoute:
        return MaterialPageRoute(builder: (_) => const RequesterProfileScreen());

      case donorDashboardRoute:
        return MaterialPageRoute(builder: (_) => const DonorDashboardScreen());

      case donorDispatchRoute:
        final dispatch = settings.arguments as DispatchTicketModel?;
        return MaterialPageRoute(
          builder: (_) => DonorDispatchScreen(initialDispatch: dispatch),
        );

      case donorNotificationRoute:
        final request = settings.arguments as BloodRequestModel?;
        return MaterialPageRoute(
          builder: (_) => NotificationScreen(initialRequest: request),
        );

      case respondRequestRoute:
        final request = settings.arguments as BloodRequestModel;
        return MaterialPageRoute(
          builder: (_) => RespondRequestScreen(request: request),
        );

      case donationHistoryRoute:
        return MaterialPageRoute(builder: (_) => const DonationHistoryScreen());

      case donationSuccessRoute:
        return MaterialPageRoute(builder: (_) => const DonationSuccessScreen());

      case donorLiveTrackingRoute:
        final requestId = settings.arguments as String? ?? '1';
        return MaterialPageRoute(
          builder: (_) => DonorLiveTrackingScreen(requestId: requestId),
        );

      case adminDashboardRoute:
        return MaterialPageRoute(builder: (_) => const AdminShellScreen());

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
        Navigator.pushReplacementNamed(context, requesterRequestRoute);
        break;
      case 'donor':
      default:
        Navigator.pushReplacementNamed(context, donorDashboardRoute);
        break;
    }
  }
}
