import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/cloud_saved_words_service.dart';
import 'package:kavaid/l10n/l10n.dart';

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
  bool _isSendingReset = false;
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
      padding: EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
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
                      ? (l10n.girisYap)
                      : (l10n.kayitOl),
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
                      ? (l10n.kayitOl)
                      : (l10n.girisYap)),
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
                      color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.3)),
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
                  l10n.hesabinizYoksaOnceKayitOlun,
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
                    l10n.kayitTamamlandiktanSonraGirisYapmaniz,
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
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
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
                decoration: InputDecoration(labelText: l10n.ePosta),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? (l10n.gecersizEPostaAdresi) : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('pass_field'),
                controller: _passController,
                focusNode: _passFocus,
                decoration: InputDecoration(labelText: l10n.sifre),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? (l10n.sifreGerekli) : null,
              ),
              if (_isLogin)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    key: const Key('forgot_password'),
                    onPressed: (_isLoading || _isSendingReset) ? null : _sendPasswordReset,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      minimumSize: const Size(0, 36),
                    ),
                    child: _isSendingReset
                        ? const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.sifremiUnuttum, style: TextStyle(fontSize: 13)),
                  ),
                )
              else
                const SizedBox(height: 8),
              
              if (!_isLogin)
                TextFormField(
                  key: const Key('confirm_pass_field'),
                  controller: _confirmPassController,
                  focusNode: _confirmFocus,
                  decoration: InputDecoration(labelText: l10n.sifreTekrar),
                  obscureText: true,
                  validator: (v) {
                    if (_isLogin) return null;
                    if (v == null || v.isEmpty) return (l10n.sifreTekrariGerekli);
                    if (v != _passController.text) return (l10n.sifrelerEslesmiyor);
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
                          ? (l10n.girisYap)
                          : (l10n.kayitOl)),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.iptal,
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

  /// "Şifremi unuttum": yazılı e-postaya sıfırlama bağlantısı gönderir.
  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() {
        _successText = null;
        _errorText = l10n.sifreniSifirlamakIcinOnceE;
      });
      _emailFocus.requestFocus();
      return;
    }

    setState(() {
      _isSendingReset = true;
      _errorText = null;
      _successText = null;
    });
    try {
      await _authService.sendPasswordReset(email);
      if (!mounted) return;
      // Firebase güvenlik gereği hesabın var olup olmadığını söylemez;
      // mesaj da bunu ima etmemeli.
      setState(() {
        _successText =
            l10n.emailAdresineKayitliBirHesap(email);
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-email' => l10n.gecerliBirEPostaAdresi,
        'user-not-found' => l10n.buEPostaIleKayit,
        'too-many-requests' =>
          l10n.cokFazlaDenemeYapildiBir,
        'network-request-failed' =>
          l10n.agHatasiInternetBaglantiniziKontrol,
        _ => l10n.baglantiGonderilemediLutfenTekrarDeneyin,
      };
      setState(() => _errorText = message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorText = l10n.baglantiGonderilemediLutfenTekrarDeneyin,
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingReset = false);
    }
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
            final messenger = ScaffoldMessenger.of(context);
            FocusManager.instance.primaryFocus?.unfocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            Navigator.pop(context); // Sheet'i kapat
            await _cloudSavedWords.mergeSync();
            widget.onSuccess?.call();
            messenger.showSnackBar(
              SnackBar(
                content: Text(l10n.hosGeldinizHesabinizBasariylaOlusturuldu),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }
    } catch (e) {
      String message = l10n.islemBasarisizLutfenTekrarDeneyin;
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            message = l10n.gecerliBirEPostaAdresi; break;
          case 'invalid-credential':
            message = l10n.ePostaVeyaSifreHatali; break;
          case 'user-not-found':
            message = l10n.buEPostaIleKayit; break;
          case 'wrong-password':
            message = l10n.sifreHatali; break;
          case 'email-already-in-use':
            message = l10n.buEPostaZatenKayitli; break;
          case 'weak-password':
            message = l10n.sifreCokZayifDahaGuclu; break;
          case 'operation-not-allowed':
             message = l10n.buGirisYontemiProjeIcin; break;
          case 'network-request-failed':
             message = l10n.agHatasiInternetBaglantiniziKontrol; break;
          case 'too-many-requests':
             message = l10n.cokFazlaDenemeYapildiBir; break;
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
