// ไฟล์: lib/widgets/dashboard/node_data_table.dart
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

class NodeDataTable extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelect;
  const NodeDataTable({super.key, required this.onSelect});

  @override
  State<NodeDataTable> createState() => _NodeDataTableState();
}

class _NodeDataTableState extends State<NodeDataTable> {
  final _api        = ApiService();
  final _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _nodes = [];
  int?   _firstAvailableIdx;
  bool   _loading    = true;
  String _searchId   = '';
  String _searchName = '';

  // GlobalKey สำหรับแต่ละ row เพื่อ scroll ไปถึง
  final List<GlobalKey> _rowKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final data = await _api.fetchDashboardNodes();
    final nodes = List<Map<String, dynamic>>.from(data['nodes'] ?? []);
    final idx   = data['first_available_idx'] as int?;

    setState(() {
      _nodes             = nodes;
      _firstAvailableIdx = idx;
      _loading           = false;
      _rowKeys
        ..clear()
        ..addAll(List.generate(nodes.length, (_) => GlobalKey()));
    });

    // auto scroll ไป available row แรก หลัง build เสร็จ
    if (idx != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToAvailable());
    }
  }

  void _scrollToAvailable() {
    if (_firstAvailableIdx == null) return;
    final idx = _firstAvailableIdx!;
    if (idx >= _rowKeys.length) return;
    final key = _rowKeys[idx];
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3); // เลื่อนให้แถวว่างอยู่บน 30%
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_searchId.isEmpty && _searchName.isEmpty) return _nodes;
    return _nodes.where((row) {
      final matchId   = row['id'].toString().contains(_searchId);
      final matchName = row['name'].toString().toLowerCase()
          .contains(_searchName.toLowerCase());
      return matchId && matchName;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: [

          // ─── Search + controls ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(children: [
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _searchId = v),
                decoration: AppInputDecoration.search(hint: 'Search ID...'),
              )),
              const SizedBox(width: 12),
              Expanded(child: TextField(
                onChanged: (v) => setState(() => _searchName = v),
                decoration: AppInputDecoration.search(hint: 'Search Name...'),
              )),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                color: AppColors.primary,
                tooltip: 'Refresh',
                onPressed: _fetchData,
              ),
              if (_firstAvailableIdx != null)
                Tooltip(
                  message: 'ไปยัง Node ว่าง',
                  child: IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    color: AppColors.success,
                    onPressed: _scrollToAvailable,
                  ),
                ),
            ]),
          ),
          const Divider(height: 1),

          // ─── Table header ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surface,
            child: Row(children: [
              Expanded(flex: 2, child: Text('NODE ID',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 3, child: Text('NODE NAME',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 2, child: Text('AC IP',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 3, child: Text('NW NODE',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 2, child: Text('NW IP',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 2, child: Text('CID',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              Expanded(flex: 2, child: Text('STATUS',
                style: AppTextStyles.tableHeader.copyWith(color: Colors.grey.shade600))),
              const SizedBox(width: 72),
            ]),
          ),
          const Divider(height: 1),

          // ─── Rows ───
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator())
              : rows.isEmpty
                ? Center(child: Text('ไม่พบข้อมูล',
                    style: TextStyle(color: Colors.grey.shade400)))
                : ListView.builder(
                    controller: _scrollCtrl,
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final node        = rows[i];
                      final isAvailable = node['isAvailable'] as bool;
                      // หา globalKey จาก _nodes (ไม่ใช่ filtered)
                      final realIdx = _nodes.indexOf(node);
                      final key = realIdx >= 0 && realIdx < _rowKeys.length
                          ? _rowKeys[realIdx] : null;

                      return _buildRow(node,
                        isAvailable: isAvailable,
                        rowKey: key);
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> node, {
    required bool isAvailable,
    Key? rowKey,
  }) {
    return Container(
      key: rowKey,
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.success.withOpacity(0.04) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100))),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(children: [
        Expanded(flex: 2, child: Text(node['id'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Expanded(flex: 3, child: Text(node['name'],
          style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
        // AC IP
        Expanded(flex: 2, child: Text(
          node['ac_ip']?.toString() ?? '-',
          style: AppTextStyles.bodySmall.copyWith(
            color: node['ac_ip'] != null ? AppColors.info : Colors.grey.shade400))),
        // NW Node
        Expanded(flex: 3, child: node['nw_node_name'] != null
          ? Text(node['nw_node_name'].toString(),
              style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)
          : Text('-', style: TextStyle(color: Colors.grey.shade400, fontSize: 12))),
        // NW IP
        Expanded(flex: 2, child: Text(
          node['nw_ip']?.toString() ?? '-',
          style: AppTextStyles.bodySmall.copyWith(
            color: node['nw_ip'] != null ? AppColors.success : Colors.grey.shade400))),
        // CID
        Expanded(flex: 2, child: Text(
          node['cid']?.toString() ?? '-',
          style: AppTextStyles.bodySmall.copyWith(
            color: node['cid'] != null ? AppColors.textPrimary : Colors.grey.shade400),
          overflow: TextOverflow.ellipsis)),
        // Status badge
        Expanded(flex: 2, child: node['conn_status'] != null
          ? _connStatusBadge(node['conn_status'].toString())
          : _statusBadge(isAvailable)),
        SizedBox(width: 72, child: isAvailable
          ? ElevatedButton(
              onPressed: () => widget.onSelect(node),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: const Size(0, 30),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
              child: const Text('เลือก'),
            )
          : const SizedBox.shrink()),
      ]),
    );
  }

  Widget _connStatusBadge(String status) {
    Color bg, border, fg;
    switch (status.toLowerCase()) {
      case 'planned':
        bg = const Color(0xFFFEF9E7); border = const Color(0xFFF39C12);
        fg = const Color(0xFFB7770D); break;
      case 'active':
        bg = AppColors.availableBg; border = AppColors.availableBorder;
        fg = AppColors.availableText; break;
      case 'inactive':
        bg = AppColors.inUseBg; border = AppColors.inUseBorder;
        fg = AppColors.inUseText; break;
      default:
        bg = Colors.grey.shade100; border = Colors.grey.shade300;
        fg = Colors.grey.shade600;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border)),
      child: Text(status, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold, color: fg)));
  }

  Widget _statusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.availableBg : AppColors.inUseBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAvailable ? AppColors.availableBorder : AppColors.inUseBorder)),
      child: Text(isAvailable ? 'Available' : 'In Use',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
          color: isAvailable ? AppColors.availableText : AppColors.inUseText)),
    );
  }
}