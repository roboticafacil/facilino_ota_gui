class User
{
  String username;
  int id;
  String key;
  String email;
  String first_name;
  String last_name;
  int lang_id;
  bool invited;
  User({required this.username,required this.id,required this.key,required this.email,required this.first_name, required this.last_name,required this.lang_id, required this.invited});
}