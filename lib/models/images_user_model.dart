class ImagesUserModel {
  ImagesUserModel({
    required this.image,



  });
  late final List<String> image;




  ImagesUserModel.fromJson(Map<String, dynamic> json) {
    image = List.from(json['image']).map((e) => e.toString()).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image.map((element) => element).toList(),

    };
  }
}