import 'package:flutter/material.dart';
import 'package:flutterwind_core/flutterwind.dart';
import 'package:vortex/vortex.dart';

@VortexPage('/todos', middleware: ['auth'])
class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the global dark mode ref
    final isDarkMode = ReactiveHooks.useRef<bool>('isDarkMode', false);

    // Create todo list state
    final todos = ReactiveHooks.useRef<List<Map<String, dynamic>>>('todos', [
      {'id': 1, 'text': 'Learn FlutterWind', 'completed': true},
      {'id': 2, 'text': 'Build a Todo App', 'completed': false},
      {'id': 3, 'text': 'Master Flutter', 'completed': false},
    ]);

    // Create a ref for the new todo text
    final newTodoText = ReactiveHooks.useRef<String>('newTodoText', '');

    // Create computed values
    final completedTodos =
        ReactiveHooks.useComputed<List<Map<String, dynamic>>>(
      'completedTodos',
      () => todos.value.where((todo) => todo['completed'] == true).toList(),
      dependencies: [todos],
    );

    final incompleteTodos =
        ReactiveHooks.useComputed<List<Map<String, dynamic>>>(
      'incompleteTodos',
      () => todos.value.where((todo) => todo['completed'] == false).toList(),
      dependencies: [todos],
    );

    // Todo functions
    void addTodo() {
      if (newTodoText.value.trim().isNotEmpty) {
        final newTodo = {
          'id': todos.value.isEmpty ? 1 : todos.value.last['id'] + 1,
          'text': newTodoText.value,
          'completed': false,
        };

        todos.value = [...todos.value, newTodo];
        newTodoText.value = '';
      }
    }

    void toggleTodo(int id) {
      final updatedTodos = todos.value.map((todo) {
        if (todo['id'] == id) {
          return {...todo, 'completed': !todo['completed']};
        }
        return todo;
      }).toList();

      todos.value = updatedTodos;
    }

    void deleteTodo(int id) {
      todos.value = todos.value.where((todo) => todo['id'] != id).toList();
    }

    void editTodo(int id, String newText) {
      if (newText.trim().isNotEmpty) {
        final updatedTodos = todos.value.map((todo) {
          if (todo['id'] == id) {
            return {...todo, 'text': newText};
          }
          return todo;
        }).toList();

        todos.value = updatedTodos;
      }
    }

    return ReactiveBuilder(
        dependencies: [
          todos,
          newTodoText,
          completedTodos,
          incompleteTodos,
          isDarkMode
        ],
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: const Text('Todo App'),
              actions: [
                // Dark mode toggle
                Switch(
                  value: isDarkMode.value,
                  onChanged: (value) => isDarkMode.value = value,
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Column(
              children: [
                // Add todo form
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Add a new todo...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) => newTodoText.value = value,
                          controller:
                              TextEditingController(text: newTodoText.value),
                          onSubmitted: (_) => addTodo(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: addTodo,
                        child: const Icon(Icons.add),
                      ).className("bg-blue-500 text-white p-4 rounded-md"),
                    ],
                  ),
                ).className("bg-gray-100 dark:bg-gray-800"),

                // Todo stats
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total: ${todos.value.length}")
                          .className("text-gray-600 dark:text-gray-400"),
                      Text("Completed: ${completedTodos.value.length}")
                          .className("text-green-600 dark:text-green-400"),
                      Text("Remaining: ${incompleteTodos.value.length}")
                          .className("text-red-600 dark:text-red-400"),
                    ],
                  ),
                ).className("bg-gray-200 dark:bg-gray-700"),

                // Todo list
                Expanded(
                  child: ListView.builder(
                    itemCount: todos.value.length,
                    itemBuilder: (context, index) {
                      final todo = todos.value[index];
                      return _buildTodoItem(
                        todo: todo,
                        onToggle: () => toggleTodo(todo['id']),
                        onDelete: () => deleteTodo(todo['id']),
                        onEdit: (newText) => editTodo(todo['id'], newText),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildTodoItem({
    required Map<String, dynamic> todo,
    required VoidCallback onToggle,
    required VoidCallback onDelete,
    required Function(String) onEdit,
  }) {
    // Create refs for editing state
    final isEditing =
        ReactiveHooks.useRef<bool>('editing_${todo['id']}', false);
    final editText =
        ReactiveHooks.useRef<String>('editText_${todo['id']}', todo['text']);

    return ReactiveBuilder(
        dependencies: [isEditing, editText],
        builder: (context) {
          return GestureDetector(
            onDoubleTap: () {
              isEditing.value = true;
              editText.value = todo['text'];
            },
            child: Dismissible(
              key: Key('todo_${todo['id']}'),
              background: Container().className("bg-red-500"),
              onDismissed: (_) => onDelete(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Row(
                  children: [
                    // Checkbox
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                todo['completed'] ? Colors.green : Colors.grey,
                            width: 2,
                          ),
                          color: todo['completed']
                              ? Colors.green
                              : Colors.transparent,
                        ),
                        child: todo['completed']
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Todo text or edit field
                    Expanded(
                      child: isEditing.value
                          ? TextField(
                              controller:
                                  TextEditingController(text: editText.value),
                              autofocus: true,
                              onChanged: (value) => editText.value = value,
                              onSubmitted: (value) {
                                onEdit(value);
                                isEditing.value = false;
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            )
                          : Text(
                              todo['text'],
                              style: TextStyle(
                                decoration: todo['completed']
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: todo['completed'] ? Colors.grey : null,
                              ),
                            ),
                    ),

                    // Delete button
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                  ],
                ),
              ).className(todo['completed']
                  ? "bg-green-50 dark:bg-green-900/20 border-l-4 border-green-500 rounded-md"
                  : "bg-white dark:bg-gray-800 border-l-4 border-blue-500 rounded-md shadow-sm hover:shadow-md transition-shadow duration-200"),
            ),
          );
        });
  }
}
