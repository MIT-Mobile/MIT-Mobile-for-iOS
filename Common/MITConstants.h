#import <Foundation/Foundation.h>
#import "MITResourceConstants.h"

// keys for NSUserDefaults dictionary go here (app preferences)
extern NSString * const MITModuleTabOrderKey;
extern NSString * const MITActiveModuleKey;
extern NSString * const MITNewsTwoFirstRunKey;
extern NSString * const MITEventsModuleInSortOrderKey;
extern NSString * const EmergencyInfoKey;
extern NSString * const EmergencyLastUpdatedKey;
extern NSString * const ShuttleSubscriptionsKey;
extern NSString * const TwitterShareUsernameKey;
extern NSString * const MITDeviceIdKey;
extern NSString * const MITPassCodeKey;
extern NSString * const DeviceTokenKey;
extern NSString * const MITUnreadNotificationsKey;
extern NSString * const PushNotificationSettingsKey;
extern NSString * const MITModulesSavedStateKey;
extern NSString * const CachedMapSearchQueryKey;
extern NSString * const LibrariesLinksUpdatedKey;
extern NSString * const LibrariesLinksKey;

extern NSString * const MITInternalURLScheme;

// module tags
extern NSString * const CalendarTag;
extern NSString * const EmergencyTag;
extern NSString * const CampusMapTag;
extern NSString * const DiningTag;
extern NSString * const NewsOfficeTag;
extern NSString * const DirectoryTag;
extern NSString * const ShuttleTag;
extern NSString * const ToursTag;
extern NSString * const SettingsTag;
extern NSString * const AboutTag;
extern NSString * const LinksTag;
extern NSString * const QRReaderTag;
extern NSString * const FacilitiesTag;
extern NSString * const LibrariesTag;

// module tags
extern NSString * const MITModuleTagCalendar;
extern NSString * const MITModuleTagEmergency;
extern NSString * const MITModuleTagCampusMap;
extern NSString * const MITModuleTagDining;
extern NSString * const MITModuleTagNewsOffice;
extern NSString * const MITModuleTagDirectory;
extern NSString * const MITModuleTagShuttle;
extern NSString * const MITModuleTagTours;
extern NSString * const MITModuleTagSettings;
extern NSString * const MITModuleTagAbout;
extern NSString * const MITModuleTagLinks;
extern NSString * const MITModuleTagQRReader;
extern NSString * const MITModuleTagFacilities;
extern NSString * const MITModuleTagLibraries;
extern NSString * const MITModuleTagMarty;

// notification names
extern NSString * const EmergencyInfoDidLoadNotification;
extern NSString * const EmergencyInfoDidFailToLoadNotification;
extern NSString * const EmergencyInfoDidChangeNotification;
extern NSString * const EmergencyContactsDidLoadNotification;

extern NSString * const ShuttleAlertRemoved;

extern NSString * const UnreadBadgeValuesChangeNotification;

// core data entity names
extern NSString * const NewsStoryEntityName;
extern NSString * const NewsCategoryEntityName;
extern NSString * const NewsImageEntityName;
extern NSString * const NewsImageRepEntityName;
extern NSString * const PersonDetailsEntityName;
extern NSString * const EmergencyInfoEntityName;
extern NSString * const EmergencyContactEntityName;
extern NSString * const ShuttleRouteEntityName;
extern NSString * const ShuttleStopEntityName;
extern NSString * const ShuttleRouteStopEntityName;
extern NSString * const CalendarEventEntityName;
extern NSString * const CalendarCategoryEntityName;
extern NSString * const CampusMapSearchEntityName;
extern NSString * const CampusTourEntityName;
extern NSString * const TourSiteOrRouteEntityName;
extern NSString * const CampusTourSideTripEntityName;
extern NSString * const TourStartLocationEntityName;
extern NSString * const QRReaderResultEntityName;

// resource names

// action accessory types
typedef enum {
    MITAccessoryViewEmail,
    MITAccessoryViewMap,
    MITAccessoryViewPeople,
    MITAccessoryViewPhone,
    MITAccessoryViewExternal,
	MITAccessoryViewEmergency,
    MITAccessoryViewSecure,
    MITAccessoryViewCalendar
} MITAccessoryViewType;

// Info.plist additions
extern NSString * const MITBuildRevisionKey;
extern NSString * const MITBuildDescriptionKey;

// App-wide error domain
extern NSString * const MITErrorDomain;

enum {
    MITMobileRequestUnknownError = 0,
    MITMobileRequestTouchstoneError,
    MITMobileRequestInvalidLoginError = NSURLErrorUserAuthenticationRequired,
    MITRequestInProgressError
};

extern NSString * const MobileLoginKeychainIdentifier;
