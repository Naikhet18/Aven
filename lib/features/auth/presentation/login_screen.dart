import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:khao_piyo_pos/core/utils/join_code.dart';
import 'package:khao_piyo_pos/features/auth/presentation/scan_join_code_screen.dart';
import 'package:khao_piyo_pos/features/auth/providers/staff_role_provider.dart';
import 'package:khao_piyo_pos/shared/models/restaurant_table.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

class _BusinessOption {
  final String id;
  final String name;
  final String role;
  const _BusinessOption(this.id, this.name, this.role);
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

enum _Step { landing, auth, pickBusiness, createBusiness, joinCode }

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _deviceLabelController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;
  _Step _step = _Step.landing;
  List<_BusinessOption> _availableBusinesses = [];
  String _joinRole = 'STAFF'; // STAFF (Waiter) or MANAGER (Cashier)

  static const _defaultTableNames = ['1', '2', '3', '4', '5', '6', '7', '8'];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _codeController.dispose();
    _deviceLabelController.dispose();
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

    final rows = await client.from('business_members').select('business_id, role, businesses(name)').eq('user_id', userId);

    final options = (rows as List)
        .map((r) => _BusinessOption(
              r['business_id'] as String,
              (r['businesses']?['name'] as String?) ?? 'Unnamed business',
              r['role'] as String? ?? 'OWNER',
            ))
        .toList();

    if (!mounted) return;

    if (options.isEmpty) {
      setState(() => _step = _Step.createBusiness);
    } else if (options.length == 1) {
      await _selectBusiness(options.first.id, options.first.role);
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

      // Retry on the astronomically rare join_code collision.
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          await client.from('businesses').insert({
            'id': id,
            'name': _businessNameController.text.trim(),
            'address': _businessAddressController.text.trim(),
            'phone': _businessPhoneController.text.trim(),
            'join_code': JoinCode.generate(),
          });
          break;
        } on PostgrestException catch (e) {
          if (e.code == '23505' && attempt < 4) continue;
          rethrow;
        }
      }
      // The on_business_created trigger adds this user as OWNER automatically.

      final tableRepo = ref.read(tableRepositoryProvider);
      final now = DateTime.now();
      for (final name in _defaultTableNames) {
        await tableRepo.addTable(RestaurantTable(id: const Uuid().v4(), businessId: id, name: name, createdAt: now, updatedAt: now));
      }

      await _selectBusiness(id, 'OWNER');
    } catch (e) {
      setState(() => _errorMessage = 'Could not create business: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBusiness(String businessId, String role) async {
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
    await prefs.setString('staff_role', role);
    ref.read(currentStaffRoleProvider.notifier).state = role;
    ref.read(currentBusinessIdProvider.notifier).state = businessId;

    if (mounted) context.go('/');
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Enter or scan a restaurant code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) {
        await client.auth.signInAnonymously();
      }

      final device = ref.read(deviceIdentityProvider);
      final label = _deviceLabelController.text.trim();

      final businessId = await client.rpc('join_business_with_code', params: {
        'p_code': code,
        'p_role': _joinRole,
        'p_device_id': device.id,
        'p_device_name': label.isEmpty ? device.deviceName : label,
        'p_platform': device.platformName,
      }) as String;

      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString('business_id', businessId);
      await prefs.setString('staff_role', _joinRole);
      ref.read(currentStaffRoleProvider.notifier).state = _joinRole;
      ref.read(currentBusinessIdProvider.notifier).state = businessId;

      if (mounted) context.go('/');
    } on PostgrestException catch (e) {
      setState(() => _errorMessage = e.message.toLowerCase().contains('invalid restaurant code') ? 'That code doesn\'t match any restaurant.' : e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Could not join: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _scanQr() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ScanJoinCodeScreen()),
    );
    if (code != null && mounted) {
      setState(() => _codeController.text = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _step == _Step.landing ? null : AppBar(
        title: const Text('KhaoPiyo POS'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => setState(() {
            _errorMessage = null;
            _step = _Step.landing;
          }),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: _step == _Step.landing
                ? Padding(padding: const EdgeInsets.all(24), child: _buildLandingStep())
                : Card(
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
      case _Step.landing:
        return _buildLandingStep();
      case _Step.auth:
        return _buildAuthStep();
      case _Step.pickBusiness:
        return _buildPickBusinessStep();
      case _Step.createBusiness:
        return _buildCreateBusinessStep();
      case _Step.joinCode:
        return _buildJoinCodeStep();
    }
  }

  Widget _buildLandingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Icon(Icons.storefront_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(
          'KhaoPiyo POS',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Run your restaurant, simply.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: () => setState(() => _step = _Step.auth),
          icon: const Icon(Icons.person_outline),
          label: const Text('I\'m the Owner'),
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(18)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = _Step.joinCode),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Join with a Restaurant Code'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
        ),
        const SizedBox(height: 16),
        Text(
          'Staff can join instantly with the code shown on the owner\'s device -- no password needed.',
          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
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

  Widget _buildJoinCodeStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Join a restaurant', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Ask the owner for the restaurant code, or scan their QR.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_errorMessage != null) _ErrorBanner(_errorMessage!),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Restaurant code', border: OutlineInputBorder()),
                enabled: !_isLoading,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isLoading ? null : _scanQr,
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan QR',
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _deviceLabelController,
          decoration: const InputDecoration(labelText: 'Your name (optional)', border: OutlineInputBorder()),
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        const Align(alignment: Alignment.centerLeft, child: Text('Your role')),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'STAFF', label: Text('Waiter')),
            ButtonSegment(value: 'MANAGER', label: Text('Cashier / Manager')),
          ],
          selected: {_joinRole},
          onSelectionChanged: _isLoading ? null : (set) => setState(() => _joinRole = set.first),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _isLoading ? null : _joinWithCode,
          style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          child: _isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Join'),
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
                subtitle: Text(b.role),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectBusiness(b.id, b.role),
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
