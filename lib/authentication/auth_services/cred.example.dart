// ignore_for_file: non_constant_identifier_names

// TEMPLATE. Copy this file to `cred.dart` in the same folder and fill in your
// own Supabase project URL and anon (publishable) key. `cred.dart` is
// gitignored, so real credentials never land in this public repo — the real
// values live only in the private build repo (Project-Atomic-Notes-New).
//
// The anon key is publishable and safe to embed in a client: Row Level
// Security is what actually protects the data. The service_role key must NEVER
// be placed in a client app.

class CredService {
  final String PROJECT_URL = "YOUR_SUPABASE_PROJECT_URL";
  final String API_KEY = "YOUR_SUPABASE_ANON_KEY";
}
