import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/user_admin_service.dart';
import '../services/exam_service.dart';
import '../models/user_model.dart';
import '../models/exam_model.dart';

class DashboardOverviewScreen extends StatelessWidget {
  const DashboardOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserAdminService();
    final examService = ExamService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TỔNG QUAN HỆ THỐNG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            
            // --- THẺ THỐNG KÊ NHANH ---
            StreamBuilder<List<UserModel>>(
              stream: userService.getAllUsers(),
              builder: (context, userSnapshot) {
                return StreamBuilder<List<ToeicExam>>(
                  stream: examService.getExams(),
                  builder: (context, examSnapshot) {
                    final userCount = userSnapshot.data?.length ?? 0;
                    final examCount = examSnapshot.data?.length ?? 0;
                    final activeUsers = userSnapshot.data?.where((u) => u.currentStreak > 0).length ?? 0;
                    
                    // --- TÍNH TOÁN TÀI NGUYÊN (ƯỚC TÍNH) ---
                    // Mỗi đề thi trung bình 5MB (ảnh + audio)
                    final double estStorage = (examCount * 5.2); 
                    // Mỗi user active trung bình tốn 15MB băng thông/tháng
                    final double estBandwidth = (activeUsers * 15.0) + (userCount * 0.5);

                    return GridView.count(
                      crossAxisCount: 3, // Chuyển sang 3 cột để nhìn rõ hơn
                      shrinkWrap: true,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 2.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard('Người dùng', userCount.toString(), Icons.people_rounded, Colors.blue),
                        _buildStatCard('Đề thi', examCount.toString(), Icons.assignment_rounded, Colors.orange),
                        _buildStatCard('Đang học', activeUsers.toString(), Icons.local_fire_department_rounded, Colors.redAccent),
                        _buildStatCard('Tỉ lệ Active', userCount == 0 ? '0%' : '${((activeUsers / userCount) * 100).toStringAsFixed(1)}%', Icons.analytics_rounded, Colors.greenAccent),
                        _buildStatCard('Lưu trữ (Est)', '${estStorage.toStringAsFixed(1)} MB', Icons.cloud_done_rounded, Colors.purpleAccent),
                        _buildStatCard('Băng thông / tháng', '${estBandwidth.toStringAsFixed(0)} MB', Icons.speed_rounded, Colors.indigoAccent),
                      ],
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // --- BIỂU ĐỒ VÀ BẢNG XẾP HẠNG ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Biểu đồ phân bố Streak (Thu nhỏ lại)
                Expanded(
                  child: Container(
                    height: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PHÂN BỐ STREAK', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        Expanded(
                          child: StreamBuilder<List<UserModel>>(
                            stream: userService.getAllUsers(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              return _buildStreakChart(snapshot.data!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // BẢNG XẾP HẠNG CAO THỦ (TOP LEARNERS)
                Expanded(
                  child: Container(
                    height: 380,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BẢNG XẾP HẠNG CAO THỦ', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                            const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: StreamBuilder<List<UserModel>>(
                            stream: userService.getAllUsers(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                              
                              // Sắp xếp người dùng theo điểm cao nhất
                              final sortedUsers = snapshot.data!..sort((a, b) {
                                final aMax = a.scores.isEmpty ? 0 : a.scores.map((s) => s.listeningScore + s.readingScore).reduce((curr, next) => curr > next ? curr : next);
                                final bMax = b.scores.isEmpty ? 0 : b.scores.map((s) => s.listeningScore + s.readingScore).reduce((curr, next) => curr > next ? curr : next);
                                return bMax.compareTo(aMax);
                              });

                              final topUsers = sortedUsers.take(5).toList();

                              return ListView.builder(
                                itemCount: topUsers.length,
                                itemBuilder: (context, index) {
                                  final user = topUsers[index];
                                  final maxScore = user.scores.isEmpty ? 0 : user.scores.map((s) => s.listeningScore + s.readingScore).reduce((curr, next) => curr > next ? curr : next);
                                  return _buildLeaderboardTile(user, index + 1, maxScore);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14), overflow: TextOverflow.ellipsis),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(UserModel user, int rank, int score) {
    Color rankColor = Colors.grey;
    if (rank == 1) rankColor = Colors.amber;
    if (rank == 2) rankColor = Colors.blueGrey;
    if (rank == 3) rankColor = Colors.brown;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 30,
            alignment: Alignment.center,
            child: Text(
              rank.toString(),
              style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.indigoAccent.withOpacity(0.1),
            backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) ? NetworkImage(user.avatarUrl!) : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty) ? Text(user.name[0], style: const TextStyle(color: Colors.indigoAccent)) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Streak: ${user.currentStreak} ngày', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            score.toString(),
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakChart(List<UserModel> users) {
    double zero = users.where((u) => u.currentStreak == 0).length.toDouble();
    double small = users.where((u) => u.currentStreak >= 1 && u.currentStreak <= 3).length.toDouble();
    double medium = users.where((u) => u.currentStreak > 3 && u.currentStreak <= 7).length.toDouble();
    double large = users.where((u) => u.currentStreak > 7).length.toDouble();

    double maxVal = [zero, small, medium, large].reduce((a, b) => a > b ? a : b);
    double maxY = maxVal == 0 ? 10 : maxVal * 1.2;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['0 Day', '1-3 Day', '3-7 Day', '7+ Day'];
                if (value.toInt() >= titles.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(titles[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          _buildBarGroup(0, zero, Colors.grey, maxY),
          _buildBarGroup(1, small, Colors.blue, maxY),
          _buildBarGroup(2, medium, Colors.indigo, maxY),
          _buildBarGroup(3, large, Colors.orange, maxY),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 30,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: const Color(0xFF334155).withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
