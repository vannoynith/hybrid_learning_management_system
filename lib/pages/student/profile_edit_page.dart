// import 'package:flutter/material.dart';
// import '../../services/auth_service.dart';
// import '../../services/firestore_service.dart';
// import '../../routes.dart';
// import '../../widgets/loading_indicator.dart';

// class ProfileEditPage extends StatefulWidget {
//   const ProfileEditPage({super.key});

//   @override
//   State<ProfileEditPage> createState() => _ProfileEditPageState();
// }

// class _ProfileEditPageState extends State<ProfileEditPage> {
//   Map<String, dynamic>? userData;
//   bool isLoading = true;
//   bool isSaving = false;
//   final AuthService _authService = AuthService();
//   final FirestoreService _firestoreService = FirestoreService();
//   late TextEditingController _nameController;
//   late TextEditingController _emailController;
//   late TextEditingController _dobController;
//   late TextEditingController _addressController;
//   late TextEditingController _phoneController;
//   String? _nameError;
//   String? _emailError;
//   String? _phoneError;
//   DateTime? _selectedDate;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserData();
//   }

//   Future<void> _loadUserData() async {
//     setState(() => isLoading = true);
//     try {
//       final user = _authService.getCurrentUser();
//       if (user != null) {
//         userData = await _firestoreService.getUser(user.uid);
//         _nameController = TextEditingController(
//           text: userData?['displayName'] ?? '',
//         );
//         _emailController = TextEditingController(
//           text: userData?['email'] ?? '',
//         );
//         _dobController = TextEditingController(
//           text: userData?['dateOfBirth']?.toString() ?? '',
//         );
//         _addressController = TextEditingController(
//           text: userData?['address']?.toString() ?? '',
//         );
//         _phoneController = TextEditingController(
//           text: userData?['phoneNumber']?.toString() ?? '',
//         );

//         // Handle date parsing for dateOfBirth
//         if (userData?['dateOfBirth'] != null) {
//           try {
//             // Assuming dateOfBirth is stored as MM/DD/YYYY string
//             final dateParts = userData!['dateOfBirth'].toString().split('/');
//             if (dateParts.length == 3) {
//               _selectedDate = DateTime(
//                 int.parse(dateParts[2]),
//                 int.parse(dateParts[0]),
//                 int.parse(dateParts[1]),
//               );
//             }
//           } catch (e) {
//             _selectedDate = null;
//             _dobController.text = ''; // Reset if parsing fails
//           }
//         }
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error loading profile: $e'),
//           backgroundColor: const Color(0xFFEF4444),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Future<void> _selectDate(BuildContext context) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _selectedDate ?? DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime.now(),
//     );
//     if (picked != null && picked != _selectedDate) {
//       setState(() {
//         _selectedDate = picked;
//         _dobController.text = "${picked.month}/${picked.day}/${picked.year}";
//       });
//     }
//   }

//   Future<void> _saveProfile() async {
//     setState(() {
//       _nameError = _nameController.text.isEmpty ? 'Name cannot be empty' : null;
//       _emailError =
//           !_emailController.text.contains('@') ? 'Enter a valid email' : null;
//       _phoneError =
//           _phoneController.text.isNotEmpty &&
//                   !RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim())
//               ? 'Enter a valid 10-digit phone number'
//               : null;
//     });

//     if (_nameError != null || _emailError != null || _phoneError != null)
//       return;

//     setState(() => isSaving = true);
//     try {
//       final user = _authService.getCurrentUser();
//       if (user != null) {
//         await _firestoreService.saveUser(
//           user.uid,
//           _emailController.text.trim(),
//           _nameController.text.trim(),
//           dateOfBirth:
//               _dobController.text.trim().isNotEmpty
//                   ? _dobController.text.trim()
//                   : null,
//           address:
//               _addressController.text.trim().isNotEmpty
//                   ? _addressController.text.trim()
//                   : null,
//           phoneNumber:
//               _phoneController.text.trim().isNotEmpty
//                   ? _phoneController.text.trim()
//                   : null,
//         );
//         Navigator.pop(context); // Return to ProfilePage
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Profile updated successfully'),
//             backgroundColor: const Color(0xFF10B981),
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to update profile: $e'),
//           backgroundColor: const Color(0xFFEF4444),
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//       );
//     } finally {
//       setState(() => isSaving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Edit Profile',
//           style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//         ),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body:
//           isLoading
//               ? const LoadingIndicator()
//               : SingleChildScrollView(
//                 padding: EdgeInsets.all(
//                   MediaQuery.of(context).size.width * 0.05,
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     const SizedBox(height: 24),
//                     TextField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         labelText: 'Full Name',
//                         prefixIcon: const Icon(
//                           Icons.person,
//                           color: Color(0xFFFF6949),
//                         ),
//                         errorText: _nameError,
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 16,
//                         ),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           _nameError =
//                               value.isEmpty ? 'Name cannot be empty' : null;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         labelText: 'Email Address',
//                         prefixIcon: const Icon(
//                           Icons.email,
//                           color: Color(0xFFFF6949),
//                         ),
//                         errorText: _emailError,
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 16,
//                         ),
//                       ),
//                       keyboardType: TextInputType.emailAddress,
//                       onChanged: (value) {
//                         setState(() {
//                           _emailError =
//                               !value.contains('@')
//                                   ? 'Enter a valid email'
//                                   : null;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _dobController,
//                       readOnly: true,
//                       decoration: InputDecoration(
//                         labelText: 'Date of Birth (Optional)',
//                         prefixIcon: const Icon(
//                           Icons.calendar_today,
//                           color: Color(0xFFFF6949),
//                         ),
//                         suffixIcon: IconButton(
//                           icon: const Icon(
//                             Icons.date_range,
//                             color: Color(0xFFFF6949),
//                           ),
//                           onPressed: () => _selectDate(context),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 16,
//                         ),
//                       ),
//                       onTap: () => _selectDate(context),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _addressController,
//                       decoration: InputDecoration(
//                         labelText: 'Address (Optional)',
//                         prefixIcon: const Icon(
//                           Icons.location_on,
//                           color: Color(0xFFFF6949),
//                         ),
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 16,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                     TextField(
//                       controller: _phoneController,
//                       decoration: InputDecoration(
//                         labelText: 'Phone Number (Optional)',
//                         prefixIcon: const Icon(
//                           Icons.phone,
//                           color: Color(0xFFFF6949),
//                         ),
//                         errorText: _phoneError,
//                         filled: true,
//                         fillColor: Colors.white,
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(24),
//                           borderSide: BorderSide.none,
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(
//                           horizontal: 20,
//                           vertical: 16,
//                         ),
//                       ),
//                       keyboardType: TextInputType.phone,
//                       onChanged: (value) {
//                         setState(() {
//                           _phoneError =
//                               value.isNotEmpty &&
//                                       !RegExp(
//                                         r'^\d{10}$',
//                                       ).hasMatch(value.trim())
//                                   ? 'Enter a valid 10-digit phone number'
//                                   : null;
//                         });
//                       },
//                     ),
//                     const SizedBox(height: 24),
//                     AnimatedScale(
//                       scale: isSaving ? 0.95 : 1.0,
//                       duration: const Duration(milliseconds: 300),
//                       child: AnimatedOpacity(
//                         opacity: isSaving ? 0.6 : 1.0,
//                         duration: const Duration(milliseconds: 300),
//                         child: GestureDetector(
//                           onTap: isSaving ? null : _saveProfile,
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.symmetric(
//                               vertical: 16,
//                               horizontal: 32,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors:
//                                     isSaving
//                                         ? [Colors.grey, Colors.grey]
//                                         : const [
//                                           Color(0xFFFF6949),
//                                           Color(0xFFFF6949),
//                                         ],
//                                 begin: Alignment.topLeft,
//                                 end: Alignment.bottomRight,
//                               ),
//                               borderRadius: BorderRadius.circular(24),
//                               boxShadow: [
//                                 BoxShadow(
//                                   color: Colors.black.withOpacity(0.1),
//                                   blurRadius: 8,
//                                   offset: const Offset(0, 4),
//                                 ),
//                               ],
//                             ),
//                             child: Center(
//                               child:
//                                   isSaving
//                                       ? const SizedBox(
//                                         width: 20,
//                                         height: 20,
//                                         child: CircularProgressIndicator(
//                                           color: Colors.white,
//                                           strokeWidth: 2,
//                                         ),
//                                       )
//                                       : const Text(
//                                         'Save Changes',
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.white,
//                                         ),
//                                       ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//     );
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _dobController.dispose();
//     _addressController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }
// }
