import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tikwei_assignment/modules/admin/user_detail_page.dart';
import '../../core/admin_navigation.dart';
import '../../services/user_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await UserService.fetchAllUsers();

      setState(() {
        _users = users;
        _filteredUsers = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();

    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['user_name'] ?? '').toLowerCase();
        final email = (user['user_email'] ?? '').toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    Future<bool?> showConfirmDialog({
      required BuildContext context,
      required String title,
      required String message,
    }) {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                  'Confirm',
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Color(0xFF93DA97),
      ),
      drawer: const AdminDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: SafeArea(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hint: Text('Search'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  controller: _searchCtrl,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      headingRowHeight: 50,
                      dataRowHeight: 56,
                      headingRowColor: MaterialStateProperty.all(
                        Color(0xFF93DA97),
                      ),
                      columns: const[
                        DataColumn(
                          label: Text(
                            'No',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Name',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Email',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Gender',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Action',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                        rows: List.generate(_filteredUsers.length, (index) {
                          final user = _filteredUsers[index];
                          final bool isActive = user['user_status'] == true;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              DataCell(Text(user['user_name'] ?? '-')),
                              DataCell(Text(user['user_email'] ?? '-')),
                              DataCell(Text(user['user_gender'] ?? '-')),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Blocked',
                                    style: TextStyle(
                                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        isActive ? Icons.block : Icons.check_circle,
                                        color: isActive ? Colors.red : Colors.green,
                                      ),
                                      tooltip: isActive ? 'Block user' : 'Activate user',
                                      onPressed: () async {
                                        final confirmed = await showConfirmDialog(
                                          context: context,
                                          title: isActive ? 'Block User' : 'Activate User',
                                          message: isActive
                                              ? 'Are you sure you want to block this user?\n\n${user['user_email']}'
                                              : 'Are you sure you want to activate this user?\n\n${user['user_email']}',
                                        );

                                        if (confirmed != true) return;

                                        await UserService.updateUserStatus(
                                          email: user['user_email'],
                                          newStatus: !isActive,
                                        );

                                        _fetchUsers();
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.visibility),
                                      tooltip: 'View details',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (BuildContext context) => UserDetailPage()),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }),
                    ),
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
