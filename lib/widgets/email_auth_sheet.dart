import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class EmailAuthSheet {
  static void show(BuildContext context, {
    bool initialIsLogin = true,
    String? message,
    VoidCallback? onSuccess,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final confirmPassController = TextEditingController();
    final emailFocus = FocusNode();
    final passFocus = FocusNode();
    final confirmFocus = FocusNode();
    final AuthService authService = AuthService();
    
    bool isLogin = initialIsLogin;
    bool isLoading = false;
    String? errorText;
    String? successText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final viewInsets = MediaQuery.of(context).viewInsets;
            final keyboardHeight = viewInsets.bottom;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: keyboardHeight + 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setSheetState(() => isLogin = !isLogin),
                            child: Text(isLogin ? 'Kayıt Ol' : 'Giriş Yap'),
                          )
                        ],
                      ),
                      if (message != null && errorText == null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.orange[300] : Colors.orange[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (isLogin && message == null) ...[
                        Text(
                          'Hesabınız yoksa önce kayıt olun',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (successText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Text(
                            successText!,
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (errorText != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withOpacity(0.3)),
                          ),
                          child: Text(
                            errorText!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: emailController,
                        focusNode: emailFocus,
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          hintText: 'ornek@email.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Geçersiz e-posta adresi' : null,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passController,
                        focusNode: passFocus,
                        decoration: const InputDecoration(
                          labelText: 'Şifre',
                        ),
                        obscureText: true,
                        validator: (v) => (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                      ),
                      const SizedBox(height: 8),
                      if (!isLogin)
                        TextFormField(
                          controller: confirmPassController,
                          focusNode: confirmFocus,
                          decoration: const InputDecoration(
                            labelText: 'Şifre Tekrar',
                          ),
                          obscureText: true,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Şifre tekrarı gerekli';
                            if (v != passController.text) return 'Şifreler eşleşmiyor';
                            return null;
                          },
                        ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            try {
                              setSheetState(() {
                                errorText = null;
                                successText = null;
                                isLoading = true;
                              });
                              if (isLogin) {
                                final user = await authService.signInWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                  if (user != null) {
                                    Navigator.pop(ctx);
                                    if (onSuccess != null) onSuccess();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Başarıyla giriş yapıldı!')),
                                    );
                                  }
                              } else {
                                final user = await authService.signUpWithEmail(
                                  email: emailController.text.trim(),
                                  password: passController.text,
                                );
                                if (user != null) {
                                  if (onSuccess != null) onSuccess();
                                  setSheetState(() {
                                    successText = 'Kayıt tamamlandı. Lütfen giriş yapın.';
                                    isLogin = true;
                                    emailController.clear();
                                    passController.clear();
                                    confirmPassController.clear();
                                  });
                                  Future.delayed(const Duration(milliseconds: 50), () {
                                    emailFocus.requestFocus();
                                  });
                                }
                              }
                            } catch (e) {
                              String errMessage = 'İşlem başarısız.';
                              if (e is FirebaseAuthException) {
                                switch (e.code) {
                                  case 'invalid-credential': errMessage = 'E-posta veya şifre hatalı.'; break;
                                  case 'email-already-in-use': errMessage = 'Bu e-posta zaten kullanımda.'; break;
                                  case 'weak-password': errMessage = 'Şifre çok zayıf.'; break;
                                  default: errMessage = e.message ?? e.code;
                                }
                              } else {
                                errMessage = e.toString();
                              }
                              setSheetState(() { errorText = errMessage; });
                            } finally {
                              setSheetState(() { isLoading = false; });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
