// ignore_for_file: use_build_context_synchronously, deprecated_member_use, use_super_parameters

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/authentication/auth_services/auth_service.dart';
import 'package:atomic_notes/utility/component/my_appbar.dart';
import 'package:atomic_notes/utility/component/my_snackbar.dart';
import 'package:atomic_notes/utility/component/my_textfield.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;
  late String? userId = supabase.auth.currentUser!.email;
  final _usernameController = TextEditingController();
  final AuthServices serve = AuthServices();
  String? username = "@Loading..";
  bool _mounted = true;
  bool _isSwitch = false;

  @override
  void initState() {
    _getUserName();
    super.initState();
  }

  // get the user name
  Future<void> _getUserName() async {
    if (!_mounted) return;

    try {
      final name = await serve.getUserInfo();
      if (!_mounted) return;
      setState(() {
        username = name;
      });
    } catch (e) {
      if (!_mounted) return;
      setState(() {
        username = "@Error";
      });
    }
  }

  Future<void> _sendData() async {
    if (!_mounted) return;

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      const MySnackBar(
        text: "No Internet Connection!",
        sec: 2000,
      ).showMySnackBar(context);
    } else {
      if (isFilled()) {
        try {
          final response = await serve.updateUserInfo(
              username: _usernameController.text.trim().toLowerCase());
          MySnackBar(
            text: response.toString(),
            sec: 1000,
          ).showMySnackBar(context);
          await _getUserName();
        } catch (e) {
          const MySnackBar(
            text: "Error occurred while updating user info",
            sec: 2000,
          ).showMySnackBar(context);
        }
      } else {
        const MySnackBar(
          text: "Please enter your username",
          sec: 2000,
        ).showMySnackBar(context);
      }
    }
    if (!_mounted) return;
    setState(() {
      _isSwitch = false;
    });
  }

  bool isFilled() {
    return _usernameController.text.trim().isNotEmpty;
  }

  void _toggleSwitch() {
    if (!_mounted) return;
    setState(() {
      _isSwitch = !_isSwitch;
    });
  }

  @override
  void dispose() {
    _mounted = false;
    _isSwitch = false;
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: const MyAppBar(text: "Profile"),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 15),
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          "assets/photo.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 35,
                              width: 35,
                              child: Image.asset("assets/logo_x.png"),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Username",
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                  // The ConstrainedBox is hoisted above the ternary on purpose,
                  // and there is deliberately no `Flexible` wrapping it:
                  //
                  //  * `Flexible` is a ParentDataWidget and must be a *direct*
                  //    child of the Row. It used to sit inside this Padding,
                  //    which threw "Incorrect use of ParentDataWidget" in debug
                  //    and a TypeError in release the moment _isSwitch flipped.
                  //  * A Row lays out its non-flex children with an unbounded
                  //    main axis, so the inner Row below would otherwise get
                  //    maxWidth: infinity — and a `Flexible` inside an
                  //    unbounded Row is itself an error. Capping the width here
                  //    makes that inner `Flexible` (and its ellipsis) valid.
                  Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: (MediaQuery.sizeOf(context).width - 120)
                            .clamp(120.0, 250.0),
                      ),
                      child: _isSwitch
                          ? SizedBox(
                              height: 50,
                              child: MyTextField(
                                  ico: const Icon(Icons.person),
                                  hintText: "Enter username",
                                  controller: _usernameController),
                            )
                          : GestureDetector(
                              onTap: _toggleSwitch,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      username!.substring(1),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: AppColors.ink),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  SvgPicture.asset(
                                    'assets/forward_arrow.svg',
                                    colorFilter: const ColorFilter.mode(
                                        AppColors.ink, BlendMode.srcIn),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
            const Divider(
              height: 35,
              indent: 20,
              endIndent: 20,
              color: AppColors.outlineVariant,
            ),
            SizedBox(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      "Email",
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      userId!,
                      style: const TextStyle(color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 35,
              indent: 20,
              endIndent: 20,
              color: AppColors.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.screenMargin, vertical: AppSpace.sm),
              child: InkActionButton(
                label: 'Save changes',
                onTap: _sendData,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
