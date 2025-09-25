class UserModel {
  final int? id;
  final String? name;
  final String? username;
  final String? email;
  final AddressModel? address;
  final String? phone;
  final String? website;
  final CompanyModel? company;

  UserModel({
    this.id,
    this.name,
    this.username,
    this.email,
    this.address,
    this.phone,
    this.website,
    this.company,
  });

  UserModel copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    AddressModel? address,
    String? phone,
    String? website,
    CompanyModel? company,
  }) => UserModel(
    id: id ?? this.id,
    name: name ?? this.name,
    username: username ?? this.username,
    email: email ?? this.email,
    address: address ?? this.address,
    phone: phone ?? this.phone,
    website: website ?? this.website,
    company: company ?? this.company,
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    username: json['username'],
    email: json['email'],
    address: json['address'] == null
        ? null
        : AddressModel.fromJson(json['address']),
    phone: json['phone'],
    website: json['website'],
    company: json['company'] == null
        ? null
        : CompanyModel.fromJson(json['company']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'address': address?.toJson(),
    'phone': phone,
    'website': website,
    'company': company?.toJson(),
  };
}

class AddressModel {
  final String? street;
  final String? suite;
  final String? city;
  final String? zipcode;
  final Geo? geo;

  AddressModel({this.street, this.suite, this.city, this.zipcode, this.geo});

  AddressModel copyWith({
    String? street,
    String? suite,
    String? city,
    String? zipcode,
    Geo? geo,
  }) => AddressModel(
    street: street ?? this.street,
    suite: suite ?? this.suite,
    city: city ?? this.city,
    zipcode: zipcode ?? this.zipcode,
    geo: geo ?? this.geo,
  );

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    street: json['street'],
    suite: json['suite'],
    city: json['city'],
    zipcode: json['zipcode'],
    geo: json['geo'] == null ? null : Geo.fromJson(json['geo']),
  );

  Map<String, dynamic> toJson() => {
    'street': street,
    'suite': suite,
    'city': city,
    'zipcode': zipcode,
    'geo': geo?.toJson(),
  };
}

class Geo {
  final String? lat;
  final String? lng;

  Geo({this.lat, this.lng});

  Geo copyWith({String? lat, String? lng}) =>
      Geo(lat: lat ?? this.lat, lng: lng ?? this.lng);

  factory Geo.fromJson(Map<String, dynamic> json) =>
      Geo(lat: json['lat'], lng: json['lng']);

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class CompanyModel {
  final String? name;
  final String? catchPhrase;
  final String? bs;

  CompanyModel({this.name, this.catchPhrase, this.bs});

  CompanyModel copyWith({String? name, String? catchPhrase, String? bs}) =>
      CompanyModel(
        name: name ?? this.name,
        catchPhrase: catchPhrase ?? this.catchPhrase,
        bs: bs ?? this.bs,
      );

  factory CompanyModel.fromJson(Map<String, dynamic> json) => CompanyModel(
    name: json['name'],
    catchPhrase: json['catchPhrase'],
    bs: json['bs'],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'catchPhrase': catchPhrase,
    'bs': bs,
  };
}
