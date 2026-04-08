import 'package:flutter/material.dart';

import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inviteNameController = TextEditingController();
  final TextEditingController _inviteEmailController = TextEditingController();

  bool _loading = false;
  bool _sendingInvite = false;
  String? _errorMessage;
  String _inviteRole = 'customer';
  List<Map<String, dynamic>> _profiles = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inviteNameController.dispose();
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final rows = await SupabaseService.getProfiles();
      rows.sort((a, b) {
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
      if (!mounted) return;
      setState(() {
        _profiles = rows;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(
          error,
          fallback: 'Could not load user accounts right now.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _sendInvite() async {
    final name = _inviteNameController.text.trim();
    final email = _inviteEmailController.text.trim().toLowerCase();
    if (name.isEmpty || email.isEmpty) {
      _showSnack('Enter name and email to create an account invite.', isError: true);
      return;
    }

    setState(() {
      _sendingInvite = true;
    });
    try {
      await SupabaseService.requestEmailOtp(
        email: email,
        userName: name,
        role: _inviteRole,
      );
      if (!mounted) return;
      _inviteNameController.clear();
      _inviteEmailController.clear();
      _showSnack('Invite sent. The user can finish sign-in from OTP/email verification.');
    } catch (error) {
      _showSnack(
        _friendlyError(
          error,
          fallback: 'Could not send account invite right now.',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _sendingInvite = false;
        });
      }
    }
  }

  Future<void> _updateRole(Map<String, dynamic> profile, String role) async {
    final profileId = (profile['id'] ?? '').toString();
    if (profileId.isEmpty) return;

    try {
      final updated = await SupabaseService.updateProfileRole(
        profileId: profileId,
        role: role,
      );
      final savedRole = (updated['role'] ?? '').toString();
      if (savedRole != role) {
        throw StateError('Backend did not confirm the role update.');
      }
      if (!mounted) return;
      setState(() {
        final index = _profiles.indexWhere(
          (entry) => (entry['id'] ?? '').toString() == profileId,
        );
        if (index >= 0) {
          _profiles[index] = {
            ..._profiles[index],
            'role': role,
          };
        }
      });
      _showSnack('Role updated successfully in database.');
    } catch (error) {
      _showSnack(
        _friendlyError(
          error,
          fallback: 'Could not update role in database right now.',
        ),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _profiles.where((profile) {
      if (query.isEmpty) return true;
      final name = (profile['name'] ?? '').toString().toLowerCase();
      final email = (profile['email'] ?? '').toString().toLowerCase();
      final phone = (profile['phone'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadProfiles,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfiles,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _inviteCard(),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDEBE8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppTheme.primaryRed),
                ),
              ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No matching profiles found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMedium),
                ),
              )
            else
              ...filtered.map(_profileCard),
          ],
        ),
      ),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create user account invite',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Send OTP/email sign-in invite with a preset role. The user completes verification on their device.',
            style: TextStyle(color: AppTheme.textMedium, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _inviteNameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _inviteEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline_rounded),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _inviteRole,
            decoration: const InputDecoration(
              labelText: 'Role',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'customer', child: Text('Customer')),
              DropdownMenuItem(value: 'store_owner', child: Text('Store Owner')),
              DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _inviteRole = value;
              });
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendingInvite ? null : _sendInvite,
              icon: _sendingInvite
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_sendingInvite ? 'Sending invite...' : 'Create invite'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(Map<String, dynamic> profile) {
    final name = (profile['name'] ?? 'Unknown user').toString();
    final email = (profile['email'] ?? 'No email').toString();
    final phone = (profile['phone'] ?? '').toString();
    final role = (profile['role'] ?? 'customer').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            Text(email, style: const TextStyle(color: AppTheme.textMedium)),
            if (phone.isNotEmpty)
              Text(phone, style: const TextStyle(color: AppTheme.textMedium)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: role,
              decoration: const InputDecoration(
                labelText: 'Role',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'customer', child: Text('Customer')),
                DropdownMenuItem(value: 'store_owner', child: Text('Store Owner')),
                DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
              ],
              onChanged: (value) {
                if (value == null || value == role) return;
                _updateRole(profile, value);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.primaryRed : AppTheme.success,
      ),
    );
  }

  String _friendlyError(Object error, {required String fallback}) {
    final text = error.toString();
    if (text.trim().isEmpty) return fallback;
    return '$fallback ($text)';
  }
}
