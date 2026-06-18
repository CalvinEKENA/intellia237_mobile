abstract class TourGuideRepository {
  Future<bool> hasSeenTour(String uid);

  Future<void> markTourSeen(String uid);
}
