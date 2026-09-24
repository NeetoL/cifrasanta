import 'package:flutter/material.dart';
import '../../core/library_store.dart';
import '../identity.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.library});
  final LibraryStore library;
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final result = await widget.library.signIn(
      email.text.trim(),
      password.text,
      name: register ? name.text.trim() : null,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      error = result;
    });
    if (result == null) password.clear();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.library,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Minha conta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.library.signedIn) ...[
                Text(
                  'Olá, ${widget.library.userName}',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Seus favoritos e suas listas ficam salvos na sua conta.',
                ),
                if (widget.library.canReadBible) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 18,
                        color: SaintColors.gold,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Leitura da Bíblia liberada.',
                        style: TextStyle(color: SaintColors.gold),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          setState(() => busy = true);
                          final result = await widget.library.signOut();
                          if (mounted) {
                            setState(() {
                              busy = false;
                              error = result;
                            });
                          }
                        },
                  child: const Text('Sair da conta'),
                ),
              ] else
                Form(
                  key: form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        register
                            ? 'Crie sua conta'
                            : 'Entre para salvar suas listas',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (register)
                        TextFormField(
                          controller: name,
                          enabled: !busy,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Seu nome',
                            counterText: '',
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Informe seu nome.'
                              : null,
                        ),
                      TextFormField(
                        controller: email,
                        enabled: !busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        maxLength: 190,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          counterText: '',
                        ),
                        validator: (v) => v == null || !v.contains('@')
                            ? 'Informe um e-mail válido.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: password,
                        enabled: !busy,
                        obscureText: true,
                        maxLength: 72,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          helperText: register
                              ? 'Pelo menos 10 caracteres'
                              : null,
                          counterText: '',
                        ),
                        validator: (v) => v == null || v.isEmpty
                            ? 'Informe sua senha.'
                            : register && v.length < 10
                            ? 'Use pelo menos 10 caracteres.'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: busy ? null : submit,
                        child: Text(
                          busy
                              ? 'Aguarde...'
                              : register
                              ? 'Criar conta'
                              : 'Entrar',
                        ),
                      ),
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                register = !register;
                                error = null;
                              }),
                        child: Text(
                          register ? 'Já tenho conta' : 'Criar uma conta',
                        ),
                      ),
                      Text(
                        'Você pode consultar as cifras sem criar uma conta.',
                        style: TextStyle(color: SaintColors.muted),
                      ),
                    ],
                  ),
                ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error!,
                    style: TextStyle(color: SaintColors.gold),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
