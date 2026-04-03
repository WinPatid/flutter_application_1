// ไฟล์: lib/screens/model_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/theme.dart';

class ModelScreen extends StatefulWidget {
  const ModelScreen({super.key});

  @override
  State<ModelScreen> createState() => _ModelScreenState();
}

class _ModelScreenState extends State<ModelScreen> {
  final _api = ApiService();

  List<Map<String, dynamic>> _models    = [];
  List<Map<String, dynamic>> _templates = [];
  Map<String, dynamic>? _selectedModel;
  bool _loadingModels    = false;
  bool _loadingTemplates = false;

  @override
  void initState() {
    super.initState();
    _fetchModels();
  }

  // ════════════════════════════════════════════
  //  DATA
  // ════════════════════════════════════════════

  Future<void> _fetchModels() async {
    setState(() => _loadingModels = true);
    final data = await _api.fetchModels();
    setState(() { _models = data; _loadingModels = false; });
  }

  Future<void> _fetchTemplates(int modelId) async {
    setState(() => _loadingTemplates = true);
    final data = await _api.fetchModelInterfaces(modelId: modelId);
    setState(() { _templates = data; _loadingTemplates = false; });
  }

  void _selectModel(Map<String, dynamic> model) {
    setState(() { _selectedModel = model; _templates = []; });
    _fetchTemplates(model['Model_Id'] as int);
  }

  // ════════════════════════════════════════════
  //  MODEL DIALOGS
  // ════════════════════════════════════════════

  void _showModelDialog({Map<String, dynamic>? existing}) {
    final nameCtrl = TextEditingController(text: existing?['Model_Name'] ?? '');
    final typeCtrl = TextEditingController(text: existing?['Model_type'] ?? '');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add Model' : 'Edit Model',
        style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 360, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTextField(nameCtrl, 'Model Name', 'e.g., C2960-24TC'),
        const SizedBox(height: 16),
        _buildTextField(typeCtrl, 'Model Type', 'e.g., access, network, core'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) { _showSnack('กรอกชื่อ Model ด้วย', Colors.orange); return; }
            Navigator.pop(ctx);
            final type = typeCtrl.text.trim().isEmpty ? null : typeCtrl.text.trim();
            if (existing == null) {
              await _api.createModel(nameCtrl.text.trim(), type);
            } else {
              await _api.updateModel(existing['Model_Id'] as int, nameCtrl.text.trim(), type);
            }
            _fetchModels();
          },
          child: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    ));
  }

  void _confirmDeleteModel(Map<String, dynamic> model) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Model', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ "${model['Model_Name']}" ออกไหม?\nต้องไม่มี Port Template อยู่ใน Model นี้'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _api.deleteModel(model['Model_Id'] as int);
            if (ok) {
              if (_selectedModel?['Model_Id'] == model['Model_Id']) {
                setState(() { _selectedModel = null; _templates = []; });
              }
              _fetchModels();
            } else {
              _showSnack('ลบไม่ได้ — มี Port Template อยู่ใน Model นี้', Colors.red);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  // ════════════════════════════════════════════
  //  TEMPLATE DIALOGS
  // ════════════════════════════════════════════

  void _showTemplateDialog({Map<String, dynamic>? existing}) {
    final nameCtrl  = TextEditingController(text: existing?['Interface_Name'] ?? '');
    final typeCtrl  = TextEditingController(text: existing?['Interface_Type'] ?? '');
    final speedCtrl = TextEditingController(text: existing?['speed'] ?? '');
    final cableCtrl = TextEditingController(text: existing?['cable_type'] ?? '');

    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(existing == null ? 'Add Port Template' : 'Edit Port Template',
        style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
        _buildTextField(nameCtrl, 'Interface Name *', 'e.g., GigabitEthernet0/1'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTextField(typeCtrl, 'Interface Type', 'e.g., GE, FE')),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField(speedCtrl, 'Speed', 'e.g., 1G, 100M')),
        ]),
        const SizedBox(height: 12),
        _buildTextField(cableCtrl, 'Cable Type', 'e.g., UTP, SFP'),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) { _showSnack('กรอกชื่อ Interface ด้วย', Colors.orange); return; }
            Navigator.pop(ctx);
            if (existing == null) {
              await _api.createModelInterface(
                _selectedModel!['Model_Id'] as int,
                nameCtrl.text.trim(),
                typeCtrl.text.trim().isEmpty  ? null : typeCtrl.text.trim(),
                speedCtrl.text.trim().isEmpty ? null : speedCtrl.text.trim(),
                cableCtrl.text.trim().isEmpty ? null : cableCtrl.text.trim(),
              );
            } else {
              await _api.updateModelInterface(
                existing['Template_ID'] as int,
                nameCtrl.text.trim(),
                typeCtrl.text.trim().isEmpty  ? null : typeCtrl.text.trim(),
                speedCtrl.text.trim().isEmpty ? null : speedCtrl.text.trim(),
                cableCtrl.text.trim().isEmpty ? null : cableCtrl.text.trim(),
              );
            }
            _fetchTemplates(_selectedModel!['Model_Id'] as int);
          },
          child: Text(existing == null ? 'Add' : 'Save'),
        ),
      ],
    ));
  }

  void _confirmDeleteTemplate(Map<String, dynamic> tmpl) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete Port Template', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('ลบ "${tmpl['Interface_Name']}" ออกไหม?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            final ok = await _api.deleteModelInterface(tmpl['Template_ID'] as int);
            if (ok) {
              _fetchTemplates(_selectedModel!['Model_Id'] as int);
            } else {
              _showSnack('ลบไม่สำเร็จ', Colors.red);
            }
          },
          child: const Text('Delete'),
        ),
      ],
    ));
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ─── Panel 1: Model list ───
        SizedBox(width: 300, child: _buildPanel(
          title: 'Switch Models',
          onAdd: () => _showModelDialog(),
          addLabel: 'Add Model',
          addColor: AppColors.primary,
          child: _loadingModels
            ? const Center(child: CircularProgressIndicator())
            : _models.isEmpty
              ? _emptyHint('ยังไม่มี Model')
              : ListView.separated(
                  itemCount: _models.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (_, i) {
                    final m = _models[i];
                    final isSelected = _selectedModel?['Model_Id'] == m['Model_Id'];
                    return InkWell(
                      onTap: () => _selectModel(m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m['Model_Name'].toString(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                                color: isSelected ? AppColors.primary : Colors.black87)),
                            const SizedBox(height: 4),
                            if (m['Model_type'] != null)
                              _typeBadge(m['Model_type'].toString()),
                          ])),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit')   _showModelDialog(existing: m);
                              if (v == 'delete') _confirmDeleteModel(m);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit',   child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                            child: Icon(Icons.more_vert, size: 18, color: Colors.grey.shade400),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
        )),

        const SizedBox(width: 24),

        // ─── Panel 2: Port Templates ───
        Expanded(child: _buildPanel(
          title: _selectedModel != null
            ? 'Port Templates — ${_selectedModel!['Model_Name']}'
            : 'Port Templates',
          onAdd: _selectedModel != null ? () => _showTemplateDialog() : null,
          addLabel: '+ Add Port',
          addColor: AppColors.success,
          child: _selectedModel == null
            ? _emptyHint('เลือก Model เพื่อดู Port Templates')
            : _loadingTemplates
              ? const Center(child: CircularProgressIndicator())
              : _templates.isEmpty
                ? _emptyHint('ยังไม่มี Port Template ใน Model นี้')
                : Column(children: [
                    // header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8))),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text('INTERFACE NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('TYPE',           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('SPEED',          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        Expanded(flex: 2, child: Text('CABLE',          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey.shade600))),
                        const SizedBox(width: 80),
                      ]),
                    ),
                    Expanded(child: ListView.separated(
                      itemCount: _templates.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (_, i) {
                        final t = _templates[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(t['Interface_Name']?.toString() ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                            Expanded(flex: 2, child: Text(t['Interface_Type']?.toString() ?? '-',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            Expanded(flex: 2, child: Text(t['speed']?.toString() ?? '-',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            Expanded(flex: 2, child: Text(t['cable_type']?.toString() ?? '-',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600))),
                            SizedBox(width: 80, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16), color: Colors.blueGrey,
                                tooltip: 'Edit', onPressed: () => _showTemplateDialog(existing: t)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 16), color: Colors.red.shade400,
                                tooltip: 'Delete', onPressed: () => _confirmDeleteTemplate(t)),
                            ])),
                          ]),
                        );
                      },
                    )),
                  ]),
        )),
      ]),
    );
  }

  // ════════════════════════════════════════════
  //  HELPER WIDGETS
  // ════════════════════════════════════════════

  Widget _buildPanel({required String title, VoidCallback? onAdd,
      String addLabel = 'Add', Color addColor = AppColors.primary, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis)),
        if (onAdd != null) ...[
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(backgroundColor: addColor, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: const Size(0, 32),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            child: Text(addLabel),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Expanded(child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
      )),
    ]);
  }

  Widget _emptyHint(String text) {
    return Center(child: Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)));
  }

  Widget _typeBadge(String type) {
    final isAccess = type == 'access';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAccess ? Colors.teal.shade50 : Colors.purple.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isAccess ? Colors.teal.shade200 : Colors.purple.shade200)),
      child: Text(type, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
        color: isAccess ? Colors.teal.shade700 : Colors.purple.shade700)),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true, fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        ),
      ),
    ]);
  }
}