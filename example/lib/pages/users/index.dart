import 'package:flutter/material.dart';
import 'package:vortex/vortex.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FetchResult<List<dynamic>>>(
      future: useFetch<List<dynamic>>(
        'https://jsonplaceholder.typicode.com/users'
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final result = snapshot.data!;
        
        return ReactiveBuilder(
          dependencies: [result.status, result.data],
          builder: (context) {
            if (result.pending) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (result.hasError) {
              return Center(
                child: Text('Error: ${result.error.value?.message}'),
              );
            }
            
            final users = result.data.value;
            if (users == null || users.isEmpty) {
              return const Center(child: Text('No users found'));
            }
            
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index] as Map<String, dynamic>;
                return ListTile(
                  title: Text(user['name']),
                  subtitle: Text(user['email']),
                );
              },
            );
          },
        );
      },
    );
  }
}