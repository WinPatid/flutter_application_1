// ไฟล์: lib/screens/user_screen.dart
import 'package:flutter/material.dart';

// ─── Models ───
class AppRole {
  String id; String name; String description;
  Map<String, String> pageAccess; Color badgeColor;
  AppRole({required this.id, required this.name, required this.description, required this.pageAccess, required this.badgeColor});
}

class AppUser {
  final String id; String name; String email; String username;
  String roleName; Map<String, String> customAccess; bool isActive;
  AppUser({required this.id, required this.name, required this.email, required this.username, required this.roleName, required this.customAccess, this.isActive = true});
}

const List<String> kAllPages = ['Dashboard', 'Search & Reserve', 'Topology Map', 'Bulk Import', 'Domain & IP', 'Models', 'Site Code'];

class UserScreen extends StatefulWidget {
  const UserScreen({super.key});
  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  // ── Database จำลอง ──
  final List<AppRole> _roles = [
    AppRole(id: '1', name: 'Manager', description: 'เข้าถึงและจัดการ (Edit) ได้ทุกหน้า + จัดการ User', pageAccess: { for (var p in kAllPages) p: 'edit' }, badgeColor: Colors.purple),
    AppRole(id: '2', name: 'Network Design Engineer', description: 'เข้าถึงได้เฉพาะหน้าที่กำหนดสิทธิ์ (View / Edit)', pageAccess: {'Dashboard': 'view', 'Search & Reserve': 'edit', 'Topology Map': 'view'}, badgeColor: Colors.teal),
  ];

  late final List<AppUser> _users = [
    AppUser(id: '1', name: 'Chaiya', email: 'chaiya@uih.co.th', username: 'admin', roleName: 'Manager', customAccess: _roles[0].pageAccess, isActive: true),
    AppUser(id: '2', name: 'Win', email: 'win@uih.co.th', username: 'UIH', roleName: 'Network Design Engineer', customAccess: _roles[1].pageAccess, isActive: true),
    AppUser(id: '3', name: 'Mart', email: 'mart@uih.co.th', username: 'UIH', roleName: 'Network Design Engineer', customAccess: {'Dashboard': 'view', 'Search & Reserve': 'view'}, isActive: false),
  ];

  String _searchQuery = '';
  List<AppUser> get _filtered => _users.where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()) || u.email.toLowerCase().contains(_searchQuery.toLowerCase()) || u.roleName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

  // ════════════════════════════════════════════
  //  DIALOG: จัดการ Roles (Manager)
  // ════════════════════════════════════════════
  void _showManageRolesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600, padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Manage Roles', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Row(children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showRoleFormDialog();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                      icon: const Icon(Icons.add, size: 16), label: const Text('Add Role')),
                    const SizedBox(width: 8),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ]),
                ]),
                const Divider(height: 24),
                const Text('กำหนดบทบาทหลักเพื่อใช้เป็นเทมเพลตสำหรับ User', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.separated(
                    shrinkWrap: true, itemCount: _roles.length, separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(backgroundColor: role.badgeColor.withOpacity(0.1), child: Icon(Icons.shield, color: role.badgeColor)),
                        title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${role.pageAccess.length} Pages Access', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showRoleFormDialog(existing: role);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleFormDialog({AppRole? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    Map<String, String> selectedAccess = existing != null ? Map.from(existing.pageAccess) : {};
    Color selectedColor = existing?.badgeColor ?? Colors.blue;
    final List<Color> colorOptions = [Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.pink, Colors.indigo];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 600, padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(existing == null ? 'Create New Role' : 'Edit Role', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ]),
                  const Divider(height: 24),

                  Row(children: [
                    Expanded(child: _dialogField(nameCtrl, 'Role Name', 'e.g., NOC Operator')),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Badge Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                      const SizedBox(height: 8),
                      Wrap(spacing: 8, children: colorOptions.map((c) => InkWell(onTap: () => setStateDialog(() => selectedColor = c), child: CircleAvatar(backgroundColor: c, radius: 16, child: selectedColor == c ? const Icon(Icons.check, color: Colors.white, size: 16) : null))).toList()),
                    ])),
                  ]),
                  const SizedBox(height: 16),
                  _dialogField(descCtrl, 'Description', 'e.g., Monitoring role...'),
                  const SizedBox(height: 24),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Default Page Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                    Row(children: [
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess = { for (var p in kAllPages) p: 'view' }), child: const Text('All View', style: TextStyle(fontSize: 12, color: Colors.orange))),
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess = { for (var p in kAllPages) p: 'edit' }), child: const Text('All Edit', style: TextStyle(fontSize: 12, color: Colors.blue))),
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess.clear()), child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red))),
                    ])
                  ]),
                  const SizedBox(height: 8),
                  
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: Column(children: kAllPages.map((page) {
                      final currentStatus = selectedAccess[page] ?? 'none';
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                        child: Row(children: [
                          Expanded(child: Text(page, style: TextStyle(fontSize: 14, fontWeight: currentStatus != 'none' ? FontWeight.bold : FontWeight.normal, color: currentStatus != 'none' ? const Color(0xFF0F172A) : Colors.grey.shade400))),
                          _buildPermissionSelector('none', 'None', Icons.block, currentStatus, false, () => setStateDialog(() => selectedAccess.remove(page))), const SizedBox(width: 8),
                          _buildPermissionSelector('view', 'View', Icons.visibility_outlined, currentStatus, false, () => setStateDialog(() => selectedAccess[page] = 'view')), const SizedBox(width: 8),
                          _buildPermissionSelector('edit', 'Edit', Icons.edit_outlined, currentStatus, false, () => setStateDialog(() => selectedAccess[page] = 'edit')),
                        ]),
                      );
                    }).toList()),
                  ),

                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () { Navigator.pop(ctx); _showManageRolesDialog(); }, child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.isEmpty) return;
                        setState(() {
                          if (existing == null) {
                            _roles.add(AppRole(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), description: descCtrl.text.trim(), pageAccess: Map.from(selectedAccess), badgeColor: selectedColor));
                          } else {
                            existing.name = nameCtrl.text.trim(); existing.description = descCtrl.text.trim(); existing.pageAccess = Map.from(selectedAccess); existing.badgeColor = selectedColor;
                          }
                        });
                        Navigator.pop(ctx);
                        _showManageRolesDialog(); // กลับไปหน้าลิสต์
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white),
                      child: const Text('Save Role'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════
  //  ✨ DIALOG: สรุปผลหลังจากสร้าง User (ส่ง Email)
  // ════════════════════════════════════════════
  void _showEmailSuccessDialog(String name, String username, String email, String role) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480, // ขยายให้กว้างขึ้นนิดนึงเพื่อใส่ตาราง
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                child: Icon(Icons.mark_email_read_rounded, size: 56, color: Colors.blue.shade600),
              ),
              const SizedBox(height: 24),
              const Text('User Created Successfully!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Text('ระบบได้สร้างบัญชีผู้ใช้งานใหม่ และกำลังจัดส่งข้อมูลการเข้าสู่ระบบไปยังอีเมลเป้าหมาย', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5)),
              const SizedBox(height: 24),
              
              // ── กล่องสรุปข้อมูล (Summary Box) ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: Column(
                  children: [
                    _buildSummaryRow(Icons.person_outline, 'Full Name', name),
                    const Divider(height: 24),
                    _buildSummaryRow(Icons.account_circle_outlined, 'Username', username),
                    const Divider(height: 24),
                    _buildSummaryRow(Icons.shield_outlined, 'Role', role),
                    const Divider(height: 24),
                    _buildSummaryRow(Icons.email_outlined, 'Send to', email, isHighlight: true),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              // โน้ตบอกเพื่อน Backend
              Text('*ส่วนนี้จะเชื่อม API ยิงอีเมลผ่าน Backend ของเพื่อนคุณ', textAlign: TextAlign.center, style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: const Text('Got it, Thanks!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // วิดเจ็ตช่วยวาดแถวในกล่องสรุป
  Widget _buildSummaryRow(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isHighlight ? Colors.blue.shade700 : const Color(0xFF0F172A))),
      ],
    );
  }

  // ════════════════════════════════════════════
  //  DIALOG: เพิ่ม / แก้ไข User (All-in-one)
  // ════════════════════════════════════════════
  void _showUserDialog({AppUser? existing}) {
    final nameCtrl     = TextEditingController(text: existing?.name ?? '');
    final emailCtrl    = TextEditingController(text: existing?.email ?? '');
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final passCtrl     = TextEditingController();
    
    String selectedRoleName = existing?.roleName ?? _roles.first.name;
    Map<String, String> selectedAccess = existing != null ? Map.from(existing.customAccess) : Map.from(_roles.first.pageAccess);
    bool sendEmailNotify = existing == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 580, padding: const EdgeInsets.all(32),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(existing == null ? 'Add User' : 'Edit User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ]),
                  const Divider(height: 24),

                  Row(children: [
                    Expanded(child: _dialogField(nameCtrl, 'Full Name', 'e.g., Somchai')),
                    const SizedBox(width: 16),
                    Expanded(child: _dialogField(usernameCtrl, 'Username', 'e.g., somchai.j')),
                  ]),
                  const SizedBox(height: 16),
                  _dialogField(emailCtrl, 'Email Address', 'e.g., email@uih.co.th'),
                  const SizedBox(height: 16),

                  if (existing == null) ...[
                    _dialogField(passCtrl, 'Password', '••••••••', obscure: true),
                    const SizedBox(height: 16),
                  ],

                  const Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      children: _roles.map((role) {
                        final isSelected = selectedRoleName == role.name;
                        return InkWell(
                          onTap: () => setStateDialog(() {
                            selectedRoleName = role.name;
                            selectedAccess = Map.from(role.pageAccess); 
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: isSelected ? const Color(0xFF0056B3).withOpacity(0.06) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                            child: Row(children: [
                              Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? const Color(0xFF0056B3) : Colors.grey.shade400, size: 20),
                              const SizedBox(width: 12),
                              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(role.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? const Color(0xFF0056B3) : const Color(0xFF0F172A))),
                                Text(role.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ]),
                            ]),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Page Access & Permissions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
                    Row(children: [
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess = { for (var p in kAllPages) p: 'view' }), child: const Text('All View', style: TextStyle(fontSize: 12, color: Colors.orange))),
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess = { for (var p in kAllPages) p: 'edit' }), child: const Text('All Edit', style: TextStyle(fontSize: 12, color: Colors.blue))),
                      TextButton(onPressed: () => setStateDialog(() => selectedAccess.clear()), child: const Text('Clear', style: TextStyle(fontSize: 12, color: Colors.red))),
                    ])
                  ]),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8), color: Colors.white),
                    child: Column(
                      children: kAllPages.map((page) {
                        final currentStatus = selectedAccess[page] ?? 'none';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                          child: Row(children: [
                            Expanded(child: Text(page, style: TextStyle(fontSize: 14, fontWeight: currentStatus != 'none' ? FontWeight.bold : FontWeight.normal, color: currentStatus != 'none' ? const Color(0xFF0F172A) : Colors.grey.shade400))),
                            _buildPermissionSelector('none', 'None', Icons.block, currentStatus, false, () => setStateDialog(() => selectedAccess.remove(page))), const SizedBox(width: 8),
                            _buildPermissionSelector('view', 'View', Icons.visibility_outlined, currentStatus, false, () => setStateDialog(() => selectedAccess[page] = 'view')), const SizedBox(width: 8),
                            _buildPermissionSelector('edit', 'Edit', Icons.edit_outlined, currentStatus, false, () => setStateDialog(() => selectedAccess[page] = 'edit')),
                          ]),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (existing == null) ...[
                    Container(
                      padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
                      child: CheckboxListTile(
                        value: sendEmailNotify,
                        onChanged: (val) => setStateDialog(() => sendEmailNotify = val!),
                        activeColor: Colors.blue.shade700, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
                        title: const Text('Send Welcome Email & Credentials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: const Text('ระบบจะสร้างรหัสผ่านอัตโนมัติและส่งไปยังอีเมลนี้', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty || usernameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                        Navigator.pop(ctx);
                        setState(() {
                          if (existing == null) {
                            _users.add(AppUser(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), email: emailCtrl.text.trim(), username: usernameCtrl.text.trim(), roleName: selectedRoleName, customAccess: Map.from(selectedAccess)));
                          } else {
                            existing.name = nameCtrl.text.trim(); existing.email = emailCtrl.text.trim(); existing.username = usernameCtrl.text.trim(); existing.roleName = selectedRoleName; existing.customAccess = Map.from(selectedAccess);
                          }
                        });
                        
                        // ✨ อัปเดตการแสดงผลเมื่อส่งอีเมล
                        if (existing == null && sendEmailNotify) {
                          _showEmailSuccessDialog(
                            nameCtrl.text.trim(), 
                            usernameCtrl.text.trim(), 
                            emailCtrl.text.trim(), 
                            selectedRoleName
                          );
                        } else {
                          _showSnack(existing == null ? '✅ สร้าง User สำเร็จ' : '✅ แก้ไขข้อมูลสำเร็จ', Colors.green);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                      child: Text(existing == null ? 'Create User' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionSelector(String type, String label, IconData icon, String currentStatus, bool isDisabled, VoidCallback onTap) {
    final isSelected = currentStatus == type;
    Color activeColor = type == 'edit' ? Colors.blue.shade600 : type == 'view' ? Colors.orange.shade600 : Colors.grey.shade500;
    return InkWell(
      onTap: isDisabled ? null : onTap, borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: isSelected ? activeColor.withOpacity(0.1) : Colors.transparent, border: Border.all(color: isSelected ? activeColor : Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
        child: Row(children: [
          Icon(icon, size: 12, color: isSelected ? activeColor : Colors.grey.shade400), const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? activeColor : Colors.grey.shade500)),
        ]),
      ),
    );
  }

  void _toggleActive(AppUser user) => setState(() => user.isActive = !user.isActive);

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color, behavior: SnackBarBehavior.floating));
  }

  // ════════════════════════════════════════════
  //  BUILD - MAIN SCREEN
  // ════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('User Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 4), Text('จัดการผู้ใช้งานและสิทธิ์การเข้าถึง', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ]),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showManageRolesDialog(),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), side: BorderSide(color: Colors.grey.shade300)),
                icon: const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF0F172A)), 
                label: const Text('Manage Roles', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showUserDialog(),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0056B3), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                icon: const Icon(Icons.person_add_outlined, size: 18), label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ]),
        const SizedBox(height: 32),

        Row(children: [
          _buildStatCard('Total Users', _users.length.toString(), Icons.people_outline, Colors.blue), const SizedBox(width: 16),
          _buildStatCard('Roles Configured', _roles.length.toString(), Icons.shield_outlined, Colors.purple), const SizedBox(width: 16),
          _buildStatCard('Active Users', _users.where((u) => u.isActive).length.toString(), Icons.check_circle_outline, Colors.green),
        ]),
        const SizedBox(height: 24),

        SizedBox(
          width: 320,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(hintText: 'Search user, email or role...', prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200))),
          ),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12)), border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('USER PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1))),
                  Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1))),
                  Expanded(flex: 4, child: Text('PAGE PERMISSIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1))),
                  Expanded(flex: 2, child: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1))),
                  SizedBox(width: 80, child: Text('ACTION', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade500, letterSpacing: 1))),
                ]),
              ),
              Expanded(
                child: ListView(
                  children: _filtered.map((user) {
                    final roleData = _roles.firstWhere((r) => r.name == user.roleName, orElse: () => _roles.first);
                    final accessedPages = user.customAccess.entries.toList();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
                      child: Row(children: [
                        Expanded(flex: 3, child: Row(children: [
                          CircleAvatar(backgroundColor: roleData.badgeColor.withOpacity(0.1), radius: 20, child: Text(user.name[0], style: TextStyle(color: roleData.badgeColor, fontSize: 16, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 16), 
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                          ])),
                        ])),
                        Expanded(flex: 2, child: Row(children: [
                          Icon(Icons.shield, size: 14, color: roleData.badgeColor), const SizedBox(width: 6),
                          Text(user.roleName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: roleData.badgeColor)),
                        ])),
                        Expanded(flex: 4, child: Wrap(spacing: 6, runSpacing: 6, children: accessedPages.take(3).map((entry) {
                          final isEdit = entry.value == 'edit';
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isEdit ? Colors.blue.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(4), border: Border.all(color: isEdit ? Colors.blue.shade200 : Colors.orange.shade200)),
                            child: Text('${entry.key} ${isEdit ? '(Edit)' : '(View)'}', style: TextStyle(fontSize: 10, color: isEdit ? Colors.blue.shade800 : Colors.orange.shade800, fontWeight: FontWeight.w600)),
                          );
                        }).toList())),
                        Expanded(flex: 2, child: GestureDetector(
                          onTap: () => _toggleActive(user),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: user.isActive ? Colors.green.shade50 : Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: user.isActive ? Colors.green.shade200 : Colors.grey.shade300)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.circle, size: 8, color: user.isActive ? Colors.green.shade600 : Colors.grey.shade500), const SizedBox(width: 6),
                              Text(user.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: user.isActive ? Colors.green.shade700 : Colors.grey.shade600)),
                            ]),
                          ),
                        )),
                        SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, size: 18), color: Colors.blueGrey, onPressed: () => _showUserDialog(existing: user)),
                          IconButton(icon: const Icon(Icons.delete_outline, size: 18), color: Colors.red.shade400, onPressed: () => setState(() => _users.remove(user))),
                        ])),
                      ]),
                    );
                  }).toList(),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _dialogField(TextEditingController ctrl, String label, String hint, {bool obscure = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF495057))),
      const SizedBox(height: 6),
      TextField(controller: ctrl, obscureText: obscure, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400), filled: true, fillColor: const Color(0xFFF8F9FA), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none))),
    ]);
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4)]),
      child: Row(children: [
        Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ]),
      ]),
    ));
  }
}