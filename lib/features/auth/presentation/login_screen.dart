import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class _BusinessOption {
  final String id;
  final String name;
  const _BusinessOption(this.id, this.name);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { auth, pickBusiness, createBusiness }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  _Step _step = _Step.auth;
  List<_BusinessOption> _availableBusinesses = [];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = _isSignUp
          ? await client.auth.signUp(email: email, password: password)
          : await client.auth.signInWithPassword(email: email, password: password);

      if (response.user == null) {
        setState(() => _errorMessage = _isSignUp
            ? 'Check your email to confirm your account, then sign in.'
            : 'Sign in failed.');
        return;
      }

      await _loadBusinessesForCurrentUser();
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'An unexpected error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBusinessesForCurrentUser() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final rows = await client.from('business_members').select('business_id, businesses(name)').eq('user_id', userId);

    final options = (rows as List)
        .map((r) => _BusinessOption(r['business_id'] as String, (r['businesses']?['name'] as String?) ?? 'Unnamed business'))
        .toList();

    if (!mounted) return;

    if (options.isEmpty) {
      setState(() => _step = _Step.createBusiness);
    } else if (options.length == 1) {
      await _selectBusiness(options.first.id);
    } else {
      setState(() {
        _availableBusinesses = options;
        _step = _Step.pickBusiness;
      });
    }
  }

  Future<void> _createBusiness() async {
    if (_businessNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a business name');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final id = const Uuid().v4();
      await client.from('businesses').insert({
        'id': id,
        'name': _businessNameController.text.trim(),
        'address': _businessAddressController.text.trim(),
        'phone': _businessPhoneController.text.trim(),
      });
      // The on_business_created trigger adds this user as OWNER automatically.
      await _selectBusiness(id);
    } catch (e) {
      setState(() => _errorMessage = 'Could not create business: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBusiness(String businessId) async {
    final device = ref.read(deviceIdentityProvider);
    final client = Supabase.instance.client;

    try {
      await client.from('devices').upsert({
        'id': device.id,
        'business_id': businessId,
        'device_name': device.deviceName,
        'platform': device.platformName,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Device registration is best-effort -- don't block login on it.
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString('business_id', businessId);
    ref.read(currentBusinessIdProvider.notifier).state = businessId;

    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KhaoPiyo POS')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildStep(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.auth:
        return _buildAuthStep();
      case _Step.pickBusiness:
        return _buildPickBusinessStep();
      case _Step.createBusiness:
        return _buildCreateBusinessStep();
    }
  }

  Widget _buildAuthStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _isSignUp ? 'Create your account' : 'Sign in',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) _ErrorBanner(_errorMessage!),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
          keyboardType: TextInputType.emailAddress,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
          obscureText: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _submitAuth,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _isSignUp = !_isSignUp),
          child: Text(_isSignUp ? 'Already have an account? Sign in' : "New here? Create an account"),
        ),
      ],
    );
  }

  Widget _buildPickBusinessStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Select a business', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ..._availableBusinesses.map((b) => Card(
              child: ListTile(
                title: Text(b.name),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectBusiness(b.id),
              ),
            )),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _step = _Step.createBusiness),
          icon: const Icon(Icons.add),
          label: const Text('Create a new business'),
        ),
      ],
    );
  }

  Widget _buildCreateBusinessStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Set up your business', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        if (_errorMessage != null) _ErrorBanner(_errorMessage!),
        TextField(
          controller: _businessNameController,
          decoration: const InputDecoration(labelText: 'Business name', border: OutlineInputBorder()),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _businessAddressController,
          decoration: const InputDecoration(labelText: 'Address (optional)', border: OutlineInputBorder()),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _businessPhoneController,
          decoration: const InputDecoration(labelText: 'Phone (optional)', border: OutlineInputBorder()),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _createBusiness,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Create & Continue'),
        ),
        if (_availableBusinesses.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _step = _Step.pickBusiness),
            child: const Text('Back to business list'),
          ),
        ],
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
    );
  }
}
