#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "MITResourceConstants.h"

#define MITCheckAsset(asset) { \
    XCTAssertGreaterThan([asset length], 0, @"%s does not contain a valid resource name",#asset); \
    XCTAssertNotNil([UIImage imageNamed:asset], @"Asset %s (%@) could not be found",  #asset, asset); \
}

#define MITCheckResource(resource) MITCheckResourceInDirectory(resource,nil)

#define MITCheckResourceInDirectory(resource,directory) {\
    XCTAssertGreaterThan([resource length], 0, @"%s does not contain a valid resource name",#resource);\
    NSString *extension = [resource pathExtension];\
    NSString *resourceName = [[resource lastPathComponent] stringByDeletingPathExtension]; \
    NSString *path = [[NSBundle mainBundle] pathForResource:resourceName ofType:extension inDirectory:directory];\
    XCTAssertNotNil(path,@"Resource %s (%@) could not be found",#resource,resource);\
}

@interface MITApplicationResourceTests : XCTestCase

@end

@implementation MITApplicationResourceTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testApplicationResources {
    MITCheckResource(MITResourceDiningMealFarmToFork);
    MITCheckResource(MITResourceDiningMealGlutenFree);
    MITCheckResource(MITResourceDiningMealHalal);
    MITCheckResource(MITResourceDiningMealHumane);
    MITCheckResource(MITResourceDiningMealInBalance);
    MITCheckResource(MITResourceDiningMealKosher);
    MITCheckResource(MITResourceDiningMealOrganic);
    MITCheckResource(MITResourceDiningMealSeafoodWatch);
    MITCheckResource(MITResourceDiningMealVegan);
    MITCheckResource(MITResourceDiningMealVegetarian);
    MITCheckResource(MITResourceDiningMealWellBeing);

}

- (void)testAssetCatalog {
    MITCheckAsset(MITImageAboutModuleIcon);
    MITCheckAsset(MITImageBuildingServicesModuleIcon);
    MITCheckAsset(MITImageEventsModuleIcon);
    MITCheckAsset(MITImageMapModuleIcon);
    MITCheckAsset(MITImageDiningModuleIcon);
    MITCheckAsset(MITImageEmergencyModuleIcon);
    MITCheckAsset(MITImageLibrariesModuleIcon);
    MITCheckAsset(MITImageLinksModuleIcon);
    MITCheckAsset(MITImageNewsModuleIcon);
    MITCheckAsset(MITImagePeopleModuleIcon);
    MITCheckAsset(MITImageScannerModuleIcon);
    MITCheckAsset(MITImageSettingsModuleIcon);
    MITCheckAsset(MITImageShuttlesModuleIcon);
    MITCheckAsset(MITImageToursModuleIcon);

#pragma mark - Dining
    MITCheckAsset(MITImageDiningBookmark);
    MITCheckAsset(MITImageDiningBookmarkSelected);
    MITCheckAsset(MITImageDiningInfo);
    MITCheckAsset(MITImageDiningInfoHighlighted);
    MITCheckAsset(MITImageDiningRotateDevice);

#pragma mark Meal Types
    MITCheckAsset(MITImageDiningMealFarmToFork);
    MITCheckAsset(MITImageDiningMealGlutenFree);
    MITCheckAsset(MITImageDiningMealHalal);
    MITCheckAsset(MITImageDiningMealHumane);
    MITCheckAsset(MITImageDiningMealInBalance);
    MITCheckAsset(MITImageDiningMealKosher);
    MITCheckAsset(MITImageDiningMealOrganic);
    MITCheckAsset(MITImageDiningMealSeafoodWatch);
    MITCheckAsset(MITImageDiningMealVegan);
    MITCheckAsset(MITImageDiningMealVegetarian);
    MITCheckAsset(MITImageDiningMealWellBeing);

#pragma mark - Events (Calendar)
    MITCheckAsset(MITImageEventsDayPickerButton);
    MITCheckAsset(MITImageEventsPadChevronUp);
    MITCheckAsset(MITImageEventsPadChevronDown);

#pragma mark - Libraries
    MITCheckAsset(MITImageLibrariesCheckmark);
    MITCheckAsset(MITImageLibrariesCheckmarkSelected);

#pragma mark Status Types
    MITCheckAsset(MITImageLibrariesStatusAlert);
    MITCheckAsset(MITImageLibrariesStatusError);
    MITCheckAsset(MITImageLibrariesStatusOK);
    MITCheckAsset(MITImageLibrariesStatusReady);

#pragma mark - Map
    MITCheckAsset(MITImageMapBrowseBuildings);
    MITCheckAsset(MITImageMapBrowseFoodServices);
    MITCheckAsset(MITImageMapBrowseResidences);
    MITCheckAsset(MITImageMapLocation);
    MITCheckAsset(MITImageMapLocationHighlighted);
    MITCheckAsset(MITImageMapAnnotationUserLocation);
    MITCheckAsset(MITImageMapAnnotationPin);
    MITCheckAsset(MITImageMapAnnotationPlacePin);


#pragma mark - News
    MITCheckAsset(MITImageNewsImagePlaceholder);
    MITCheckAsset(MITImageNewsGridView);

    MITCheckAsset(MITImageNewsTemplateButtonBookmark);
    MITCheckAsset(MITImageNewsTemplateButtonShare);
    MITCheckAsset(MITImageNewsTemplateButtonShareHighlighted);
    MITCheckAsset(MITImageNewsTemplateButtonZoomIn);


#pragma mark - People Directory
    MITCheckAsset(MITImagePeopleDirectoryDestructiveButton);
    MITCheckAsset(MITImagePeopleDirectoryDestructiveButtonHighlighted);


#pragma mark - Scanner
    MITCheckAsset(MITImageScannerCameraUnsupported);
    MITCheckAsset(MITImageScannerSampleBarcode);
    MITCheckAsset(MITImageScannerSampleQRCode);
    MITCheckAsset(MITImageScannerMissingImage);
    MITCheckAsset(MITImageScannerScanBarButton);


#pragma mark - Shuttles
    MITCheckAsset(MITImageShuttlesRouteInService);
    MITCheckAsset(MITImageShuttlesRouteNotInService);
    MITCheckAsset(MITImageShuttlesRoutePredictionsUnavailable);
    MITCheckAsset(MITImageShuttlesBusBubble);
    MITCheckAsset(MITImageShuttlesAlertOn);
    MITCheckAsset(MITImageShuttlesAlertOff);
    MITCheckAsset(MITImageShuttlesAnnotationBus);
    MITCheckAsset(MITImageShuttlesAnnotationNextStop);
    MITCheckAsset(MITImageShuttlesAnnotationNextStopSelected);
    MITCheckAsset(MITImageShuttlesAnnotationCurrentStop);
    MITCheckAsset(MITImageShuttlesAnnotationCurrentStopSelected);


#pragma mark - Tours
    MITCheckAsset(MITImageToursWBRogers);
    MITCheckAsset(MITImageToursKillian);
    MITCheckAsset(MITImageToursMITSeal);
    MITCheckAsset(MITImageToursSideTripArrow);
    MITCheckAsset(MITImageToursScrimNotSure);
    MITCheckAsset(MITImageToursScrimNotSureTop);

    MITCheckAsset(MITImageToursWallpaperKillian);
    MITCheckAsset(MITImageToursWallpaperStata);
    MITCheckAsset(MITImageToursWallpaperGreatSail);

#pragma mark Current Tour Progress Bar
    MITCheckAsset(MITImageToursProgressBarBackground);
    MITCheckAsset(MITImageToursProgressBarCurrent);
    MITCheckAsset(MITImageToursProgressBarDivider);
    MITCheckAsset(MITImageToursProgressBarPast);
    MITCheckAsset(MITImageToursProgressBarTrench);

#pragma mark Toolbar Icons
    MITCheckAsset(MITImageToursToolbarArrowLeft);
    MITCheckAsset(MITImageToursToolbarArrowRight);
    MITCheckAsset(MITImageToursToolbarBackground);
    MITCheckAsset(MITImageToursToolbarCamera);
    MITCheckAsset(MITImageToursToolbarMap);
    MITCheckAsset(MITImageToursToolbarQR);

    MITCheckAsset(MITImageToursButtonAudioPause);
    MITCheckAsset(MITImageToursButtonAudio);
    MITCheckAsset(MITImageToursButtonMap);
    MITCheckAsset(MITImageToursButtonMapHighlighted);
    MITCheckAsset(MITImageToursButtonScanQR);
    MITCheckAsset(MITImageToursButtonScanQRHighlighted);
    MITCheckAsset(MITImageToursButtonSidetrip);
    MITCheckAsset(MITImageToursButtonSelectStart);
    MITCheckAsset(MITImageToursButtonSelectStartMerged);
    MITCheckAsset(MITImageToursButtonReturn);

    MITCheckAsset(MITImageToursAnnotationStopInitial);
    MITCheckAsset(MITImageToursAnnotationStopCurrent);
    MITCheckAsset(MITImageToursAnnotationStopUnvisited);
    MITCheckAsset(MITImageToursAnnotationStopVisited);
    MITCheckAsset(MITImageToursAnnotationArrowEnd);
    MITCheckAsset(MITImageToursAnnotationArrowStart);
    MITCheckAsset(MITImageToursMapLegendOverlay);

    MITCheckAsset(MITImageToursTemplateButtonExternalLink);


#pragma mark - Global Assets
    MITCheckAsset(MITImageNameEmail);
    MITCheckAsset(MITImageNameEmailHighlight);
    MITCheckAsset(MITImageNameMap);
    MITCheckAsset(MITImageNameMapHighlight);
    MITCheckAsset(MITImageNamePeople);
    MITCheckAsset(MITImageNamePeopleHighlight);
    MITCheckAsset(MITImageNamePhone);
    MITCheckAsset(MITImageNamePhoneHighlight);
    MITCheckAsset(MITImageActionExternalWhite);
    MITCheckAsset(MITImageActionExternal);
    MITCheckAsset(MITImageActionExternalHighlight);
    MITCheckAsset(MITImageNameEmergency);
    MITCheckAsset(MITImageNameEmergencyHighlight);
    MITCheckAsset(MITImageNameSecure);
    MITCheckAsset(MITImageNameSecureHighlight);
    MITCheckAsset(MITImageNameCalendar);
    MITCheckAsset(MITImageNameCalendarHighlight);
    MITCheckAsset(MITImageNameShare);

    MITCheckAsset(MITImageNameLeftArrow);
    MITCheckAsset(MITImageNameRightArrow);
    MITCheckAsset(MITImageNameUpArrow);
    MITCheckAsset(MITImageNameDownArrow);

    MITCheckAsset(MITImageNameSearch);
    MITCheckAsset(MITImageNameBookmark);
    MITCheckAsset(MITImageDisclosureRight);
    MITCheckAsset(MITImageTransparentPixel);

    MITCheckAsset(MITImageLogoDarkContent);
    MITCheckAsset(MITImageLogoLightContent);
    
#pragma mark UIBarButtonItem icons
    MITCheckAsset(MITImageBarButtonMenu);
    MITCheckAsset(MITImageBarButtonLocation);
    MITCheckAsset(MITImageBarButtonList);
    
    MITCheckAsset(MITImageBarButtonSearch);
    MITCheckAsset(MITImageBarButtonSearchMagnifier);
    
#pragma mark MITTabView Assets
    MITCheckAsset(MITImageTabViewDivider);
    MITCheckAsset(MITImageTabViewHeader);
    MITCheckAsset(MITImageTabViewSummaryButton);
    MITCheckAsset(MITImageTabViewActive);
    MITCheckAsset(MITImageTabViewInactive);
    MITCheckAsset(MITImageTabViewInactiveHighlighted);
}

@end
