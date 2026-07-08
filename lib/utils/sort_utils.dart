int compareSizes(String a, String b) {
  String sa = a.trim().toUpperCase();
  String sb = b.trim().toUpperCase();
  
  double? getNumeric(String s) {
    if (s == 'ZERO') return 0.0;
    return double.tryParse(s);
  }

  double? numA = getNumeric(sa);
  double? numB = getNumeric(sb);
  
  if (numA != null && numB != null) {
    return numA.compareTo(numB);
  }
  
  if (numA != null) return -1;
  if (numB != null) return 1;
  
  int getClothingSizeWeight(String s) {
    if (s == 'XXS' || s == '2XS') return 10;
    if (s == 'XS') return 20;
    if (s == 'S') return 30;
    if (s == 'M') return 40;
    if (s == 'L') return 50;
    if (s == 'XL') return 60;
    if (s == 'XXL' || s == '2XL') return 70;
    if (s == 'XXXL' || s == '3XL') return 80;
    if (s == '4XL') return 90;
    if (s == '5XL') return 100;
    if (s == '6XL') return 110;
    
    RegExp regex = RegExp(r'^(\d+)XL$');
    Match? match = regex.firstMatch(s);
    if (match != null) {
      int n = int.parse(match.group(1)!);
      return 60 + (n * 10);
    }
    return 1000; 
  }
  
  int weightA = getClothingSizeWeight(sa);
  int weightB = getClothingSizeWeight(sb);
  
  if (weightA != 1000 && weightB != 1000) {
    return weightA.compareTo(weightB);
  }
  
  if (weightA != 1000) return -1;
  if (weightB != 1000) return 1;
  
  return sa.compareTo(sb);
}

int compareCategories(String a, String b) {
  int catOrder(String cat) {
    if (cat == 'men') return 0;
    if (cat == 'women') return 1;
    if (cat == 'kids') return 2;
    return 3;
  }
  return catOrder(a).compareTo(catOrder(b));
}
