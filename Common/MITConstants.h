#import <Foundation/Foundation.h>
#import "MITBuildInfo.h"

// common URLs
extern NSString * const MITMobileWebDomainString;
extern NSString * const MITMobileWebAPIURLString;

// keys for NSUserDefaults dictionary go here (app preferences)
extern NSString * const MITModuleTabOrderKey;
extern NSString * const MITActiveModuleKey;
extern NSString * const EmergencyInfoKey;
extern NSString * const EmergencyLastUpdatedKey;
extern NSString * const EmergencyUnreadCountKey;
extern NSString * const ShuttleSubscriptionsKey;
extern NSString * const MITDeviceIdKey;
extern NSString * const MITPassCodeKey;
extern NSString * const DeviceTokenKey;
extern NSString * const MITUnreadNotificationsKey;
extern NSString * const PushNotificationSettingsKey;

extern NSString * const MITInternalURLScheme;


// module tags
extern NSString * const EmergencyTag;
extern NSString * const CampusMapTag;
extern NSString * const NewsOfficeTag;
extern NSString * const DirectoryTag;
extern NSString * const StellarTag;
extern NSString * const ShuttleTag;
extern NSString * const MobileWebTag;
extern NSString * const SettingsTag;
extern NSString * const AboutTag;

// notification names
extern NSString * const EmergencyInfoDidLoadNotification;
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
extern NSString * const StellarCourseEntityName;
extern NSString * const StellarClassEntityName;
extern NSString * const StellarClassTimeEntityName;
extern NSString * const StellarStaffMemberEntityName;
extern NSString * const StellarAnnouncementEntityName;
extern NSString * const EmergencyInfoEntityName;
extern NSString * const EmergencyContactEntityName;

// resource names
extern NSString * const MITImageNameBackground;

extern NSString * const MITImageNameEmail;
extern NSString * const MITImageNameEmailHighlight;
extern NSString * const MITImageNameMap;
extern NSString * const MITImageNameMapHighlight;
extern NSString * const MITImageNamePeople;
extern NSString * const MITImageNamePeopleHighlight;
extern NSString * const MITImageNamePhone;
extern NSString * const MITImageNamePhoneHighlight;
extern NSString * const MITImageNameExternal;
extern NSString * const MITImageNameExternalHighlight;
extern NSString * const MITImageNameEmergency;
extern NSString * const MITImageNameEmergencyHighlight;
extern NSString * const MITImageNameSecure;
extern NSString * const MITImageNameSecureHighlight;

extern NSString * const MITImageNameScrollTabBackgroundOpaque;
extern NSString * const MITImageNameScrollTabBackgroundTranslucent;
extern NSString * const MITImageNameScrollTabLeftEndCap;
extern NSString * const MITImageNameScrollTabRightEndCap;
extern NSString * const MITImageNameScrollTabSelectedTab;

// action accessory types

typedef enum {
    MITAccessoryViewEmail,
    MITAccessoryViewMap,
    MITAccessoryViewPeople,
    MITAccessoryViewPhone,
    MITAccessoryViewExternal,
	MITAccessoryViewEmergency,
    MITAccessoryViewSecure
} MITAccessoryViewType;
