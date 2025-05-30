// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import '../../services/firestore_service.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/loading_indicator.dart';
// import '../../models/course.dart';
// import '../../models/module.dart';
// import '../../models/lesson.dart';
// import '../../models/unit.dart';

// class ManageCoursePage extends StatefulWidget {
//   final Course course;

//   const ManageCoursePage({super.key, required this.course});

//   @override
//   State<ManageCoursePage> createState() => _ManageCoursePageState();
// }

// class _ManageCoursePageState extends State<ManageCoursePage> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthService _authService = AuthService();
//   bool _isLoading = true;
//   List<Module> _modules = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadModules();
//   }

//   Future<void> _loadModules() async {
//     setState(() => _isLoading = true);
//     try {
//       _modules = await _firestoreService.getModules(widget.course.id);
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load modules: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _addModule() async {
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Add Module'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(labelText: 'Module Title'),
//                 ),
//                 TextField(
//                   controller: descriptionController,
//                   decoration: const InputDecoration(labelText: 'Description'),
//                   maxLines: 3,
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (titleController.text.trim().isNotEmpty) {
//                     try {
//                       await _firestoreService.addModule(
//                         widget.course.id,
//                         titleController.text.trim(),
//                         descriptionController.text.trim(),
//                         _modules.length,
//                         _authService.getCurrentUser()!.uid,
//                       );
//                       await _loadModules();
//                       Navigator.pop(context);
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to add module: $e')),
//                       );
//                     }
//                   }
//                 },
//                 child: const Text('Add'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.course.title),
//         backgroundColor: Theme.of(context).primaryColor,
//       ),
//       body:
//           _isLoading
//               ? const LoadingIndicator()
//               : Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: ListView(
//                   children: [
//                     Card(
//                       elevation: 4,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Row(
//                               children: [
//                                 Text(
//                                   'Modules',
//                                   style: Theme.of(
//                                     context,
//                                   ).textTheme.headlineSmall?.copyWith(
//                                     fontWeight: FontWeight.bold,
//                                     color: Theme.of(context).primaryColor,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Chip(
//                                   label: Text(
//                                     '${_modules.length}',
//                                     style: const TextStyle(color: Colors.white),
//                                   ),
//                                   backgroundColor:
//                                       Theme.of(context).primaryColor,
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 16),
//                             if (_modules.isEmpty)
//                               const Text(
//                                 'No modules yet. Add a new module!',
//                                 style: TextStyle(color: Colors.grey),
//                               )
//                             else
//                               ..._modules.asMap().entries.map(
//                                 (entry) => ExpansionTile(
//                                   title: Text(entry.value.title),
//                                   subtitle: Text(entry.value.description),
//                                   children: [
//                                     ModuleContentWidget(
//                                       courseId: widget.course.id,
//                                       module: entry.value,
//                                       onContentAdded: _loadModules,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             const SizedBox(height: 16),
//                             ElevatedButton.icon(
//                               onPressed: _addModule,
//                               icon: const Icon(Icons.add),
//                               label: const Text('Add Module'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Theme.of(context).primaryColor,
//                                 foregroundColor: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//     );
//   }
// }

// class ModuleContentWidget extends StatefulWidget {
//   final String courseId;
//   final Module module;
//   final VoidCallback onContentAdded;

//   const ModuleContentWidget({
//     super.key,
//     required this.courseId,
//     required this.module,
//     required this.onContentAdded,
//   });

//   @override
//   State<ModuleContentWidget> createState() => _ModuleContentWidgetState();
// }

// class _ModuleContentWidgetState extends State<ModuleContentWidget> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthService _authService = AuthService();
//   List<Lesson> _lessons = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadLessons();
//   }

//   Future<void> _loadLessons() async {
//     setState(() => _isLoading = true);
//     try {
//       _lessons = await _firestoreService.getLessons(
//         widget.courseId,
//         widget.module.id,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load lessons: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _addLesson() async {
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();

//     await showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('Add Lesson'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextField(
//                   controller: titleController,
//                   decoration: const InputDecoration(labelText: 'Lesson Title'),
//                 ),
//                 TextField(
//                   controller: descriptionController,
//                   decoration: const InputDecoration(labelText: 'Description'),
//                   maxLines: 3,
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () async {
//                   if (titleController.text.trim().isNotEmpty) {
//                     try {
//                       await _firestoreService.addLesson(
//                         widget.courseId,
//                         widget.module.id,
//                         titleController.text.trim(),
//                         descriptionController.text.trim(),
//                         _lessons.length,
//                         _authService.getCurrentUser()!.uid,
//                       );
//                       await _loadLessons();
//                       widget.onContentAdded();
//                       Navigator.pop(context);
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to add lesson: $e')),
//                       );
//                     }
//                   }
//                 },
//                 child: const Text('Add'),
//               ),
//             ],
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _isLoading
//         ? const Padding(
//           padding: EdgeInsets.all(16.0),
//           child: LoadingIndicator(),
//         )
//         : Column(
//           children: [
//             ..._lessons.asMap().entries.map(
//               (entry) => ExpansionTile(
//                 title: Text(entry.value.title),
//                 subtitle: Text(entry.value.description),
//                 children: [
//                   UnitContentWidget(
//                     courseId: widget.courseId,
//                     moduleId: widget.module.id,
//                     lesson: entry.value,
//                     onContentAdded: _loadLessons,
//                   ),
//                 ],
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton.icon(
//                 onPressed: _addLesson,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Lesson'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         );
//   }
// }

// class UnitContentWidget extends StatefulWidget {
//   final String courseId;
//   final String moduleId;
//   final Lesson lesson;
//   final VoidCallback onContentAdded;

//   const UnitContentWidget({
//     super.key,
//     required this.courseId,
//     required this.moduleId,
//     required this.lesson,
//     required this.onContentAdded,
//   });

//   @override
//   State<UnitContentWidget> createState() => _UnitContentWidgetState();
// }

// class _UnitContentWidgetState extends State<UnitContentWidget> {
//   final FirestoreService _firestoreService = FirestoreService();
//   final AuthService _authService = AuthService();
//   List<Unit> _units = [];
//   bool _isLoading = true;
//   bool _isUploading = false;
//   final List<String> _contentTypes = ['video', 'pdf', 'image', 'text'];

//   @override
//   void initState() {
//     super.initState();
//     _loadUnits();
//   }

//   Future<void> _loadUnits() async {
//     setState(() => _isLoading = true);
//     try {
//       _units = await _firestoreService.getUnits(
//         widget.courseId,
//         widget.moduleId,
//         widget.lesson.id,
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Failed to load units: $e')));
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   Future<void> _addUnit() async {
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();
//     String? contentType;
//     String? contentUrl;

//     await showDialog(
//       context: context,
//       builder:
//           (context) => StatefulBuilder(
//             builder:
//                 (context, setDialogState) => AlertDialog(
//                   title: const Text('Add Unit'),
//                   content: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       TextField(
//                         controller: titleController,
//                         decoration: const InputDecoration(
//                           labelText: 'Unit Title',
//                         ),
//                       ),
//                       DropdownButtonFormField<String>(
//                         decoration: const InputDecoration(
//                           labelText: 'Content Type',
//                         ),
//                         items:
//                             _contentTypes
//                                 .map(
//                                   (type) => DropdownMenuItem(
//                                     value: type,
//                                     child: Text(type),
//                                   ),
//                                 )
//                                 .toList(),
//                         onChanged:
//                             (value) =>
//                                 setDialogState(() => contentType = value),
//                         validator:
//                             (value) =>
//                                 value == null
//                                     ? 'Please select a content type'
//                                     : null,
//                       ),
//                       if (contentType != 'text')
//                         Padding(
//                           padding: const EdgeInsets.only(top: 8.0),
//                           child: ElevatedButton(
//                             onPressed:
//                                 _isUploading
//                                     ? null
//                                     : () async {
//                                       try {
//                                         setDialogState(
//                                           () => _isUploading = true,
//                                         );
//                                         FilePickerResult? result =
//                                             await FilePicker.platform.pickFiles(
//                                               type:
//                                                   contentType == 'video'
//                                                       ? FileType.video
//                                                       : contentType == 'pdf'
//                                                       ? FileType.custom
//                                                       : FileType.image,
//                                               allowedExtensions:
//                                                   contentType == 'pdf'
//                                                       ? ['pdf']
//                                                       : null,
//                                               allowMultiple: false,
//                                             );
//                                         if (result != null &&
//                                             result.files.single.path != null) {
//                                           contentUrl = await _firestoreService
//                                               .uploadToCloudinary(
//                                                 result.files.single.path!,
//                                                 contentType!,
//                                               );
//                                         }
//                                       } catch (e) {
//                                         ScaffoldMessenger.of(
//                                           context,
//                                         ).showSnackBar(
//                                           SnackBar(
//                                             content: Text(
//                                               'Failed to upload file: $e',
//                                             ),
//                                           ),
//                                         );
//                                       } finally {
//                                         setDialogState(
//                                           () => _isUploading = false,
//                                         );
//                                       }
//                                     },
//                             child:
//                                 _isUploading
//                                     ? const CircularProgressIndicator()
//                                     : const Text('Upload File'),
//                           ),
//                         )
//                       else
//                         TextField(
//                           controller: TextEditingController(
//                             text: contentUrl ?? '',
//                           ),
//                           decoration: const InputDecoration(
//                             labelText: 'Content Text',
//                           ),
//                           maxLines: 3,
//                           onChanged: (value) => contentUrl = value,
//                         ),
//                       TextField(
//                         controller: descriptionController,
//                         decoration: const InputDecoration(
//                           labelText: 'Description',
//                         ),
//                         maxLines: 3,
//                       ),
//                     ],
//                   ),
//                   actions: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cancel'),
//                     ),
//                     TextButton(
//                       onPressed: () async {
//                         if (titleController.text.trim().isNotEmpty &&
//                             contentType != null &&
//                             contentUrl != null &&
//                             contentUrl!.isNotEmpty) {
//                           try {
//                             await _firestoreService.addUnit(
//                               widget.courseId,
//                               widget.moduleId,
//                               widget.lesson.id,
//                               titleController.text.trim(),
//                               contentType!,
//                               contentUrl!,
//                               descriptionController.text.trim(),
//                               _units.length,
//                               _authService.getCurrentUser()!.uid,
//                             );
//                             await _loadUnits();
//                             widget.onContentAdded();
//                             Navigator.pop(context);
//                           } catch (e) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text('Failed to add unit: $e')),
//                             );
//                           }
//                         } else {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Please fill all required fields'),
//                             ),
//                           );
//                         }
//                       },
//                       child: const Text('Add'),
//                     ),
//                   ],
//                 ),
//           ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return _isLoading
//         ? const Padding(
//           padding: EdgeInsets.all(16.0),
//           child: LoadingIndicator(),
//         )
//         : Column(
//           children: [
//             ..._units.map(
//               (unit) => ListTile(
//                 title: Text(unit.title),
//                 subtitle: Text(
//                   '${unit.type.toUpperCase()}: ${unit.url.length > 50 ? '${unit.url.substring(0, 50)}...' : unit.url}',
//                 ),
//                 trailing: IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: () async {
//                     try {
//                       await _firestoreService.deleteUnit(
//                         widget.courseId,
//                         widget.moduleId,
//                         widget.lesson.id,
//                         unit.id,
//                         _authService.getCurrentUser()!.uid,
//                       );
//                       await _loadUnits();
//                       widget.onContentAdded();
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text('Failed to delete unit: $e')),
//                       );
//                     }
//                   },
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton.icon(
//                 onPressed: _addUnit,
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Unit'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Theme.of(context).primaryColor,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         );
//   }
// }
