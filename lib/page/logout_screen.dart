import 'package:flutter/material.dart';

/// The brief screen shown between sign-out and the login screen.
///
/// [SessionGuard] resets the whole navigation stack here on any sign-out.
/// Resetting straight to the login route from an auth-stream callback could
/// land while the navigator was still closing the logout confirmation dialog,
/// leaving a blank (black) navigator that only an app restart cleared. Landing
/// on this always-opaque screen first removes that race, and it gives the
/// sign-out a branded beat instead of a bare flash. Once its first frame is on
/// screen — so the navigator is idle again — it forwards to the login screen on
/// its own, so there is nothing for the user to restart.
class LoggedOutScreen extends StatefulWidget {
  const LoggedOutScreen({super.key});

  @override
  State<LoggedOutScreen> createState() => _LoggedOutScreenState();
}

class _LoggedOutScreenState extends State<LoggedOutScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _toLogin());
  }

  Future<void> _toLogin() async {
    // A short branded beat, then hand off to login. The navigator is idle by
    // now (this screen has painted), so replacing the stack is safe here.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/loginpage', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Deliberately pure black with the atom mark centred at half opacity: the
    // asset is already light-on-transparent, so it reads as a soft glow here.
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Opacity(
          opacity: 0.5,
          child: SizedBox(
            width: 120,
            height: 120,
            child: Image(
              image: AssetImage('assets/logo_x.png'),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
