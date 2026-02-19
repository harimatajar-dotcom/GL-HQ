enum FieldType { number, text, paymentArray }

class ReportField {
  final String key;
  final String label;
  final FieldType type;
  final String emoji;
  final bool required;
  final String? hint;

  const ReportField({
    required this.key,
    required this.label,
    required this.type,
    required this.emoji,
    this.required = false,
    this.hint,
  });
}

const Map<String, List<ReportField>> roleReportFields = {
  'sales_rep': [
    ReportField(key: 'calls_made', label: 'Calls Made', type: FieldType.number, emoji: '📞', required: true),
    ReportField(key: 'calls_connected', label: 'Calls Connected', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'demos_scheduled', label: 'Demos Scheduled', type: FieldType.number, emoji: '📅'),
    ReportField(key: 'demos_completed', label: 'Demos Completed', type: FieldType.number, emoji: '🎯'),
    ReportField(key: 'trials', label: 'Trials Started', type: FieldType.number, emoji: '🧪'),
    ReportField(key: 'payments_closed', label: 'Payments Closed', type: FieldType.number, emoji: '💰'),
    ReportField(key: 'payments_amount', label: 'Payment Amount (₹)', type: FieldType.number, emoji: '💵'),
    ReportField(key: 'hot_leads', label: 'Hot Leads', type: FieldType.text, emoji: '🔥', hint: 'List promising leads...'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝', hint: 'Any additional notes...'),
  ],
  'secretary': [
    ReportField(key: 'payments', label: 'Payments Received', type: FieldType.paymentArray, emoji: '💳', required: true),
    ReportField(key: 'tickets_handled', label: 'Tickets Handled', type: FieldType.number, emoji: '🎫'),
    ReportField(key: 'license_updates', label: 'License Updates', type: FieldType.number, emoji: '📄'),
    ReportField(key: 'followups', label: 'Follow-ups Done', type: FieldType.number, emoji: '📞'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'support': [
    ReportField(key: 'tickets_handled', label: 'Tickets Handled', type: FieldType.number, emoji: '🎫', required: true),
    ReportField(key: 'tickets_resolved', label: 'Tickets Resolved', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'avg_response_time', label: 'Avg Response Time (min)', type: FieldType.number, emoji: '⏱️'),
    ReportField(key: 'escalation_count', label: 'Escalations', type: FieldType.number, emoji: '⬆️'),
    ReportField(key: 'escalation_details', label: 'Escalation Details', type: FieldType.text, emoji: '📋'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'hr': [
    ReportField(key: 'attendance', label: 'Attendance Summary', type: FieldType.text, emoji: '📊', required: true),
    ReportField(key: 'leave_requests', label: 'Leave Requests', type: FieldType.number, emoji: '🏖️'),
    ReportField(key: 'interviews', label: 'Interviews Conducted', type: FieldType.number, emoji: '🤝'),
    ReportField(key: 'issues', label: 'HR Issues', type: FieldType.text, emoji: '⚠️'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'finance': [
    ReportField(key: 'invoices', label: 'Invoices Generated', type: FieldType.number, emoji: '🧾', required: true),
    ReportField(key: 'collected_count', label: 'Payments Collected', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'collected_amount', label: 'Collected Amount (₹)', type: FieldType.number, emoji: '💵'),
    ReportField(key: 'pending_count', label: 'Pending Payments', type: FieldType.number, emoji: '⏳'),
    ReportField(key: 'pending_amount', label: 'Pending Amount (₹)', type: FieldType.number, emoji: '💸'),
    ReportField(key: 'expenses_count', label: 'Expenses Logged', type: FieldType.number, emoji: '📤'),
    ReportField(key: 'expenses_amount', label: 'Expenses Amount (₹)', type: FieldType.number, emoji: '💰'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'developer': [
    ReportField(key: 'tasks', label: 'Tasks Worked On', type: FieldType.text, emoji: '💻', required: true, hint: 'What did you work on today?'),
    ReportField(key: 'commits', label: 'Commits Made', type: FieldType.number, emoji: '📦'),
    ReportField(key: 'bugs_fixed', label: 'Bugs Fixed', type: FieldType.number, emoji: '🐛'),
    ReportField(key: 'blockers', label: 'Blockers', type: FieldType.text, emoji: '🚧', hint: 'Any blockers?'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'tester': [
    ReportField(key: 'test_cases', label: 'Test Cases Run', type: FieldType.number, emoji: '🧪', required: true),
    ReportField(key: 'bugs_found', label: 'Bugs Found', type: FieldType.number, emoji: '🐛'),
    ReportField(key: 'bugs_verified', label: 'Bugs Verified', type: FieldType.number, emoji: '✅'),
    ReportField(key: 'blockers', label: 'Blockers', type: FieldType.text, emoji: '🚧'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
  'admin': [
    ReportField(key: 'tasks', label: 'Tasks & Activities', type: FieldType.text, emoji: '⚡', required: true, hint: 'What did you work on today?'),
    ReportField(key: 'decisions', label: 'Key Decisions', type: FieldType.text, emoji: '🎯', hint: 'Important decisions made...'),
    ReportField(key: 'notes', label: 'Notes', type: FieldType.text, emoji: '📝'),
  ],
};
