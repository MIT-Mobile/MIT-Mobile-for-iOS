#import "MITConstants.h"

// keys for NSUserDefaults dictionary go here (app preferences)
NSString * const MITModuleTabOrderKey = @"MITModuleTabOrder";
NSString * const MITActiveModuleKey = @"ActiveModule";
NSString * const MITNewsTwoFirstRunKey = @"MITNews2ClearedCachedArticles";
NSString * const MITEventsModuleInSortOrderKey = @"MITEventsModuleInSortOrder";
NSString * const ShuttleSubscriptionsKey = @"ActiveShuttleSubscriptions";
NSString * const TwitterShareUsernameKey = @"TwitterShareUsername";
NSString * const MITDeviceIdKey = @"device_id";
NSString * const MITPassCodeKey = @"pass_key";
NSString * const DeviceTokenKey = @"DeviceToken";
NSString * const MITUnreadNotificationsKey = @"UnreadNotifications";
NSString * const PushNotificationSettingsKey = @"ModulesDisabledForPush";
NSString * const MITModulesSavedStateKey = @"MITModulesSavedState";
NSString * const CachedMapSearchQueryKey = @"CachedMapSearchQuerey";
NSString * const LibrariesLinksUpdatedKey = @"LibrariesLinksUpdated";
NSString * const LibrariesLinksKey = @"LibrariesLinks";

NSString * const MITInternalURLScheme = @"mitmobile";


// module tags
NSString * const CalendarTag   = @"calendar";
NSString * const EmergencyTag  = @"emergencyinfo";
NSString * const CampusMapTag  = @"map";
NSString * const DiningTag     = @"dining";
NSString * const NewsOfficeTag = @"newsoffice";
NSString * const DirectoryTag  = @"people";
NSString * const ShuttleTag    = @"shuttletrack";
NSString * const ToursTag      = @"tours";
NSString * const SettingsTag   = @"settings";
NSString * const AboutTag      = @"about";
NSString * const LinksTag      = @"links";
NSString * const QRReaderTag    = @"qrreader";
NSString * const FacilitiesTag    = @"facilities";
NSString * const LibrariesTag   = @"libraries";

NSString * const MITModuleTagCalendar   = @"calendar";
NSString * const MITModuleTagEmergency  = @"emergencyinfo";
NSString * const MITModuleTagCampusMap  = @"map";
NSString * const MITModuleTagDining     = @"dining";
NSString * const MITModuleTagNewsOffice = @"newsoffice";
NSString * const MITModuleTagDirectory  = @"people";
NSString * const MITModuleTagShuttle    = @"shuttletrack";
NSString * const MITModuleTagTours      = @"tours";
NSString * const MITModuleTagSettings   = @"settings";
NSString * const MITModuleTagAbout      = @"about";
NSString * const MITModuleTagLinks      = @"links";
NSString * const MITModuleTagQRReader   = @"qrreader";
NSString * const MITModuleTagFacilities = @"facilities";
NSString * const MITModuleTagLibraries  = @"libraries";
NSString * const MITModuleTagMobius     = @"mobius";


// notification names
NSString * const EmergencyInfoDidLoadNotification = @"MITEmergencyInfoDidLoadNotification";
NSString * const EmergencyInfoDidFailToLoadNotification = @"MITEmergencyInfoDidFailToLoadNotification";
NSString * const EmergencyInfoDidChangeNotification = @"MITEmergencyInfoDidChangeNotification";
NSString * const EmergencyContactsDidLoadNotification = @"MITEmergencyContactsDidLoadNotification";

NSString * const ShuttleAlertRemoved = @"MITShuttleAlertRemovedNotification";

NSString * const UnreadBadgeValuesChangeNotification = @"UnreadBadgeValuesChangeNotification";

// core data entity names
NSString * const NewsStoryEntityName = @"NewsStory";
NSString * const NewsCategoryEntityName = @"NewsCategory";
NSString * const NewsImageEntityName = @"NewsImage";
NSString * const NewsImageRepEntityName = @"NewsImageRep";
NSString * const PersonDetailsEntityName = @"PersonDetails";
NSString * const EmergencyInfoEntityName = @"EmergencyInfo";
NSString * const EmergencyContactEntityName = @"EmergencyContact";
NSString * const ShuttleRouteEntityName = @"ShuttleRouteCache";
NSString * const ShuttleStopEntityName = @"ShuttleStopLocation";
NSString * const ShuttleRouteStopEntityName = @"ShuttleRouteStop";
NSString * const CalendarEventEntityName = @"MITCalendarEvent";
NSString * const CalendarCategoryEntityName = @"EventCategory";
NSString * const CampusMapSearchEntityName = @"MapSearch";
NSString * const CampusTourEntityName = @"CampusTour";
NSString * const TourSiteOrRouteEntityName = @"TourSiteOrRoute";
NSString * const CampusTourSideTripEntityName = @"CampusTourSideTrip";
NSString * const TourStartLocationEntityName = @"TourStartLocation";
NSString * const QRReaderResultEntityName = @"QRReaderResult";

// Info.plist additions

NSString * const MITBuildRevisionKey = @"MITBuildRevision";
NSString * const MITBuildDescriptionKey = @"MITBuildDescription";


/* Touchstone/Shibboleth-related errors */
NSString * const MITErrorDomain = @"edu.mit.mobile.Error";

NSString* const MobileLoginKeychainIdentifier = @"edu.mit.mobile.MobileWebLogin";
