import 'package:flutter/material.dart';
import 'package:course_emis/widgets/common_state_widgets.dart';

/// Comprehensive error showcase page displaying all error states
/// with best design practices for the EMIS application
class ErrorShowcasePage extends StatelessWidget {
  const ErrorShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error States Showcase'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Empty States'),

          // Empty State - No Data
          _buildExampleCard(
            context,
            'Empty State - No Data',
            EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'No Items Found',
              subtitle: 'Your list is empty. Add items to get started!',
              onRefresh: () {},
            ),
          ),

          // Empty State - Search Results
          _buildExampleCard(
            context,
            'Empty State - No Search Results',
            EmptyStateWidget(
              icon: Icons.search_off_rounded,
              title: 'No Results Found',
              subtitle: 'Try adjusting your search terms or filters',
              onRefresh: () {},
            ),
          ),

          // Empty State - No Messages
          _buildExampleCard(
            context,
            'Empty State - No Messages',
            EmptyStateWidget(
              icon: Icons.mail_outline,
              title: 'No Messages',
              subtitle: 'Your inbox is clear. Enjoy the quiet!',
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Loading States'),

          // Basic Loading
          _buildExampleCard(
            context,
            'Basic Loading',
            const SizedBox(
              height: 100,
              child: Center(
                child: LoadingWidget(),
              ),
            ),
          ),

          // Loading with Message
          _buildExampleCard(
            context,
            'Loading with Message',
            const SizedBox(
              height: 120,
              child: LoadingWidget(message: 'Loading data...'),
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Error States'),

          // Network Error
          _buildExampleCard(
            context,
            'Network Error',
            CustomErrorWidget(
              error: Exception('DioException: Connection timeout'),
              onRetry: () {},
              customMessage:
                  'Network connection lost. Please check your internet.',
            ),
          ),

          // Server Error
          _buildExampleCard(
            context,
            'Server Error',
            CustomErrorWidget(
              error: Exception('Internal Server Error 500'),
              onRetry: () {},
              customMessage:
                  'Our servers are having issues. Please try again later.',
            ),
          ),

          // Permission Denied
          _buildExampleCard(
            context,
            'Permission Denied',
            CustomErrorWidget(
              error: Exception('Permission denied'),
              onRetry: () {},
              customMessage:
                  'You don\'t have permission to access this resource.',
            ),
          ),

          // Not Found Error
          _buildExampleCard(
            context,
            'Not Found Error',
            CustomErrorWidget(
              error: Exception('Resource not found 404'),
              onRetry: () {},
              customMessage: 'The requested item could not be found.',
            ),
          ),

          // Timeout Error
          _buildExampleCard(
            context,
            'Timeout Error',
            CustomErrorWidget(
              error: Exception('TimeoutException: Request timed out'),
              onRetry: () {},
              customMessage: 'Request took too long. Please try again.',
            ),
          ),

          // Generic Error
          _buildExampleCard(
            context,
            'Generic Error',
            CustomErrorWidget(
              error: Exception('Something went wrong'),
              onRetry: () {},
            ),
          ),

          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Shimmer Loading Effects'),

          // Shimmer Grid
          _buildExampleCard(
            context,
            'Shimmer Card List',
            SizedBox(
              height: 200,
              child: Column(
                children: [
                  ShimmerLoading(width: double.infinity, height: 80),
                  const SizedBox(height: 12),
                  ShimmerLoading(width: double.infinity, height: 80),
                  const SizedBox(height: 12),
                  ShimmerLoading(width: double.infinity, height: 80),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Usage Guide
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Usage Guide',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildUsageRow('EmptyStateWidget',
                      'Use when lists are empty or no search results'),
                  _buildUsageRow(
                      'LoadingWidget', 'Use during data fetching operations'),
                  _buildUsageRow('CustomErrorWidget',
                      'Use for error states with retry option'),
                  _buildUsageRow('ShimmerLoading',
                      'Use for skeleton loading in cards/lists'),
                  const SizedBox(height: 16),
                  Text(
                    'All components support theming and are fully responsive.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildExampleCard(BuildContext context, String title, Widget child) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SizedBox(
            height: 200,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageRow(String component, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$component: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
