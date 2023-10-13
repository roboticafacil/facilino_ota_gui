class ProjectOptions
{
  List<dynamic> boards;
  List<dynamic> versions;
  List<dynamic> filters;
  List<dynamic> languages;

  List<int> _boardIDs=[];
  List<int> _versionIDs=[];
  List<int> _filterIDs=[];
  List<int> _langIDs=[];

  List<int> get boardIDs {
    return _boardIDs;
  }
  List<int> get versionIDs {
    return _versionIDs;
  }
  List<int> get filterIDs {
    return _filterIDs;
  }
  List<int> get langIDs {
    return _langIDs;
  }

  ProjectOptions({required this.boards,required this.versions,required this.filters, required this.languages}){
    _boardIDs.clear();
    for (var board in boards) {
      int id = int.parse(board["id"]);
      _boardIDs.add(id);
    }
    _versionIDs.clear();
    for (var version in versions) {
      int id = int.parse(version["id"]);
      _versionIDs.add(id);
    }
    _filterIDs.clear();
    for (var filter in filters) {
      int id = int.parse(filter["id"]);
      _filterIDs.add(id);
    }
    _langIDs.clear();
    for (var lang in languages) {
      int id = int.parse(lang["id"]);
      _langIDs.add(id);
    }
  }

}