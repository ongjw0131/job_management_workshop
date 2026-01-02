/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 15:29:48
/// @modify date 2025-09-11 15:29:48
/// @desc [SupabaseConfig: Configuration constants for Supabase connectivity.]
library;

class SupabaseConfig {
  /// The base URL of the Supabase project used for API requests.
  static const String supabaseUrl = 'https://wulwkmigfhltbjklnyef.supabase.co';

  /// The public anonymous key for Supabase, used for client-side authentication.
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind1bHdrbWlnZmhsdGJqa2xueWVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY0NDE1NTcsImV4cCI6MjA3MjAxNzU1N30.QH5BAEwyZ0yPG9a856peNWDnIZi4zr06CTmQPR_sh78';

  /// The base URL for Supabase Storage services.
  static const String supabaseStorageUrl =
      'https://wulwkmigfhltbjklnyef.storage.supabase.co/storage/v1/s3';
}
