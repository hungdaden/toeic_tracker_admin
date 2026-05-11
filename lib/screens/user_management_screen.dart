import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../services/user_admin_service.dart';
import '../widgets/dynamic_island_notification.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserAdminService();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quản lý người dùng',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Theo dõi hoạt động và quản lý tài khoản người viên',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: userService.getAllUsers(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final users = snapshot.data ?? [];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 24,
                          columns: const [
                            DataColumn(label: Text('Người dùng', style: TextStyle(color: Colors.indigoAccent))),
                            DataColumn(label: Text('Streak', style: TextStyle(color: Colors.indigoAccent))),
                            DataColumn(label: Text('Mục tiêu', style: TextStyle(color: Colors.indigoAccent))),
                            DataColumn(label: Text('Nhóm', style: TextStyle(color: Colors.indigoAccent))),
                            DataColumn(label: Text('Trạng thái', style: TextStyle(color: Colors.indigoAccent))),
                            DataColumn(label: Text('Hành động', style: TextStyle(color: Colors.indigoAccent))),
                          ],
                          rows: users.map((user) => DataRow(
                            cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                                    child: user.avatarUrl == null ? Text(user.name[0]) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                      Text(user.id, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ],
                              )),
                              DataCell(Row(
                                children: [
                                  const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 18),
                                  const SizedBox(width: 4),
                                  Text('${user.currentStreak} ngày', style: const TextStyle(color: Colors.white)),
                                ],
                              )),
                              DataCell(Text('${user.targetScore}', style: const TextStyle(color: Colors.white))),
                              DataCell(Text(user.groupId ?? 'Chưa vào nhóm', style: TextStyle(color: user.groupId != null ? Colors.blue : Colors.grey))),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.isDisabled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.isDisabled ? 'Bị khóa' : 'Hoạt động',
                                  style: TextStyle(color: user.isDisabled ? Colors.red : Colors.green, fontSize: 12),
                                ),
                              )),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    icon: Icon(user.isDisabled ? Icons.lock_open_rounded : Icons.lock_outline_rounded, size: 20),
                                    color: user.isDisabled ? Colors.green : Colors.redAccent,
                                    onPressed: () async {
                                      try {
                                        await userService.toggleUserStatus(user.id, !user.isDisabled);
                                        if (context.mounted) {
                                          DynamicIslandNotification.show(
                                            context,
                                            title: user.isDisabled ? 'Đã mở khóa' : 'Đã khóa',
                                            message: user.isDisabled ? 'Tài khoản ${user.name} đã hoạt động trở lại.' : 'Học viên ${user.name} đã bị chặn truy cập.',
                                            type: user.isDisabled ? NotificationType.success : NotificationType.warning,
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          String errorMsg = e.toString();
                                          if (e is FirebaseException) {
                                            errorMsg = 'Lỗi hệ thống: ${e.message}';
                                          }
                                          DynamicIslandNotification.show(
                                            context,
                                            title: 'Lỗi thực thi',
                                            message: errorMsg,
                                            type: NotificationType.error,
                                          );
                                        }
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.analytics_outlined, size: 20, color: Colors.blue),
                                    onPressed: () {
                                      // Xem chi tiết lịch sử thi
                                    },
                                  ),
                                ],
                              )),
                            ],
                          )).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
