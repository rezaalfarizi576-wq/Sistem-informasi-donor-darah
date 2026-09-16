import 'package:flutter/material.dart';

class DonationHistoryScreen extends StatelessWidget {
  const DonationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Riwayat dummy donor
    final dummyHistory = [
      {
        'date': '15 Januari 2024',
        'location': 'UDD PMI Kabupaten Lamongan',
        'type': 'Donor Darah Biasa (Whole Blood)',
        'bags': '1 Kantong (350 ml)',
        'status': 'Berhasil',
      },
      {
        'date': '10 Oktober 2023',
        'location': 'Mobile Unit Alun-Alun Lamongan',
        'type': 'Donor Darah Biasa (Whole Blood)',
        'bags': '1 Kantong (350 ml)',
        'status': 'Berhasil',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Donor Darah'),
      ),
      body: Column(
        children: [
          // Info Kelayakan Donor Selanjutnya
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Donor Anda:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Siap & Memenuhi Syarat Donor',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Jarak minimal 60 hari sejak donor terakhir telah terpenuhi.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: dummyHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = dummyHistory[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD32F2F),
                      child: Icon(Icons.bloodtype, color: Colors.white),
                    ),
                    title: Text(item['location']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Tanggal: ${item['date']}'),
                        Text('${item['type']} - ${item['bags']}'),
                      ],
                    ),
                    trailing: Chip(
                      label: Text(item['status']!, style: const TextStyle(color: Colors.green, fontSize: 12)),
                      backgroundColor: Colors.green.shade50,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
