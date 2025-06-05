/// Data models for the parking manager application
/// Provides structured data classes for ParkingSpot, Booking, and related entities
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for parking spot status
enum SpotStatus {
  available,
  occupied,
  expired,
  inactive;

  /// Convert status to display string
  String get displayName {
    switch (this) {
      case SpotStatus.available:
        return 'Available';
      case SpotStatus.occupied:
        return 'Occupied';
      case SpotStatus.expired:
        return 'Expired';
      case SpotStatus.inactive:
        return 'Inactive';
    }
  }

  /// Convert string to SpotStatus
  static SpotStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return SpotStatus.available;
      case 'occupied':
        return SpotStatus.occupied;
      case 'expired':
        return SpotStatus.expired;
      case 'inactive':
        return SpotStatus.inactive;
      default:
        return SpotStatus.available;
    }
  }
}

/// Enum for booking status
enum BookingStatus {
  active,
  completed,
  cancelled,
  expired;

  /// Convert status to display string
  String get displayName {
    switch (this) {
      case BookingStatus.active:
        return 'Active';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
    }
  }

  /// Convert string to BookingStatus
  static BookingStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BookingStatus.active;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'expired':
        return BookingStatus.expired;
      default:
        return BookingStatus.active;
    }
  }
}

/// Model class for parking spot location
class Location {
  final double latitude;
  final double longitude;
  final String address;

  const Location({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  /// Create Location from Firestore document
  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
    );
  }

  /// Convert Location to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  /// Create a copy with updated fields
  Location copyWith({
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return Location(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  @override
  String toString() {
    return 'Location(latitude: $latitude, longitude: $longitude, address: $address)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.address == address;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ address.hashCode;
  }
}

/// Model class for parking spot
class ParkingSpot {
  final String id;
  final String ownerId;
  final String ownerEmail;
  final Location location;
  final double hourlyRate;
  final SpotStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? currentBookingId;
  final DateTime? occupiedUntil;
  final String? description;
  final List<String> amenities;
  final bool isActive;

  const ParkingSpot({
    required this.id,
    required this.ownerId,
    required this.ownerEmail,
    required this.location,
    required this.hourlyRate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.currentBookingId,
    this.occupiedUntil,
    this.description,
    this.amenities = const [],
    this.isActive = true,
  });

  /// Create ParkingSpot from Firestore document
  factory ParkingSpot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ParkingSpot.fromMap(data, doc.id);
  }

  /// Create ParkingSpot from Map with optional ID
  factory ParkingSpot.fromMap(Map<String, dynamic> map, [String? id]) {
    return ParkingSpot(
      id: id ?? map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      ownerEmail: map['ownerEmail'] as String? ?? '',
      location:
          Location.fromMap(map['location'] as Map<String, dynamic>? ?? {}),
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      status: SpotStatus.fromString(map['status'] as String? ?? 'available'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      currentBookingId: map['currentBookingId'] as String?,
      occupiedUntil: (map['occupiedUntil'] as Timestamp?)?.toDate(),
      description: map['description'] as String?,
      amenities: List<String>.from(map['amenities'] as List? ?? []),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Convert ParkingSpot to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerEmail': ownerEmail,
      'location': location.toMap(),
      'hourlyRate': hourlyRate,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'currentBookingId': currentBookingId,
      'occupiedUntil':
          occupiedUntil != null ? Timestamp.fromDate(occupiedUntil!) : null,
      'description': description,
      'amenities': amenities,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  ParkingSpot copyWith({
    String? id,
    String? ownerId,
    String? ownerEmail,
    Location? location,
    double? hourlyRate,
    SpotStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? currentBookingId,
    DateTime? occupiedUntil,
    String? description,
    List<String>? amenities,
    bool? isActive,
  }) {
    return ParkingSpot(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      location: location ?? this.location,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      occupiedUntil: occupiedUntil ?? this.occupiedUntil,
      description: description ?? this.description,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if the spot is currently expired
  bool get isExpired {
    if (occupiedUntil == null) return false;
    return DateTime.now().isAfter(occupiedUntil!);
  }

  /// Check if the spot is available for booking
  bool get isAvailableForBooking {
    return isActive && status == SpotStatus.available;
  }

  /// Get formatted hourly rate as currency string
  String get formattedRate {
    return '\$${hourlyRate.toStringAsFixed(2)}/hour';
  }

  @override
  String toString() {
    return 'ParkingSpot(id: $id, location: $location, status: $status, rate: $hourlyRate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkingSpot && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

/// Model class for booking
class Booking {
  final String id;
  final String userId;
  final String userEmail;
  final String spotId;
  final ParkingSpot? spot; // Optional populated spot data
  final DateTime startTime;
  final DateTime endTime;
  final double totalCost;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? paymentMethodId;
  final String? notes;
  final bool isVerified;

  const Booking({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.spotId,
    this.spot,
    required this.startTime,
    required this.endTime,
    required this.totalCost,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.paymentMethodId,
    this.notes,
    this.isVerified = false,
  });

  /// Create Booking from Firestore document
  factory Booking.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Booking.fromMap(data, doc.id);
  }

  /// Create Booking from Map with optional ID
  factory Booking.fromMap(Map<String, dynamic> map, [String? id]) {
    return Booking(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      spotId: map['spotId'] as String? ?? '',
      spot: map['spot'] != null
          ? ParkingSpot.fromMap(map['spot'] as Map<String, dynamic>)
          : null,
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0.0,
      status: BookingStatus.fromString(map['status'] as String? ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      paymentMethodId: map['paymentMethodId'] as String?,
      notes: map['notes'] as String?,
      isVerified: map['isVerified'] as bool? ?? false,
    );
  }

  /// Convert Booking to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'spotId': spotId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'totalCost': totalCost,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentMethodId': paymentMethodId,
      'notes': notes,
      'isVerified': isVerified,
    };
  }

  /// Create a copy with updated fields
  Booking copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? spotId,
    ParkingSpot? spot,
    DateTime? startTime,
    DateTime? endTime,
    double? totalCost,
    BookingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentMethodId,
    String? notes,
    bool? isVerified,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      spotId: spotId ?? this.spotId,
      spot: spot ?? this.spot,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalCost: totalCost ?? this.totalCost,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Get booking duration in hours
  double get durationInHours {
    return endTime.difference(startTime).inMinutes / 60.0;
  }

  /// Check if booking is currently active
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return status == BookingStatus.active &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  /// Check if booking has expired
  bool get hasExpired {
    return DateTime.now().isAfter(endTime) && status == BookingStatus.active;
  }

  /// Get formatted total cost as currency string
  String get formattedCost {
    return '\$${totalCost.toStringAsFixed(2)}';
  }

  /// Get formatted duration string
  String get formattedDuration {
    final duration = endTime.difference(startTime);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  @override
  String toString() {
    return 'Booking(id: $id, spotId: $spotId, status: $status, cost: $totalCost)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

/// Model class for user profile
class UserProfile {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.profileImageUrl,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Create UserProfile from Firestore document
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data, doc.id);
  }

  /// Create UserProfile from Map with optional ID
  factory UserProfile.fromMap(Map<String, dynamic> map, [String? id]) {
    return UserProfile(
      id: id ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      firstName: map['firstName'] as String?,
      lastName: map['lastName'] as String?,
      dateOfBirth: (map['dateOfBirth'] as Timestamp?)?.toDate(),
      gender: map['gender'] as String?,
      profileImageUrl: map['profileImageUrl'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Convert UserProfile to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth':
          dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'gender': gender,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get full name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    } else {
      return email;
    }
  }

  /// Get display name for UI
  String get displayName {
    return fullName.isNotEmpty ? fullName : email;
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}
