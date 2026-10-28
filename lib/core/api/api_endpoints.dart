/// Central list of API endpoint paths (relative to the API base URL).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String updateProfile = '/auth/profile';
  static const String changePassword = '/auth/password';
  static const String sendReset = '/auth/reset/send';

  // Email OTP change flow
  static const String sendCurrentEmailOtp = '/auth/email/otp/send-current';
  static const String verifyCurrentEmail = '/auth/email/otp/verify-current';
  static const String sendNewEmailOtp = '/auth/email/otp/send-new';
  static const String verifyNewEmail = '/auth/email/otp/verify-new';

  // ── Dashboard ─────────────────────────────────────────────────────────────
  static const String dashboard = '/dashboard';

  // ── Properties ────────────────────────────────────────────────────────────
  static const String properties = '/properties';
  static String property(int id) => '/properties/$id';
  static String propertyImages(int id) => '/properties/$id/images';
  static String propertyImage(int propertyId, int imageId) =>
      '/properties/$propertyId/images/$imageId';
  static String propertyCover(int propertyId, int imageId) =>
      '/properties/$propertyId/images/$imageId/cover';
  static const String propertyAgents = '/properties/agents';

  // ── Leads ─────────────────────────────────────────────────────────────────
  static const String leads = '/leads';
  static String lead(int id) => '/leads/$id';
  static String leadActivities(int id) => '/leads/$id/activities';
  static String leadAddActivity(int id) => '/leads/$id/activities';
  static String leadReassign(int id) => '/leads/$id/reassign';
  static String leadStatus(int id) => '/leads/$id/status';
  static String leadConvert(int id) => '/leads/$id/convert';
  static const String leadImportTemplate = '/leads/import/template';
  static const String leadImport = '/leads/import';

  // ── Pipeline / Deals ──────────────────────────────────────────────────────
  static const String pipeline = '/pipeline';
  static String deal(int id) => '/pipeline/$id';
  static String dealMoveStage(int id) => '/pipeline/$id/stage';

  // ── Customers ─────────────────────────────────────────────────────────────
  static const String customers = '/customers';
  static String customer(int id) => '/customers/$id';

  // ── Site Visits ───────────────────────────────────────────────────────────
  static const String siteVisits = '/site-visits';
  static String siteVisit(int id) => '/site-visits/$id';

  // ── Tasks ─────────────────────────────────────────────────────────────────
  static const String tasks = '/tasks';
  static String task(int id) => '/tasks/$id';

  // ── Bookings ──────────────────────────────────────────────────────────────
  static const String bookings = '/bookings';
  static String booking(int id) => '/bookings/$id';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const String payments = '/payments';
  static String payment(int id) => '/payments/$id';

  // ── Media ─────────────────────────────────────────────────────────────────
  static const String media = '/media';
  static String mediaItem(int id) => '/media/$id';

  // ── Marketing ─────────────────────────────────────────────────────────────
  static const String campaigns = '/campaigns';
  static String campaign(int id) => '/campaigns/$id';

  // ── CMS ───────────────────────────────────────────────────────────────────
  static const String cms = '/cms';
  static String cmsSection(String id) => '/cms/sections/$id';
  static const String cmsFeatured = '/cms/featured';

  // ── Users ─────────────────────────────────────────────────────────────────
  static const String users = '/users';
  static String user(int id) => '/users/$id';

  // ── Roles / Permissions ───────────────────────────────────────────────────
  static const String roles = '/roles';
  static String role(int id) => '/roles/$id';
  static const String permissions = '/permissions';

  // ── Settings ──────────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String settingsSmtp = '/settings/smtp';
  static const String testSmtp = '/settings/smtp/test';

  // ── Reports ───────────────────────────────────────────────────────────────
  static const String reports = '/reports';
  static const String reportExport = '/reports/export';
  static const String reportExportPdf = '/reports/export-pdf';

  // ── Notifications ─────────────────────────────────────────────────────────
  static const String notifications = '/notifications';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(int id) => '/notifications/$id/read';
}