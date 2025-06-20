import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/loading_indicator.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isDeleting = false;
  List<Map<String, dynamic>> _users = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      _users = await _firestoreService.getActiveUsers();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to load users: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<bool> _showPasswordConfirmationDialog(
    String action,
    String uid,
  ) async {
    final passwordController = TextEditingController();
    bool isAuthenticating = false;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: Colors.white,
                  title: Text(
                    'Confirm $action',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Please enter your password to $action user.',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        enabled: !isAuthenticating,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText: errorMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      ),
                      if (isAuthenticating)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(
                            color: Color(0xFFFF6949),
                            backgroundColor: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isAuthenticating
                              ? null
                              : () => Navigator.of(dialogContext).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    ElevatedButton(
                      onPressed:
                          isAuthenticating
                              ? null
                              : () async {
                                setDialogState(() => isAuthenticating = true);
                                try {
                                  final isPasswordValid = await _authService
                                      .reAuthenticateAdmin(
                                        passwordController.text,
                                      );
                                  if (isPasswordValid) {
                                    Navigator.of(dialogContext).pop(true);
                                  } else {
                                    setDialogState(() {
                                      isAuthenticating = false;
                                      errorMessage = 'Incorrect password';
                                    });
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isAuthenticating = false;
                                    errorMessage = 'Authentication failed: $e';
                                  });
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6949),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
          ),
    );

    passwordController.dispose();
    return result ?? false;
  }

  Future<void> _suspendUser(String uid) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || !mounted) return;
    if (uid == currentUser.uid) {
      _showErrorSnackBar('You cannot suspend yourself');
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Suspend', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        final userData = await _firestoreService.getUser(uid);
        await _firestoreService.suspendUser(uid, currentUser.uid);
        await _loadUsers();
        _showSuccessSnackBar('User suspended: ${userData?['email'] ?? uid}');
      } catch (e) {
        _showErrorSnackBar('Failed to suspend user: $e');
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _unsuspendUser(String uid) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || !mounted) return;
    if (uid == currentUser.uid) {
      _showErrorSnackBar('You cannot unsuspend yourself');
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Unsuspend', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        final userData = await _firestoreService.getUser(uid);
        await _firestoreService.unsuspendUser(uid, currentUser.uid);
        await _loadUsers();
        _showSuccessSnackBar('User unsuspended: ${userData?['email'] ?? uid}');
      } catch (e) {
        _showErrorSnackBar('Failed to unsuspend user: $e');
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null || !mounted) return;
    if (uid == currentUser.uid) {
      _showErrorSnackBar('You cannot delete yourself');
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Delete', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        // Fetch user data before deletion for logging and feedback
        final userData = await _firestoreService.getUser(uid);
        final userEmail = userData?['email'] ?? 'Unknown User';
        // Delete user via FirestoreService
        await _firestoreService.deleteUser(uid, currentUser.uid);
        // Refresh user list
        await _loadUsers();
        _showSuccessSnackBar('User deleted: $userEmail');
      } catch (e) {
        _showErrorSnackBar('Failed to delete user: $e');
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  List<Map<String, dynamic>> _filteredUsers() {
    if (_searchQuery.isEmpty) {
      return _users
          .where(
            (user) => ['student', 'admin', 'lecturer'].contains(user['role']),
          )
          .toList();
    }
    return _users
        .where(
          (user) =>
              ['student', 'admin', 'lecturer'].contains(user['role']) &&
              (user['email']?.toLowerCase().contains(_searchQuery) ?? false),
        )
        .toList();
  }

  Color _getRoleHighlightColor(String? role) {
    switch (role) {
      case 'student':
        return const Color.fromARGB(255, 64, 169, 255).withOpacity(0.1);
      case 'admin':
        return const Color.fromARGB(255, 255, 167, 34).withOpacity(0.1);
      case 'lecturer':
        return const Color.fromARGB(255, 101, 255, 106).withOpacity(0.1);
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final filteredUsers = _filteredUsers();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body:
          _isLoading || _isDeleting
              ? const LoadingIndicator()
              : RefreshIndicator(
                onRefresh: _loadUsers,
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200,
                      floating: false,
                      pinned: true,
                      toolbarHeight: 60,
                      titleSpacing: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text(
                          'User Management',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFFF6949), Color(0xFFFF8A65)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                      backgroundColor: const Color(0xFFFF6949),
                      elevation: 0,
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 24,
                          vertical: 16,
                        ),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Users: ${filteredUsers.length}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                    fontSize: isMobile ? 24 : 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: TextField(
                                    controller: _searchController,
                                    decoration: InputDecoration(
                                      hintText: 'Search by email...',
                                      prefixIcon: const Icon(Icons.search),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 12.0,
                                          ),
                                    ),
                                  ),
                                ),
                                if (filteredUsers.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.0,
                                    ),
                                    child: Text(
                                      'No users found.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  ...filteredUsers.map(
                                    (user) => Container(
                                      decoration: BoxDecoration(
                                        color: _getRoleHighlightColor(
                                          user['role'],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      margin: const EdgeInsets.only(
                                        bottom: 8.0,
                                      ),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                            ),
                                        title: Text(
                                          user['email'] ?? 'No Email',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: isMobile ? 14 : 16,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Role: ${user['role'] ?? 'Unknown'}',
                                              style: TextStyle(
                                                fontSize: isMobile ? 12 : 14,
                                              ),
                                            ),
                                            Text(
                                              'Status: ${user['suspended'] == true ? 'Suspended' : 'Active'}',
                                              style: TextStyle(
                                                color:
                                                    user['suspended'] == true
                                                        ? Colors.red
                                                        : Colors.green,
                                                fontSize: isMobile ? 12 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                user['suspended'] == true
                                                    ? Icons.play_arrow
                                                    : Icons.pause,
                                                color:
                                                    user['suspended'] == true
                                                        ? Colors.green
                                                        : Colors.orange,
                                              ),
                                              tooltip:
                                                  user['suspended'] == true
                                                      ? 'Unsuspend'
                                                      : 'Suspend',
                                              onPressed:
                                                  _isDeleting
                                                      ? null
                                                      : () {
                                                        if (user['suspended'] ==
                                                            true) {
                                                          _unsuspendUser(
                                                            user['uid'],
                                                          );
                                                        } else {
                                                          _suspendUser(
                                                            user['uid'],
                                                          );
                                                        }
                                                      },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Color(0xFFEF4444),
                                              ),
                                              tooltip: 'Delete',
                                              onPressed:
                                                  _isDeleting
                                                      ? null
                                                      : () => _deleteUser(
                                                        user['uid'],
                                                      ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
