class ItemModel {
  final int id;
  final int userId;
  final int? categoryId;
  final String type; // 'lost' | 'found'
  final String title;
  final String description;
  final String location;
  final String dateOccurred;
  final String? timeOccurred;
  final String? image;
  final String? imageUrl;
  final String? additionalInformation;
  final String status; // 'active' | 'resolved' | 'deleted'
  final String? createdAt;
  final String? updatedAt;
  final String? categoryName;
  final String? posterName;
  final String? posterPhone;
  final String? posterEmail;

  const ItemModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.dateOccurred,
    this.timeOccurred,
    this.image,
    this.imageUrl,
    this.additionalInformation,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.categoryName,
    this.posterName,
    this.posterPhone,
    this.posterEmail,
  });

  bool get isLost    => type == 'lost';
  bool get isFound   => type == 'found';
  bool get isActive  => status == 'active';
  bool get isResolved => status == 'resolved';

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id:                    _parseInt(json['id']),
      userId:                _parseInt(json['user_id']),
      categoryId:            json['category_id'] != null ? _parseInt(json['category_id']) : null,
      type:                  json['type']                   as String? ?? 'lost',
      title:                 json['title']                  as String? ?? '',
      description:           json['description']            as String? ?? '',
      location:              json['location']               as String? ?? '',
      dateOccurred:          json['date_occurred']          as String? ?? '',
      timeOccurred:          json['time_occurred']          as String?,
      image:                 json['image']                  as String?,
      imageUrl:              json['image_url']              as String?,
      additionalInformation: json['additional_information'] as String?,
      status:                json['status']                 as String? ?? 'active',
      createdAt:             json['created_at']             as String?,
      updatedAt:             json['updated_at']             as String?,
      categoryName:          json['category_name']          as String?,
      posterName:            json['poster_name']            as String?,
      posterPhone:           json['poster_phone']           as String?,
      posterEmail:           json['poster_email']           as String?,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'id':                     id,
    'user_id':                userId,
    'category_id':            categoryId,
    'type':                   type,
    'title':                  title,
    'description':            description,
    'location':               location,
    'date_occurred':          dateOccurred,
    'time_occurred':          timeOccurred,
    'image':                  image,
    'image_url':              imageUrl,
    'additional_information': additionalInformation,
    'status':                 status,
    'created_at':             createdAt,
    'updated_at':             updatedAt,
    'category_name':          categoryName,
    'poster_name':            posterName,
  };
}

class PaginationModel {
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  const PaginationModel({
    required this.total,
    required this.page,
    required this.perPage,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      total:      _parseInt(json['total']),
      page:       _parseInt(json['page']),
      perPage:    _parseInt(json['per_page']),
      totalPages: _parseInt(json['total_pages']),
    );
  }

  bool get hasNextPage => page < totalPages;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}
