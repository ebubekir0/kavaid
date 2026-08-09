import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/cloud_saved_words_service.dart';
import '../services/language_service.dart';

class EmailAuthSheet extends StatefulWidget {
  final bool initialIsLogin;
  final VoidCallback? onSuccess;
  final String? message;

  const EmailAuthSheet({
    super.key,
    this.initialIsLogin = true,
    this.onSuccess,
    this.message,
  });

  static void show(BuildContext context, {bool initialIsLogin = true, VoidCallback? onSuccess, String? message}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true, // Alt barın üzerinde açılması için
      backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => EmailAuthSheet(initialIsLogin: initialIsLogin, onSuccess: onSuccess, message: message),
    );
  }

  @override
  State<EmailAuthSheet> createState() => _EmailAuthSheetState();
}

class _EmailAuthSheetState extends State<EmailAuthSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  
  // Servisler
  final AuthService _authService = AuthService();
  final CloudSavedWordsService _cloudSavedWords = CloudSavedWordsService();

  late bool _isLogin;
  bool _isLoading = false;
  String? _errorText;
  String? _successText;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialIsLogin;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _isLogin 
                      ? (LanguageService().isEnglish ? 'Log In' : (LanguageService().isArabic ? 'تسجيل الدخول' : 'Giriş Yap'))
                      : (LanguageService().isEnglish ? 'Sign Up' : (LanguageService().isArabic ? 'إنشاء حساب' : 'Kayıt Ol')),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() {
                      _isLogin = !_isLogin;
                      _errorText = null;
                      _successText = null;
                    }),
                    child: Text(_isLogin 
                      ? (LanguageService().isEnglish ? 'Sign Up' : (LanguageService().isArabic ? 'إنشاء حساب' : 'Kayıt Ol'))
                      : (LanguageService().isEnglish ? 'Log In' : (LanguageService().isArabic ? 'تسجيل الدخول' : 'Giriş Yap'))),
                  )
                ],
              ),
              // Opsiyonel Mesaj Alanı
              if (widget.message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF2196F3), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.message!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDarkMode ? Colors.white70 : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              const SizedBox(height: 6),
              if (_isLogin) ...[
                Text(
                  LanguageService().isEnglish ? 'Sign up first if you don\'t have an account' : (LanguageService().isArabic ? 'سجل أولاً إذا لم يكن لديك حساب' : 'Hesabınız yoksa önce kayıt olun'),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF8E8E93) : const Color(0xFF6D6D70),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (!_isLogin) const SizedBox(height: 8),

               // Kayıt uyarısı (Profilde olduğu gibi)
              if (_errorText == null && !_isLogin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    LanguageService().isEnglish ? 'You need to log in after signing up.' : (LanguageService().isArabic ? 'تحتاج إلى تسجيل الدخول بعد إنشاء الحساب.' : 'Kayıt tamamlandıktan sonra giriş yapmanız gerekir.'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),

              if (_successText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Text(
                    _successText!,
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_errorText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: InputDecoration(labelText: LanguageService().isEnglish ? 'Email' : (LanguageService().isArabic ? 'البريد الإلكتروني' : 'E-posta')),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? (LanguageService().isEnglish ? 'Invalid email address' : (LanguageService().isArabic ? 'بريد إلكتروني غير صالح' : 'Geçersiz e-posta adresi')) : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('pass_field'),
                controller: _passController,
                focusNode: _passFocus,
                decoration: InputDecoration(labelText: LanguageService().isEnglish ? 'Password' : (LanguageService().isArabic ? 'كلمة المرور' : 'Şifre')),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? (LanguageService().isEnglish ? 'Password required' : (LanguageService().isArabic ? 'كلمة المرور مطلوبة' : 'Şifre gerekli')) : null,
              ),
              const SizedBox(height: 8),
              
              if (!_isLogin)
                TextFormField(
                  key: const Key('confirm_pass_field'),
                  controller: _confirmPassController,
                  focusNode: _confirmFocus,
                  decoration: InputDecoration(labelText: LanguageService().isEnglish ? 'Confirm Password' : (LanguageService().isArabic ? 'تأكيد كلمة المرور' : 'Şifre Tekrar')),
                  obscureText: true,
                  validator: (v) {
                    if (_isLogin) return null;
                    if (v == null || v.isEmpty) return (LanguageService().isEnglish ? 'Confirm password required' : (LanguageService().isArabic ? 'تأكيد كلمة المرور مطلوب' : 'Şifre tekrarı gerekli'));
                    if (v != _passController.text) return (LanguageService().isEnglish ? 'Passwords do not match' : (LanguageService().isArabic ? 'كلمات المرور غير متطابقة' : 'Şifreler eşleşmiyor'));
                    return null;
                  },
                ),
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isLogin 
                          ? (LanguageService().isEnglish ? 'Log In' : (LanguageService().isArabic ? 'تسجيل الدخول' : 'Giriş Yap'))
                          : (LanguageService().isEnglish ? 'Sign Up' : (LanguageService().isArabic ? 'إنشاء حساب' : 'Kayıt Ol'))),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    LanguageService().isEnglish 
                        ? 'Cancel' 
                        : (LanguageService().isArabic ? 'إلغاء' : 'İptal'),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _errorText = null;
      _successText = null;
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        final user = await _authService.signInWithEmail(
          email: _emailController.text.trim(),
          password: _passController.text,
        );
        if (user != null) {
          if (mounted) {
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            Navigator.pop(context); // Sheet'i kapat
            await _cloudSavedWords.mergeSync();
            widget.onSuccess?.call();
          }
          return;
        }
      } else {
        final user = await _authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passController.text,
        );
        if (user != null) {
          if (mounted) {
            setState(() {
              _successText = LanguageService().isEnglish ? 'Signed up successfully. Please log in.' : 'Kayıt tamamlandı. Lütfen giriş yapın.';
              _isLogin = true;
              _isLoading = false;
              _emailController.clear();
              _passController.clear();
              _confirmPassController.clear();
            });
            // Klavye açık kalsın ve email'e odaklansın
            Future.delayed(const Duration(milliseconds: 50), () {
              _emailFocus.requestFocus();
            });
          }
        }
      }
    } catch (e) {
      String message = LanguageService().isEnglish ? 'Transaction failed. Please try again.' : 'İşlem başarısız. Lütfen tekrar deneyin.';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            message = LanguageService().isEnglish ? 'Enter a valid email address.' : 'Geçerli bir e‑posta adresi giriniz.'; break;
          case 'invalid-credential':
            message = LanguageService().isEnglish ? 'Invalid email or password. Please check.' : 'E‑posta veya şifre hatalı. Lütfen kontrol ediniz.'; break;
          case 'user-not-found':
            message = LanguageService().isEnglish ? 'No account found with this email.' : 'Bu e‑posta ile kayıt bulunamadı.'; break;
          case 'wrong-password':
            message = LanguageService().isEnglish ? 'Incorrect password.' : 'Şifre hatalı.'; break;
          case 'email-already-in-use':
            message = LanguageService().isEnglish ? 'This email is already registered.' : 'Bu e‑posta zaten kayıtlı.'; break;
          case 'weak-password':
            message = LanguageService().isEnglish ? 'Password is too weak. Choose a stronger one.' : 'Şifre çok zayıf. Daha güçlü bir şifre seçin.'; break;
          case 'operation-not-allowed':
             message = LanguageService().isEnglish ? 'This login method is not enabled.' : 'Bu giriş yöntemi proje için etkin değil.'; break;
          case 'network-request-failed':
             message = LanguageService().isEnglish ? 'Network error. Please check your connection.' : 'Ağ hatası. İnternet bağlantınızı kontrol edin.'; break;
          case 'too-many-requests':
             message = LanguageService().isEnglish ? 'Too many attempts. Try again later.' : 'Çok fazla deneme yapıldı. Bir süre sonra tekrar deneyin.'; break;
          default:
             message = 'Hata: ${e.message ?? e.code}';
        }
      } else {
        message = e.toString();
      }
      
      if (mounted) {
        setState(() {
          _errorText = message;
          _isLoading = false;
        });
      }
    }
  }
}
