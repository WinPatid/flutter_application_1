# NODE ASSIST PRO
### Enterprise Network Provisioning & Reservation System

> Developer Handoff & Architecture Guide — v1.0.0 | April 2026

---

## 1. Project Overview

ระบบจัดการ Network Node สำหรับทีม NOC ใช้ในการ:

- ค้นหาและ Reserve LSW Access / Network Node
- จัดการ Domain และ IP Address (subnet-based)
- จัดการ Switch Model และ Port Templates
- Bulk Import connection จาก CSV
- แสดง Network Topology Diagram ก่อน Confirm

---

## 2. Tech Stack

| Layer | Technology | Version | หมายเหตุ |
|-------|-----------|---------|----------|
| Frontend | Flutter | 3.x | Web app (`--release -d chrome`) |
| Backend | FastAPI | 0.100+ | Python 3.14 |
| Database | PostgreSQL | 14+ | Schema มีอยู่แล้ว |
| ORM | SQLAlchemy | 2.x | Declarative Base |
| HTTP (Dart) | http | latest | ใช้ใน `api_service.dart` |
| SVG | flutter_svg | ^2.0.0 | Logo rendering |
| CSV Parse | csv | ^6.0.0 | Bulk Import |
| File Pick | file_picker | ^8.0.0 | Bulk Import upload |

---

## 3. Folder Structure

### Frontend (Flutter)

```
lib/
├── main.dart
├── core/
│   └── theme.dart              # AppColors, AppTextStyles, AppButtonStyles, AppWidgets
├── services/
│   └── api_service.dart        # HTTP client ทุก endpoint
├── models/
│   └── node_model.dart
├── screens/
│   ├── login_screen.dart
│   ├── node_assist_screen.dart  # Main screen + Search & Reserve (Phase 1 & 2)
│   ├── bulk_import_screen.dart
│   ├── domain_screen.dart       # 3-panel: Domain → Subnet → IP
│   └── model_screen.dart        # 2-panel: Model → Port Templates
└── widgets/
    ├── search_field.dart
    ├── dropdown_field.dart
    ├── network_table.dart        # Phase 2 table (lazy port loading)
    ├── topology_diagram.dart     # Confirm dialog
    ├── common/
    │   ├── status_badge.dart
    │   ├── mini_chip.dart
    │   ├── app_card.dart
    │   ├── empty_hint.dart
    │   ├── table_header_row.dart
    │   ├── form_field_wrapper.dart
    │   └── panel_container.dart
    ├── sidebar/
    │   ├── app_sidebar.dart      # Sidebar + logo
    │   ├── sidebar_item.dart
    │   └── top_bar.dart
    └── dashboard/
        └── node_data_table.dart

assets/
└── images/
    └── logo.svg
```

### Backend (FastAPI)

```
app/
├── main.py                     # FastAPI app + CORS + router registration
├── database/
│   └── database.py             # SQLAlchemy engine + get_db()
├── models/
│   └── models.py               # ORM models ทุก table
├── schemas/
│   └── schemas.py              # Pydantic schemas (In/Out)
└── routers/
    ├── nodes.py                # access-nodes, network-nodes, models, sites
    ├── interfaces.py           # access/network interfaces + switches
    ├── domains.py              # domains, IPs, bulk IP insert/delete
    └── connect.py              # connections, bulk-import, topology
```

---

## 4. Database Schema

> Database: `network_db` (PostgreSQL) — มีอยู่แล้ว ไม่ต้อง `create_all`

| Table | คำอธิบาย | FK หลัก |
|-------|---------|---------|
| `LSW_Access` | LSW Access Node | — |
| `LSW_Network` | LSW Network Node | — |
| `SwitchAc` | Switch ฝั่ง Access | `model.Model_Id` |
| `SwitchNw` | Switch ฝั่ง Network | `model.Model_Id`, `site.Location_ID` |
| `InterfacesAc` | Port ฝั่ง Access | `SwitchAc`, `ModelInterfaces` |
| `InterfacesNw` | Port ฝั่ง Network | `SwitchNw`, `ModelInterfaces` |
| `NodeAc_Interface` | Junction: Access Node ↔ Port ↔ IP | `LSW_Access`, `InterfacesAc`, `ip` |
| `NodeNw_Interface` | Junction: Network Node ↔ Port ↔ IP | `LSW_Network`, `InterfacesNw`, `ip` |
| `Connect` | Connection reservation | `NodeAc_Interface`, `NodeNw_Interface` |
| `Domain` | IP Domain / VLAN group | — |
| `ip` | IP Address (**type: `inet`**) | `Domain` |
| `model` | Switch Model | — |
| `ModelInterfaces` | Port Template ของ Model | `model` |
| `site` | Site Location | — |
| `pe` | PE Router | `site` |

> ⚠️ **สำคัญ:** column `"IP"` ใน table `ip` เป็น type **`inet`** ไม่ใช่ `varchar`
> ต้องใช้ `cast(:ip AS inet)` เวลา INSERT ด้วย raw SQL

---

## 5. API Endpoints

Base URL: `http://localhost:8000/api/v1`

### Nodes

| Method | Path | คำอธิบาย |
|--------|------|---------|
| GET | `/access-nodes` | ดึง LSW Access Nodes (`?search=`) |
| GET | `/network-nodes` | ดึง LSW Network Nodes (`?search=`, `?site_code=`) |
| GET | `/network-nodes/{id}/ports` | ดึง ports ทั้งหมดของ SwitchNw ที่ node link อยู่ |
| GET | `/network-nodes/{id}/site` | Auto-fill site name |
| GET/POST/PUT/DELETE | `/models` | CRUD Switch Models |
| GET/POST/PUT/DELETE | `/model-interfaces` | CRUD Port Templates |
| GET | `/sites` | ดึง Sites ทั้งหมด |

### Domains & IPs

| Method | Path | คำอธิบาย |
|--------|------|---------|
| GET/POST/PUT/DELETE | `/domains` | CRUD Domains |
| GET | `/domains/{id}/ips` | ดึง IPs ใน Domain |
| GET | `/domains/{id}/ips-status` | ดึง IPs พร้อม `in_use` flag |
| POST | `/domains/{id}/ips` | เพิ่ม IP เดี่ยว |
| POST | `/domains/{id}/ips/bulk` | Gen IP ทั้งวง `{ subnet, prefix }` |
| DELETE | `/domains/{id}/ips/subnet` | ลบ IP ทั้ง subnet (`?subnet=10.98.4`) — ลบได้เฉพาะถ้าทุก IP ว่าง |
| PUT/DELETE | `/ips/{id}` | แก้ไข / ลบ IP เดี่ยว |

### Connections

| Method | Path | คำอธิบาย |
|--------|------|---------|
| POST | `/connections` | สร้าง Connection |
| GET | `/connections` | ดึง Connections (`?status=planned/active`) |
| GET | `/connections/{id}/topology` | Topology summary สำหรับ diagram |
| PATCH | `/connections/{id}/activate` | เปลี่ยน status → active |
| DELETE | `/connections/{id}` | ลบ + คืน port กลับเป็น available |
| POST | `/connections/bulk-import` | Bulk import จาก array of rows |

#### Bulk Import Row Schema
```json
{
  "row": 1,
  "node_ac_id": 88860,
  "domain": "BKK-MPLS",
  "ip_access": "10.98.4.200",
  "model": "C2960-24TC",
  "port_access": "GigabitEthernet0/1",
  "site_code": "BCH-5012-UR",
  "node_nw_id": 12345,
  "ip_network": "10.98.5.1",
  "port_network": "GigabitEthernet0/2",
  "cid": "CID-2024-001",
  "status": "planned"
}
```

---

## 6. Frontend Flow — Search & Reserve

### Phase 1 — LSW Access
1. Search Node ID / Node Name
2. Select Area Group (BKK / UPC)
3. Select Domain → โหลด IP list อัตโนมัติ (แสดงในรูป `10.98.4.1/24`)
4. Search IP Assist → เก็บแค่ IP address (ตัด `/prefix` ออก) ตอน onSelected
5. Select Model → โหลด Port Templates จาก `ModelInterfaces`
6. Select Switch Port จาก Template

### Phase 2 — LSW Network
1. Search Site Code → `_loadNetworkNodesBySite()` — ดึงเฉพาะ nodes ใน site นั้น
2. `NetworkSelectionTable` แสดง rows — ports โหลด **lazy** ทีละ row ผ่าน `addPostFrameCallback`
3. Port ดึงจาก `GET /network-nodes/{id}/ports`:
   - หา `SwitchNw_ID` จาก `NodeNwInterface → InterfacesNw`
   - ดึง `InterfacesNw` **ทั้งหมด** ของ switch นั้น (ได้ทั้ง available + in_use)
4. กด **เลือก** → `onShowDiagram()` → `TopologyDiagram` dialog
5. กด **Confirm Configuration** → `POST /connections`

---

## 7. Known Issues & Technical Debt

| # | Issue | Location | Priority |
|---|-------|----------|----------|
| 1 | Login hardcode `admin/admin` — ต้องเชื่อม API auth จริง | `login_screen.dart` | 🔴 High |
| 2 | Dashboard ใช้ mock data — ต้องดึงจาก `access-nodes` จริง | `node_data_table.dart` | 🔴 High |
| 3 | NodeID badge ว่าง/ไม่ว่าง ใช้ `% 2` mock | `node_assist_screen.dart` | 🟡 Medium |
| 4 | `access_switch_id` และ `access_port_id` ส่ง `0` เสมอ | `topology_diagram.dart` | 🟡 Medium |
| 5 | `network_switch_id` ไม่มี validate ก่อน insert | `connect.py` | 🟡 Medium |
| 6 | Topology Map page ยังเป็น placeholder | `node_assist_screen.dart` | 🟢 Low |
| 7 | `database.py` fallback มี password hardcode | `database.py` | 🟢 Low |

---

## 8. Setup & Run

### Backend
```powershell
cd app
pip install fastapi uvicorn sqlalchemy psycopg2-binary
$env:DATABASE_URL = "postgresql://postgres:yourpass@localhost:5432/network_db"
python -m uvicorn main:app --reload
```

### Frontend
```powershell
cd flutter_application_1
flutter pub get
flutter run -d chrome
```

> ⚠️ **Device Guard:** หากรันไม่ได้บนเครื่ององค์กร ให้แจ้ง IT whitelist `C:\T\flutter\`

### pubspec.yaml
```yaml
dependencies:
  flutter_svg: ^2.0.0
  file_picker: ^8.0.0
  csv: ^6.0.0

flutter:
  assets:
    - assets/images/logo.svg
```

---

## 9. Environment Variables

| Variable | Default | คำอธิบาย |
|----------|---------|---------|
| `DATABASE_URL` | `postgresql://postgres:020846@localhost:5432/network_db` | PostgreSQL connection string |
| `BASE_URL` (Dart) | `http://localhost:8000/api/v1` | แก้ใน `api_service.dart` บรรทัดแรก |

---

## 10. Suggested Next Steps

- [ ] แก้ Login ให้เชื่อมต่อ API auth จริง (JWT / session)
- [ ] แก้ Dashboard ให้ดึงข้อมูลจาก `access-nodes` API แทน mock data
- [ ] เพิ่ม error handling / loading state ที่สมบูรณ์ใน `api_service.dart`
- [ ] Implement Topology Map page จริง
- [ ] เพิ่ม pagination ใน `NetworkSelectionTable`
- [ ] Unit tests สำหรับ backend routers

---

*Node Assist PRO v1.0.0 — April 2026*