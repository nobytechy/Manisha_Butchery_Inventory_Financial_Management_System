import 'package:flutter/material.dart';
import 'package:manisha_butchery/services/shared_prefs_service.dart';
import 'dashboard.dart';
import '../widgets/bottom_modals.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());
  String _enteredPin = '';

  @override
  void initState() {
    super.initState();
    _setupFocusNodes();
  }

  void _setupFocusNodes() {
    for (int i = 0; i < 4; i++) {
      _controllers[i].addListener(() {
        if (_controllers[i].text.length == 1 && i < 3) {
          _focusNodes[i + 1].requestFocus();
        }
        _updateEnteredPin();
      });
    }
  }

  void _updateEnteredPin() {
    String pin = '';
    for (var controller in _controllers) {
      pin += controller.text;
    }
    setState(() {
      _enteredPin = pin;
    });

    if (pin.length == 4) {
      _verifyPin(pin);
    }
  }

  void _verifyPin(String pin) async {
    final savedPin = SharedPrefsService.getPin();

    if (pin == savedPin) {
      // Success
      showSuccessToast('Login successful!');
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else {
      // Failed
      showErrorToast('Invalid PIN');
      _clearFields();
      _focusNodes[0].requestFocus();
    }
  }

  void _clearFields() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _enteredPin = '';
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showChangePinModal() {
    // First show modal to verify old PIN
    _showVerifyOldPinModal();
  }

  void _showVerifyOldPinModal() {
    final List<TextEditingController> oldPinControllers =
        List.generate(4, (_) => TextEditingController());
    final List<FocusNode> oldPinFocusNodes =
        List.generate(5, (_) => FocusNode());
    String enteredOldPin = '';

    void updateOldPin() {
      String pin = '';
      for (var controller in oldPinControllers) {
        pin += controller.text;
      }
      enteredOldPin = pin;

      if (pin.length == 4) {
        final savedPin = SharedPrefsService.getPin();
        if (pin == savedPin) {
          // Old PIN verified, now show change PIN modal
          Navigator.pop(context); // Close old PIN modal
          _showChangeNewPinModal();
        } else {
          showErrorToast('Incorrect old PIN');
          for (var controller in oldPinControllers) {
            controller.clear();
          }
          oldPinFocusNodes[0].requestFocus();
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Verify Old PIN',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enter your current PIN to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      width: 45,
                      height: 45,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1E3A8A),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: TextField(
                          controller: oldPinControllers[index],
                          focusNode: oldPinFocusNodes[index],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 3) {
                              FocusScope.of(context)
                                  .requestFocus(oldPinFocusNodes[index + 1]);
                            }
                            updateOldPin();
                          },
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: enteredOldPin.length == 4
                            ? () {
                                final savedPin = SharedPrefsService.getPin();
                                if (enteredOldPin == savedPin) {
                                  Navigator.pop(context);
                                  _showChangeNewPinModal();
                                } else {
                                  showErrorToast('Incorrect old PIN');
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('VERIFY'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeNewPinModal() {
    showChangePinModal(
      context,
      onPinChanged: (newPin) {
        // This should save the new PIN
        SharedPrefsService.setPin(newPin);
        showSuccessToast('PIN changed successfully');
        // Clear the current PIN fields so user has to enter new PIN
        _clearFields();
        Navigator.pop(context); // Close the change PIN modal
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: SizedBox(
            height: screenHeight - MediaQuery.of(context).padding.top,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth > 600 ? 40.0 : 20.0,
                vertical: 8.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: isSmallScreen ? 55.0 : 70.0,
                        color: const Color(0xFF1E3A8A),
                      ),
                      SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                      const Text(
                        'Enter PIN',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16.0 : 24.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final pinBoxSize = isSmallScreen ? 48.0 : 55.0;
                          final pinMargin = screenWidth < 400 ? 6.0 : 8.0;

                          return Container(
                            width: pinBoxSize,
                            height: pinBoxSize,
                            margin: EdgeInsets.symmetric(horizontal: pinMargin),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFF1E3A8A),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18.0 : 22.0,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E3A8A),
                                ),
                                decoration: const InputDecoration(
                                  counterText: '',
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 3) {
                                    FocusScope.of(context)
                                        .requestFocus(_focusNodes[index + 1]);
                                  }
                                },
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: isSmallScreen ? 20.0 : 30.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _enteredPin.length == 4
                              ? () => _verifyPin(_enteredPin)
                              : null,
                          icon: const Icon(Icons.login, size: 20),
                          label: const Text(
                            'LOGIN',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                      TextButton(
                        onPressed: _showChangePinModal,
                        child: const Text(
                          'Change PIN',
                          style: TextStyle(
                            color: Color(0xFF1E3A8A),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Column(
                      children: [
                        Text(
                          'Powered by',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        Text(
                          'Nobytechy Systems',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
