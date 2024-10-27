class Route{
  Route({required this.name, required this.path, this.baseUrl=""});

  String name;
  String path;
  String baseUrl;

  get fullPath{
    return "$baseUrl${path.startsWith("/") ? "":"/"}$path";
  }
}

class Routing {
  static final Route home = Route(name:"home",path:"/home");
  static final Route splash = Route(name:"splash",path:"/splash");
}
