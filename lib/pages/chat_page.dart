// import 'package:flutter/material.dart';
// import '../routes.dart';
// import '../widgets/loading_indicator.dart';

// class ChatPage extends StatefulWidget {
//   const ChatPage({super.key});

//   @override
//   State<ChatPage> createState() => _ChatPageState();
// }

// class _ChatPageState extends State<ChatPage>
//     with SingleTickerProviderStateMixin {
//   bool isLoading = true;
//   late TabController _tabController;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadData();
//   }

//   Future<void> _loadData() async {
//     await Future.delayed(const Duration(seconds: 1));
//     setState(() => isLoading = false);
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         elevation: 0,
//         bottom: TabBar(
//           controller: _tabController,
//           indicator: const UnderlineTabIndicator(
//             borderSide: BorderSide(width: 3.0, color: Colors.white),
//             insets: EdgeInsets.symmetric(horizontal: 16),
//           ),
//           tabs: const [
//             Tab(icon: Icon(Icons.home), text: 'Home'),
//             Tab(icon: Icon(Icons.person), text: 'Profile'),
//             Tab(icon: Icon(Icons.chat), text: 'Chat'),
//           ],
//           onTap: (index) {
//             if (index == 0)
//               Navigator.pushNamed(context, Routes.dashboard);
//             else if (index == 1)
//               Navigator.pushNamed(context, Routes.profile);
//             else if (index == 2)
//               Navigator.pushNamed(context, Routes.chat); // Already on Chat
//           },
//         ),
//       ),
//       body: RefreshIndicator(
//         onRefresh: _loadData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 16),
//               Text('It’s Monday, 02:16 PM',
//                   style: TextStyle(
//                       fontSize: 16,
//                       color: Colors.black54,
//                       fontWeight: FontWeight.w500)),
//               const SizedBox(height: 32),
//               isLoading
//                   ? const LoadingIndicator()
//                   : const Text('Chat messages here',
//                       style: TextStyle(fontSize: 18)),
//               const SizedBox(height: 24),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
