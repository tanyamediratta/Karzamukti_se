// scheme_data.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class Scheme {
  final String id;
  final String title;
  final String description;
  final double? minimumAmount;
  final double? interestRate;
  final int? timePeriodMonths;
  final String createdAt;

  Scheme({
    required this.id,
    required this.title,
    required this.description,
    this.minimumAmount,
    this.interestRate,
    this.timePeriodMonths,
    required this.createdAt,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    return Scheme(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minimumAmount: (json['minimum_amount'] as num?)?.toDouble(),
      interestRate: (json['interest_rate'] as num?)?.toDouble(),
      timePeriodMonths: json['time_period_months'] as int?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

final supabase = Supabase.instance.client;

Future<List<Scheme>> fetchSchemes() async {
  final response = await supabase
      .from('schemes')
      .select(
        'id, title, description, minimum_amount, interest_rate, time_period_months, created_at',
      )
      .order('created_at', ascending: true);

  print("RAW SCHEMES: $response"); // Debugging

  return response
      .map<Scheme>((row) => Scheme.fromJson(row as Map<String, dynamic>))
      .toList();
}
