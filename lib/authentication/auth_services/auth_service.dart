// ignore_for_file: unnecessary_null_comparison

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthServices {
  late SupabaseClient supabase;
  late String userId = supabase.auth.currentUser!.id;
  AuthServices() {
    supabase = Supabase.instance.client;
  }

  // update user info
  Future<String?> updateUserInfo({
    required String username,
  }) async {
    try {
      await supabase.from('atomicuser').upsert(
          {'username': username, 'user_id': userId},
          onConflict: "user_id");
      return "Username updated wait for refresh";
    } catch (error) {
      // Handle other errors here if needed
      if (error is PostgrestException &&
          error.code == '23505' &&
          error.details == 'Conflict') {
        // Update the existing record if a conflict occurs
        await supabase
            .from('atomicuser')
            .update({'username': username}).eq('user_id', userId);
        return "Username updated wait for refresh";
      } else {
        // Handle other types of errors here
        return "Error updating username";
      }
    }
  }

  // fetch user info from supabase
  Future<String> getUserInfo() async {
    try {
      final data = await supabase
          .from('atomicuser')
          .select('username')
          .eq('user_id', userId)
          .single();
      if (data != null) {
        if (data['username'].toString() == "") {
          return "@atomicuser";
        }
        return "@${data['username']}";
      } else {
        return "@atomicuser";
      }
    } catch (error) {
      return "@atomicuser";
    }
  }
}
