/// Accounts run by the Note With Us team. Their notes and profile show an
/// "Official" badge. Kept in the app, not on the profile, so no one can
/// give themselves the badge.
///
/// Add the team account's uid here once it exists (Firebase console,
/// Authentication, User UID).
const Set<String> officialAccountIds = {};

bool isOfficial(String uid) => officialAccountIds.contains(uid);
