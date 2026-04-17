// ไฟล์: lib/screens/user_screen.dart
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';

const List<String> kAllPages = [
  'Dashboard', 'Search & Reserve', 'Topology Map', 'Bulk Import',
  'Domain & IP', 'Models', 'Site Code', 'Network Nodes',
];

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  final _api = ApiService();

  static const Map<String, Color> _colorMap = {
    'blue':   AppColors.primary,
    'purple': Colors.purple,
    'teal':   Colors.teal,
    'orange': Colors.orange,
    'pink':   Colors.pink,
    'indigo': Colors.indigo,
    'green':  Colors.green,
    'red':    Colors.red,
  };
  static const List<String> _colorKeys = [
    'blue','purple','teal','orange','pink','indigo','green','red'
  ];

  Color _toColor(String? k) => _colorMap[k ?? 'blue'] ?? AppColors.primary;
  String _fromColor(Color c) => _colorMap.entries
    .firstWhere((e) => e.value == c,
      orElse: () => const MapEntry('blue', AppColors.primary)).key;

  List<Map<String, dynamic>> _users  = [];
  List<Map<String, dynamic>> _roles  = [];
  bool   _loading     = true;
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered => _users.where((u) =>
    u['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
    u['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
    u['role_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final r = await Future.wait([_api.fetchUsers(), _api.fetchRoles()]);
    setState(() { _users = r[0]; _roles = r[1]; _loading = false; });
  }

  Future<void> _fetchUsers() async {
    final d = await _api.fetchUsers();
    setState(() => _users = d);
  }

  // ════════════════════════════════════════════
  //  MANAGE ROLES DIALOG
  // ════════════════════════════════════════════
  void _showManageRolesDialog() {
    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 560, padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Manage Roles', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
              Row(children: [
                ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _showRoleFormDialog(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Role')),
                const SizedBox(width: 8),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
            ]),
            const Divider(height: 20),
            Text('Role เป็น template permission — สามารถ customize ต่อได้ใน User',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: _roles.isEmpty
                ? Center(child: Text('ยังไม่มี Role',
                    style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    shrinkWrap: true, itemCount: _roles.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (_, i) {
                      final r = _roles[i];
                      final c = _toColor(r['badge_color']);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: c.withOpacity(0.12),
                          child: Icon(Icons.shield_outlined, color: c, size: 18)),
                        title: Text(r['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(r['description'] ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 18),
                            onPressed: () { Navigator.pop(ctx); _showRoleFormDialog(existing: r); }),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18),
                            onPressed: () async {
                              final res = await _api.deleteRole(r['id'] as int);
                              if (res?['error'] != null && mounted) {
                                AppSnackbar.error(context, res!['error']);
                              } else {
                                await _loadAll();
                                if (mounted) Navigator.pop(ctx);
                                if (mounted) _showManageRolesDialog();
                              }
                            }),
                        ]),
                      );
                    }),
            ),
          ]),
        ),
      ),
    ));
  }

  void _showRoleFormDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');
    Map<String, String> sel = existing != null
      ? Map<String, String>.from(existing['page_access'] ?? {}) : {};
    Color selColor = _toColor(existing?['badge_color']);

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 560, padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(existing == null ? 'Create Role' : 'Edit Role',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 20),
              Row(children: [
                Expanded(child: _dialogField(nameCtrl, 'Role Name', 'e.g., NOC Operator')),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Color', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: _colorKeys.map((k) {
                    final c = _toColor(k);
                    return InkWell(
                      onTap: () => setD(() => selColor = c),
                      child: CircleAvatar(backgroundColor: c, radius: 14,
                        child: selColor == c ? const Icon(Icons.check, color: Colors.white, size: 14) : null));
                  }).toList()),
                ]),
              ]),
              const SizedBox(height: 12),
              _dialogField(descCtrl, 'Description', 'e.g., NOC monitoring role'),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Page Access', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                Row(children: [
                  TextButton(onPressed: () => setD(() => sel = {for (var p in kAllPages) p: 'view'}),
                    child: const Text('All View', style: TextStyle(fontSize: 11, color: Colors.orange))),
                  TextButton(onPressed: () => setD(() => sel = {for (var p in kAllPages) p: 'edit'}),
                    child: const Text('All Edit', style: TextStyle(fontSize: 11, color: AppColors.primary))),
                  TextButton(onPressed: () => setD(() => sel.clear()),
                    child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red))),
                ]),
              ]),
              const SizedBox(height: 6),
              _buildPageAccessTable(sel, (p, v) => setD(() {
                if (v == 'none') sel.remove(p); else sel[p] = v;
              })),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(
                  onPressed: () { Navigator.pop(ctx); _showManageRolesDialog(); },
                  child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final payload = {
                      'name':        nameCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'page_access': sel,
                      'badge_color': _fromColor(selColor),
                    };
                    Map<String, dynamic>? res;
                    if (existing == null) {
                      res = await _api.createRole(payload);
                    } else {
                      res = await _api.updateRole(existing['id'] as int, payload);
                    }
                    if (res != null && res['error'] == null) {
                      await _loadAll();
                      if (mounted) Navigator.pop(ctx);
                      if (mounted) _showManageRolesDialog();
                    } else if (mounted) {
                      AppSnackbar.error(context, res?['error'] ?? 'เกิดข้อผิดพลาด');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: const Text('Save Role')),
              ]),
            ],
          )),
        ),
      ),
    ));
  }

  // ════════════════════════════════════════════
  //  USER DIALOG
  // ════════════════════════════════════════════
  void _showUserDialog({Map<String, dynamic>? existing}) {
    final nameCtrl     = TextEditingController(text: existing?['name'] ?? '');
    final emailCtrl    = TextEditingController(text: existing?['email'] ?? '');
    final usernameCtrl = TextEditingController(text: existing?['username'] ?? '');
    final passCtrl     = TextEditingController();
    String selRole     = existing?['role_name'] ?? (_roles.isNotEmpty ? _roles.first['name'] : 'Viewer');
    Map<String, String> selAccess = existing != null
      ? Map<String, String>.from(existing['page_access'] ?? {})
      : (_roles.isNotEmpty ? Map<String, String>.from(_roles.first['page_access'] ?? {}) : {});
    bool sendEmail = existing == null;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setD) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 560, padding: const EdgeInsets.all(28),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(existing == null ? 'Add User' : 'Edit User',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.dark)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ]),
              const Divider(height: 20),
              Row(children: [
                Expanded(child: _dialogField(nameCtrl, 'Full Name', 'e.g., Somchai')),
                const SizedBox(width: 12),
                Expanded(child: _dialogField(usernameCtrl, 'Username', 'e.g., somchai.j')),
              ]),
              const SizedBox(height: 12),
              _dialogField(emailCtrl, 'Email', 'e.g., user@uih.co.th'),
              if (existing == null) ...[
                const SizedBox(height: 12),
                _dialogField(passCtrl, 'Password', '••••••••', obscure: true),
              ] else ...[
                const SizedBox(height: 12),
                _dialogField(passCtrl, 'Password ใหม่ (ถ้าต้องการเปลี่ยน)', '• เว้นว่างถ้าไม่เปลี่ยน', obscure: true),
              ],
              const SizedBox(height: 16),

              // Role selector from DB
              const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              _roles.isEmpty
                ? Text('ยังไม่มี Role — กรุณาสร้าง Role ก่อน',
                    style: TextStyle(color: Colors.orange.shade700, fontSize: 12))
                : Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8)),
                    child: Column(children: _roles.map((role) {
                      final isSel = selRole == role['name'];
                      final c = _toColor(role['badge_color']);
                      return InkWell(
                        onTap: () => setD(() {
                          selRole = role['name'];
                          selAccess = Map<String, String>.from(role['page_access'] ?? {});
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withOpacity(0.06) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8)),
                          child: Row(children: [
                            Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSel ? AppColors.primary : Colors.grey.shade400, size: 18),
                            const SizedBox(width: 10),
                            CircleAvatar(radius: 10,
                              backgroundColor: c.withOpacity(0.15),
                              child: Icon(Icons.shield_outlined, size: 12, color: c)),
                            const SizedBox(width: 8),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(role['name'] ?? '', style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13,
                                color: isSel ? AppColors.primary : AppColors.dark)),
                              Text(role['description'] ?? '',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                            ])),
                          ]),
                        ),
                      );
                    }).toList()),
                  ),
              const SizedBox(height: 16),

              // Page Access (customizable per user)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Page Access (Custom)', style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
                Row(children: [
                  TextButton(onPressed: () => setD(() => selAccess = {for (var p in kAllPages) p: 'view'}),
                    child: const Text('All View', style: TextStyle(fontSize: 11, color: Colors.orange))),
                  TextButton(onPressed: () => setD(() => selAccess = {for (var p in kAllPages) p: 'edit'}),
                    child: const Text('All Edit', style: TextStyle(fontSize: 11, color: AppColors.primary))),
                  TextButton(onPressed: () => setD(() => selAccess.clear()),
                    child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red))),
                ]),
              ]),
              const SizedBox(height: 6),
              _buildPageAccessTable(selAccess, (p, v) => setD(() {
                if (v == 'none') selAccess.remove(p); else selAccess[p] = v;
              })),
              const SizedBox(height: 16),

              if (existing == null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                  child: CheckboxListTile(
                    value: sendEmail, onChanged: (v) => setD(() => sendEmail = v!),
                    activeColor: AppColors.primary, contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Send Welcome Email & Credentials',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    subtitle: const Text('ส่ง username/password ไปยัง email ที่กรอก',
                      style: TextStyle(fontSize: 11))),
                ),

              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty ||
                        usernameCtrl.text.trim().isEmpty ||
                        emailCtrl.text.trim().isEmpty) {
                      AppSnackbar.warning(context, 'กรอกข้อมูลให้ครบ');
                      return;
                    }
                    if (existing == null && passCtrl.text.isEmpty) {
                      AppSnackbar.warning(context, 'กรอก Password ด้วย');
                      return;
                    }
                    Navigator.pop(ctx);

                    if (existing == null) {
                      final result = await _api.createUser({
                        'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(),
                        'username': usernameCtrl.text.trim(), 'password': passCtrl.text,
                        'role_name': selRole, 'page_access': selAccess, 'is_active': true,
                      });
                      if (result != null && result['error'] == null) {
                        await _fetchUsers();
                        if (sendEmail && mounted) {
                          _showEmailSuccessDialog(nameCtrl.text.trim(),
                            usernameCtrl.text.trim(), emailCtrl.text.trim(), selRole);
                        } else if (mounted) {
                          AppSnackbar.success(context, 'สร้าง User สำเร็จ');
                        }
                      } else if (mounted) {
                        AppSnackbar.error(context, result?['error'] ?? 'สร้างไม่สำเร็จ');
                      }
                    } else {
                      final payload = <String, dynamic>{
                        'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(),
                        'username': usernameCtrl.text.trim(),
                        'role_name': selRole, 'page_access': selAccess,
                      };
                      if (passCtrl.text.isNotEmpty) payload['password'] = passCtrl.text;
                      final result = await _api.updateUser(existing['id'] as int, payload);
                      if (result != null && result['error'] == null) {
                        await _fetchUsers();
                        if (mounted) AppSnackbar.success(context, 'แก้ไขข้อมูลสำเร็จ');
                      } else if (mounted) {
                        AppSnackbar.error(context, result?['error'] ?? 'แก้ไขไม่สำเร็จ');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text(existing == null ? 'Create User' : 'Save Changes',
                    style: const TextStyle(fontWeight: FontWeight.bold))),
              ]),
            ],
          )),
        ),
      ),
    ));
  }

  // ════════════════════════════════════════════
  //  EMAIL SUCCESS DIALOG
  // ════════════════════════════════════════════
  void _showEmailSuccessDialog(String name, String username, String email, String role) {
    showDialog(context: context, builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 440, padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Icon(Icons.mark_email_read_rounded, size: 48, color: AppColors.primary)),
          const SizedBox(height: 20),
          const Text('User Created Successfully!',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.dark)),
          const SizedBox(height: 8),
          Text('ระบบสร้างบัญชีใหม่เรียบร้อยแล้ว',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border)),
            child: Column(children: [
              _summaryRow(Icons.person_outline,         'Full Name', name),
              const Divider(height: 20),
              _summaryRow(Icons.account_circle_outlined, 'Username',  username),
              const Divider(height: 20),
              _summaryRow(Icons.shield_outlined,         'Role',      role),
              const Divider(height: 20),
              _summaryRow(Icons.email_outlined,          'Email',     email, highlight: true),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)))),
        ]),
      ),
    ));
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final active   = _users.where((u) => u['is_active'] == true || u['is_active'] == 'true').length;
    final inactive = _users.length - active;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('User Management',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.dark)),
            Text('จัดการผู้ใช้งานและสิทธิ์การเข้าถึง Node Assist PRO',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ]),
          Row(children: [
            OutlinedButton.icon(
              onPressed: _showManageRolesDialog,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                side: BorderSide(color: Colors.grey.shade300)),
              icon: const Icon(Icons.admin_panel_settings, size: 16, color: AppColors.dark),
              label: const Text('Manage Roles',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.dark))),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _showUserDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
        ]),
        const SizedBox(height: 24),

        Row(children: [
          _statCard('Total Users', '${_users.length}',  Icons.people_outline,      AppColors.primary),
          const SizedBox(width: 12),
          _statCard('Roles',       '${_roles.length}',  Icons.shield_outlined,      Colors.purple),
          const SizedBox(width: 12),
          _statCard('Active',      '$active',           Icons.check_circle_outline, AppColors.success),
          const SizedBox(width: 12),
          _statCard('Inactive',    '$inactive',         Icons.cancel_outlined,      Colors.grey),
        ]),
        const SizedBox(height: 20),

        SizedBox(width: 300, child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: AppInputDecoration.search(hint: 'Search name, email, role...'),
        )),
        const SizedBox(height: 16),

        Expanded(child: Container(
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02),
              blurRadius: 8, offset: const Offset(0, 4))]),
          child: Column(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                border: Border(bottom: BorderSide(color: AppColors.border))),
              child: Row(children: [
                Expanded(flex: 3, child: _hdr('USER')),
                Expanded(flex: 2, child: _hdr('ROLE')),
                Expanded(flex: 4, child: _hdr('PAGE ACCESS')),
                Expanded(flex: 2, child: _hdr('STATUS')),
                const SizedBox(width: 80,
                  child: Center(child: Text('ACTION', style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1)))),
              ]),
            ),
            Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? Center(child: Text('ไม่พบ User',
                    style: TextStyle(color: Colors.grey.shade400)))
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border),
                    itemBuilder: (_, i) => _buildUserRow(_filtered[i]))),
          ]),
        )),
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  USER ROW
  // ════════════════════════════════════════════
  Widget _buildUserRow(Map<String, dynamic> user) {
    final roleName = user['role_name']?.toString() ?? '';
    final roleData = _roles.firstWhere((r) => r['name'] == roleName,
      orElse: () => {'badge_color': 'blue'});
    final c = _toColor(roleData['badge_color']);
    final pages = Map<String, String>.from(user['page_access'] ?? {}).entries.toList();
    final isActive = user['is_active'] == true || user['is_active'] == 'true';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          CircleAvatar(backgroundColor: c.withOpacity(0.12), radius: 18,
            child: Text((user['name'] ?? '?')[0],
              style: TextStyle(color: c, fontSize: 15, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user['name']?.toString() ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.dark)),
            Text(user['email']?.toString() ?? '-',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text('@${user['username'] ?? '-'}',
              style: TextStyle(fontSize: 10, color: AppColors.primary)),
          ])),
        ])),
        Expanded(flex: 2, child: Row(children: [
          Icon(Icons.shield_outlined, size: 13, color: c),
          const SizedBox(width: 5),
          Text(roleName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: c)),
        ])),
        Expanded(flex: 4, child: Wrap(spacing: 4, runSpacing: 4,
          children: pages.take(4).map((e) {
            final isEdit = e.value == 'edit';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isEdit ? AppColors.primarySurface : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isEdit
                  ? AppColors.primary.withOpacity(0.3) : Colors.orange.shade200)),
              child: Text('${e.key} (${isEdit ? "E" : "V"})',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                  color: isEdit ? AppColors.primary : Colors.orange.shade800)));
          }).toList())),
        Expanded(flex: 2, child: GestureDetector(
          onTap: () async {
            final res = await _api.updateUser(user['id'] as int, {'is_active': !isActive});
            if (res != null && res['error'] == null) _fetchUsers();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? AppColors.availableBg : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? AppColors.availableBorder : Colors.grey.shade300)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 7, color: isActive ? AppColors.success : Colors.grey.shade500),
              const SizedBox(width: 5),
              Text(isActive ? 'Active' : 'Inactive',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: isActive ? AppColors.availableText : Colors.grey.shade600)),
            ]),
          ),
        )),
        SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16), color: Colors.blueGrey,
            onPressed: () => _showUserDialog(existing: user)),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16), color: Colors.red.shade400,
            onPressed: () async {
              final ok = await _api.deleteUser(user['id'] as int);
              if (ok && mounted) {
                _fetchUsers();
                AppSnackbar.info(context, 'ลบ ${user['name']} แล้ว');
              }
            }),
        ])),
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  HELPERS
  // ════════════════════════════════════════════
  Widget _buildPageAccessTable(Map<String, String> sel,
      void Function(String, String) onChange) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
      child: Column(children: kAllPages.map((page) {
        final cur = sel[page] ?? 'none';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
          child: Row(children: [
            Expanded(child: Text(page, style: TextStyle(fontSize: 13,
              fontWeight: cur != 'none' ? FontWeight.bold : FontWeight.normal,
              color: cur != 'none' ? AppColors.dark : Colors.grey.shade400))),
            _permBtn('none', 'None', Icons.block,               cur, onChange, page),
            const SizedBox(width: 6),
            _permBtn('view', 'View', Icons.visibility_outlined,  cur, onChange, page),
            const SizedBox(width: 6),
            _permBtn('edit', 'Edit', Icons.edit_outlined,        cur, onChange, page),
          ]),
        );
      }).toList()),
    );
  }

  Widget _permBtn(String type, String label, IconData icon,
      String cur, void Function(String, String) onChange, String page) {
    final isSel = cur == type;
    final color = type == 'edit' ? AppColors.primary
      : type == 'view' ? Colors.orange.shade600 : Colors.grey.shade500;
    return InkWell(
      onTap: () => onChange(page, type), borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isSel ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Icon(icon, size: 11, color: isSel ? color : Colors.grey.shade400),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
            color: isSel ? color : Colors.grey.shade400)),
        ]),
      ),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint,
      {bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold,
        fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure,
        decoration: AppInputDecoration.standard(hint: hint)),
    ]);
  }

  Widget _summaryRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Row(children: [
      Icon(icon, size: 16, color: Colors.grey.shade400), const SizedBox(width: 10),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
        color: highlight ? AppColors.primary : AppColors.dark)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
      ]),
    ));
  }

  Widget _hdr(String label) => Text(label, style: const TextStyle(
    fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey, letterSpacing: 1));
}