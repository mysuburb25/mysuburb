import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../models/models.dart';

// ─────────────────────── SIGN UP ─────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final cred = await _authService.signUpWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        displayName: _nameCtrl.text.trim(),
      );
      if (mounted) {
        context.go('/select-suburb', extra: {
          'uid': cred.user!.uid,
          'email': _emailCtrl.text.trim(),
          'displayName': _nameCtrl.text.trim(),
        });
      }
    } catch (e) {
      final msg = e.toString();
      String friendly = 'Something went wrong. Please try again.';
      if (msg.contains('email-already-in-use')) {
        friendly = 'That email is already registered. Try signing in.';
      } else if (msg.contains('weak-password')) {
        friendly = 'Password is too weak. Use at least 8 characters.';
      }
      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        backgroundColor: AppTheme.sand,
        elevation: 0,
        leading: BackButton(color: AppTheme.charcoal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.charcoal,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Join your neighbourhood in seconds',
              style: TextStyle(fontSize: 15, color: AppTheme.midGrey),
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter your name' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Enter a valid email' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.length < 8 ? 'Minimum 8 characters' : null,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.terracotta.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.terracotta, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _signUp,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.white),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: 20),
            const Text(
              'By signing up, you agree to our Terms of Service and Privacy Policy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.midGrey, height: 1.5),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── SELECT SUBURB ───────────────────────────────────────

class SelectSuburbScreen extends StatefulWidget {
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEditing;

  const SelectSuburbScreen({
    super.key,
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isEditing = false,
  });

  @override
  State<SelectSuburbScreen> createState() => _SelectSuburbScreenState();
}

class _SelectSuburbScreenState extends State<SelectSuburbScreen> {
  final _searchCtrl = TextEditingController();
  final _authService = AuthService();

  String? _selectedState;
  String? _selectedSuburb;
  bool _loading = false;
  List<String> _filteredSuburbs = [];
  bool _searching = false;

  // Sample suburbs — in production, load from Firestore or a bundled JSON
  static const Map<String, List<String>> _suburbsByState = {
    'Queensland': [
      'Surfers Paradise', 'Broadbeach', 'Burleigh Heads', 'Coolangatta',
      'Palm Beach', 'Robina', 'Southport', 'Labrador', 'Runaway Bay',
      'Hope Island', 'Coomera', 'Pimpama', 'Helensvale', 'Nerang',
      'Brisbane City', 'South Brisbane', 'Fortitude Valley', 'New Farm',
      'West End', 'Paddington', 'Toowong', 'Kelvin Grove', 'Milton',
      'Woolloongabba', 'Stones Corner', 'Coorparoo', 'Camp Hill',
      'Carindale', 'Mount Gravatt', 'Eight Mile Plains', 'Sunnybank',
      'Springwood', 'Logan Central', 'Beenleigh', 'Ipswich',
      'Toowoomba', 'Rockhampton', 'Mackay', 'Cairns', 'Townsville',
      'Sunshine Coast', 'Noosa Heads', 'Maroochydore', 'Caloundra',
    ],
    'New South Wales': [
      'Sydney CBD', 'Parramatta', 'Bondi Beach', 'Manly', 'Newtown',
      'Glebe', 'Surry Hills', 'Darlinghurst', 'Paddington', 'Mosman',
      'Chatswood', 'Hornsby', 'Castle Hill', 'Penrith', 'Liverpool',
      'Campbelltown', 'Wollongong', 'Newcastle', 'Maitland', 'Gosford',
      'Coffs Harbour', 'Tamworth', 'Albury', 'Wagga Wagga', 'Orange',
      'Dubbo', 'Bathurst', 'Lismore', 'Byron Bay', 'Ballina',
    ],
    'Victoria': [
      'Melbourne CBD', 'South Yarra', 'St Kilda', 'Fitzroy', 'Brunswick',
      'Richmond', 'Collingwood', 'Northcote', 'Preston', 'Coburg',
      'Essendon', 'Moonee Ponds', 'Footscray', 'Williamstown', 'Dandenong',
      'Frankston', 'Ringwood', 'Box Hill', 'Camberwell', 'Hawthorn',
      'Geelong', 'Ballarat', 'Bendigo', 'Shepparton', 'Warrnambool',
      'Mildura', 'Wodonga', 'Sale', 'Traralgon', 'Morwell',
    ],
    'Western Australia': [
      'Perth CBD', 'Fremantle', 'Subiaco', 'Cottesloe', 'Scarborough',
      'Joondalup', 'Midland', 'Armadale', 'Rockingham', 'Mandurah',
      'Bunbury', 'Busselton', 'Broome', 'Karratha', 'Port Hedland',
      'Geraldton', 'Kalgoorlie', 'Albany', 'Esperance', 'Margaret River',
    ],
    'South Australia': [
      'Adelaide CBD', 'Glenelg', 'Norwood', 'Unley', 'Burnside',
      'Prospect', 'Salisbury', 'Elizabeth', 'Marion', 'Noarlunga',
      'Mount Barker', 'Victor Harbor', 'Murray Bridge', 'Whyalla',
      'Mount Gambier', 'Port Augusta', 'Port Pirie', 'Renmark',
    ],
    'Tasmania': [
      'Hobart', 'Sandy Bay', 'Kingston', 'Glenorchy', 'Launceston',
      'Devonport', 'Burnie', 'Ulverstone', 'Wynyard', 'Scottsdale',
    ],
    'Northern Territory': [
      'Darwin CBD', 'Palmerston', 'Casuarina', 'Nightcliff', 'Fannie Bay',
      'Alice Springs', 'Katherine', 'Tennant Creek', 'Nhulunbuy',
    ],
    'Australian Capital Territory': [
      'Canberra City', 'Braddon', 'Kingston', 'Manuka', 'Barton',
      'Belconnen', 'Tuggeranong', 'Woden', 'Weston Creek', 'Gungahlin',
      'Queanbeyan',
    ],
  };

  void _onSearch(String q) {
    if (q.isEmpty || _selectedState == null) {
      setState(() {
        _filteredSuburbs = [];
        _searching = false;
      });
      return;
    }
    final all = _suburbsByState[_selectedState] ?? [];
    setState(() {
      _searching = true;
      _filteredSuburbs = all
          .where((s) => s.toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  Future<void> _confirm() async {
    if (_selectedSuburb == null || _selectedState == null) return;
    setState(() => _loading = true);
    try {
      if (widget.isEditing) {
        // Just pop with result
        if (mounted) Navigator.pop(context, {'suburb': _selectedSuburb, 'state': _selectedState});
        return;
      }
      await _authService.createUserProfile(
        uid: widget.uid!,
        email: widget.email!,
        displayName: widget.displayName!,
        suburb: _selectedSuburb!,
        state: _selectedState!,
        photoUrl: widget.photoUrl,
      );
      if (mounted) context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.sand,
      appBar: AppBar(
        backgroundColor: AppTheme.sand,
        elevation: 0,
        leading: widget.isEditing ? BackButton(color: AppTheme.charcoal) : null,
        title: const Text('Your suburb'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            if (!widget.isEditing)
              const Text(
                'Which suburb do you live in?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.charcoal,
                  letterSpacing: -0.3,
                ),
              ),
            if (!widget.isEditing) const SizedBox(height: 4),
            if (!widget.isEditing)
              const Text(
                'Your feed will show posts from neighbours in your suburb.',
                style: TextStyle(fontSize: 14, color: AppTheme.midGrey, height: 1.4),
              ),
            const SizedBox(height: 20),

            // State picker
            DropdownButtonFormField<String>(
              value: _selectedState,
              decoration: const InputDecoration(
                labelText: 'State / Territory',
                prefixIcon: Icon(Icons.map_outlined),
              ),
              items: AppConstants.australianStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedState = v;
                  _selectedSuburb = null;
                  _searchCtrl.clear();
                  _filteredSuburbs = [];
                  _searching = false;
                });
              },
            ),
            const SizedBox(height: 14),

            if (_selectedState != null) ...[
              TextFormField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  labelText: 'Search suburb',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              if (_selectedSuburb != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGreenPale,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.brandGreenLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppTheme.brandGreen, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '$_selectedSuburb, $_selectedState',
                        style: const TextStyle(
                          color: AppTheme.brandGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_searching && _filteredSuburbs.isNotEmpty)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.lightGrey),
                    ),
                    child: ListView.separated(
                      itemCount: _filteredSuburbs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final s = _filteredSuburbs[i];
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined,
                              color: AppTheme.brandGreen),
                          title: Text(s),
                          onTap: () {
                            setState(() {
                              _selectedSuburb = s;
                              _searchCtrl.clear();
                              _filteredSuburbs = [];
                              _searching = false;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),

              if (_searching && _filteredSuburbs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.lightGrey),
                  ),
                  child: const Text(
                    'No suburbs found. Try a different spelling.',
                    style: TextStyle(color: AppTheme.midGrey),
                  ),
                ),
            ],

            const Spacer(),
            ElevatedButton(
              onPressed: (_selectedSuburb != null && !_loading) ? _confirm : null,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.white),
                    )
                  : Text(widget.isEditing ? 'Save suburb' : "Let's go"),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
