import 'package:flutter/material.dart';
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
  bool _isDeleting = false; // New: Track deletion state
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showPasswordConfirmationDialog(
    String action,
    String uid,
  ) async {
    final passwordController = TextEditingController();
    bool isAuthenticating = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (dialogContext, setDialogState) => AlertDialog(
                  title: Text('Confirm $action'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Please enter your password to $action user.'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        enabled: !isAuthenticating,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          errorText:
                              isAuthenticating
                                  ? null
                                  : null, // Managed in actions
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      if (isAuthenticating)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isAuthenticating
                              ? null
                              : () {
                                Navigator.of(dialogContext).pop(false);
                              },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
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
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Incorrect password'),
                                        ),
                                      );
                                    });
                                  }
                                } catch (e) {
                                  setDialogState(() {
                                    isAuthenticating = false;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Authentication failed: $e',
                                        ),
                                      ),
                                    );
                                  });
                                }
                              },
                      child: const Text('Confirm'),
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
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      }
      return;
    }
    if (uid == currentUser.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot suspend yourself')),
        );
      }
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Suspend', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        final userData = await _firestoreService.getUser(uid);
        await _firestoreService.suspendUser(uid, currentUser.uid);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User suspended: ${userData?['email'] ?? uid}'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to suspend user: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Future<void> _unsuspendUser(String uid) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      }
      return;
    }
    if (uid == currentUser.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot unsuspend yourself')),
        );
      }
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Unsuspend', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        final userData = await _firestoreService.getUser(uid);
        await _firestoreService.unsuspendUser(uid, currentUser.uid);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('User unsuspended: ${userData?['email'] ?? uid}'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unsuspend user: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  Future<void> _deleteUser(String uid) async {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No user logged in')));
      }
      return;
    }
    if (uid == currentUser.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot delete yourself')),
        );
      }
      return;
    }

    final confirmed = await _showPasswordConfirmationDialog('Delete', uid);
    if (confirmed && mounted) {
      setState(() => _isDeleting = true);
      try {
        // Cache user data before deletion
        final userData = await _firestoreService.getUser(uid);
        final userEmail = userData?['email'] ?? uid;
        await _firestoreService.deleteUser(uid, currentUser.uid);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User deleted: $userEmail')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to delete user: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
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
    final filteredUsers = _filteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isLoading || _isDeleting
              ? const LoadingIndicator()
              : RefreshIndicator(
                onRefresh: _loadUsers,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                'Search students, admins, or lecturers by email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12.0,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Users: ${filteredUsers.length}',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                  fontSize:
                                      MediaQuery.of(context).size.width > 600
                                          ? 24
                                          : 20,
                                ),
                                semanticsLabel:
                                    'Users: ${filteredUsers.length}',
                              ),
                              const SizedBox(height: 16),
                              if (filteredUsers.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
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
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                      title: Text(
                                        user['email'] ?? 'No Email',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize:
                                              MediaQuery.of(
                                                        context,
                                                      ).size.width >
                                                      600
                                                  ? 16
                                                  : 14,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Role: ${user['role'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              fontSize:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width >
                                                          600
                                                      ? 14
                                                      : 12,
                                            ),
                                          ),
                                          Text(
                                            'Status: ${user['suspended'] == true ? 'Suspended' : 'Active'}',
                                            style: TextStyle(
                                              color:
                                                  user['suspended'] == true
                                                      ? Colors.red
                                                      : Colors.green,
                                              fontSize:
                                                  MediaQuery.of(
                                                            context,
                                                          ).size.width >
                                                          600
                                                      ? 14
                                                      : 12,
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
                    ],
                  ),
                ),
              ),
    );
  }
}
