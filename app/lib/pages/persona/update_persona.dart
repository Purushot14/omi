import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omi_private/backend/schema/app.dart';
import 'package:omi_private/main.dart';
import 'package:omi_private/pages/persona/persona_provider.dart';
import 'package:omi_private/pages/persona/twitter/social_profile.dart';
import 'package:omi_private/utils/other/debouncer.dart';
import 'package:omi_private/utils/other/temp.dart';
import 'package:omi_private/utils/text_formatter.dart';
import 'package:omi_private/widgets/animated_loading_button.dart';
import 'package:provider/provider.dart';

class UpdatePersonaPage extends StatefulWidget {
  final App? app;
  final bool fromNewFlow;
  const UpdatePersonaPage({super.key, this.app, required this.fromNewFlow});

  @override
  State<UpdatePersonaPage> createState() => _UpdatePersonaPageState();
}

class _UpdatePersonaPageState extends State<UpdatePersonaPage> {
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 500));

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.app == null) {
        await context.read<PersonaProvider>().getUserPersona();
        var app = context.read<PersonaProvider>().userPersona;
        context.read<PersonaProvider>().prepareUpdatePersona(app!);
      } else {
        context.read<PersonaProvider>().prepareUpdatePersona(widget.app!);
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PersonaProvider>(builder: (context, provider, child) {
      return PopScope(
        onPopInvoked: (didPop) {
          if (didPop) {
            context.read<PersonaProvider>().resetForm();
            if (widget.fromNewFlow) {
              Future.delayed(Duration.zero, () {
                routeToPage(context, DeciderWidget(), replace: true);
              });
            } else {
              Future.delayed(Duration.zero, () {
                Navigator.pop(context);
              });
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Update Persona', style: TextStyle(color: Colors.white)),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: provider.formKey,
                onChanged: () {
                  provider.validateForm();
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          await provider.pickImage();
                        },
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(color: Colors.grey.shade800),
                          ),
                          // child: provider.selectedImage != null
                          //     ? ClipRRect(
                          //         borderRadius: BorderRadius.circular(60),
                          //         child: Image.file(
                          //           provider.selectedImage!,
                          //           fit: BoxFit.cover,
                          //         ),
                          //       )
                          //     : Icon(
                          //         Icons.add_a_photo,
                          //         size: 40,
                          //         color: Colors.grey.shade400,
                          //       ),
                          child: provider.selectedImage != null || provider.selectedImageUrl != null
                              ? (provider.selectedImageUrl == null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.file(provider.selectedImage!, fit: BoxFit.cover))
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: CachedNetworkImage(imageUrl: provider.selectedImageUrl!),
                                    ))
                              : const Icon(Icons.add_a_photo, color: Colors.grey, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      padding: const EdgeInsets.all(14.0),
                      margin: const EdgeInsets.only(top: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Persona Name',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            margin: const EdgeInsets.only(left: 2.0, right: 2.0, top: 10, bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            width: double.infinity,
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username to access the persona';
                                }
                                return null;
                              },
                              controller: provider.nameController,
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Nik AI',
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Persona Username',
                              style: TextStyle(color: Colors.grey.shade300, fontSize: 16),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            margin: const EdgeInsets.only(left: 2.0, right: 2.0, top: 10, bottom: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            width: double.infinity,
                            child: TextFormField(
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username to access the persona';
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _debouncer.run(() async {
                                  await provider.checkIsUsernameTaken(value);
                                });
                              },
                              controller: provider.usernameController,
                              inputFormatters: [
                                LowerCaseTextFormatter(),
                                FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                              ],
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'nikshevchenko',
                                suffix: provider.usernameController.text.isEmpty
                                    ? null
                                    : provider.isCheckingUsername
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                                              ),
                                            ),
                                          )
                                        : Icon(
                                            provider.isUsernameTaken ? Icons.close : Icons.check,
                                            color: provider.isUsernameTaken ? Colors.red : Colors.green,
                                            size: 16,
                                          ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Row(
                        children: [
                          Text(
                            'Make Persona Public',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          const Spacer(),
                          Switch(
                            value: provider.makePersonaPublic,
                            onChanged: (value) {
                              provider.setPersonaPublic(value);
                            },
                            activeColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, bottom: 12),
                            child: Text(
                              'Connected Knowledge Data',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  'assets/images/x_logo_mini.png',
                                  width: 24,
                                  height: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  widget.app!.twitter != null
                                      ? (widget.app!.twitter!['username'] == null
                                          ? 'Connect Twitter'
                                          : widget.app!.twitter?['username'] ?? '')
                                      : 'Connect Twitter',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const Spacer(),
                                if (provider.twitterProfile.isEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      if (widget.app!.connectedAccounts.contains('twitter')) {
                                      } else {
                                        routeToPage(context, const SocialHandleScreen());
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[800],
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        widget.app!.connectedAccounts.contains('twitter') ? 'Connected' : 'Connect',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Connected',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 52),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedLoadingButton(
                onPressed: !provider.isFormValid
                    ? () async {}
                    : () async {
                        await provider.updatePersona();
                      },
                color: provider.isFormValid ? Colors.white : Colors.grey[800]!,
                loaderColor: Colors.black,
                text: "Update Persona",
                textStyle: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
