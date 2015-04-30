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

#pragma mark - Libraries
    MITCheckAsset(MITImageLibrariesCheckmark);
    MITCheckAsset(MITImageLibrariesCheckmarkSelected);

#pragma mark Status Types
    MITCheckAsset(MITImageLibrariesStatusAlert);
    MITCheckAsset(MITImageLibrariesStatusError);
    MITCheckAsset(MITImageLibrariesStatusOK);
    MITCheckAsset(MITImageLibrariesStatusReady);

#pragma mark - Map
    MITCheckAsset(MITImageMapAnnotationPlacePin);
    MITCheckAsset(MITImageMapPinBallBlack);
    MITCheckAsset(MITImageMapPinBallBlue);
    MITCheckAsset(MITImageMapPinBallRed);
    MITCheckAsset(MITImageMapPinNeedle);
    MITCheckAsset(MITImageMapPinShadow);
    
    MITCheckAsset(MITImageMapCategoryAthenaClusters);
    MITCheckAsset(MITImageMapCategoryBuildings);
    MITCheckAsset(MITImageMapCategoryCourtsAndGreenspaces);
    MITCheckAsset(MITImageMapCategoryFoodServices);
    MITCheckAsset(MITImageMapCategoryHotels);
    MITCheckAsset(MITImageMapCategoryLibrary);
    MITCheckAsset(MITImageMapCategoryMuseumsAndGalleries);
    MITCheckAsset(MITImageMapCategoryParking);
    MITCheckAsset(MITImageMapCategoryResidences);
    MITCheckAsset(MITImageMapCategoryRooms);
    MITCheckAsset(MITImageMapCategoryStreetsAndLandmarks);

#pragma mark - Mobius
    MITCheckAsset(MITImageMobiusResourceOffline);
    MITCheckAsset(MITImageMobiusAccordionOpened);
    MITCheckAsset(MITImageMobiusAccordionClosed);
    MITCheckAsset(MITImageMobiusBarButtonAdvancedSearch);


#pragma mark - Scanner
    MITCheckAsset(MITImageScannerCameraUnsupported);
    MITCheckAsset(MITImageScannerSampleBarcode);
    MITCheckAsset(MITImageScannerSampleQRCode);
    MITCheckAsset(MITImageScannerMissingImage);


#pragma mark - Shuttles
    MITCheckAsset(MITImageShuttlesInService);
    MITCheckAsset(MITImageShuttlesNotInService);
    MITCheckAsset(MITImageShuttlesUnknown);
    MITCheckAsset(MITImageShuttlesInServiceSmall);
    MITCheckAsset(MITImageShuttlesNotInServiceSmall);
    MITCheckAsset(MITImageShuttlesUnknownSmall);
    
    MITCheckAsset(MITImageShuttlesBusBubble);
    MITCheckAsset(MITImageShuttlesAlertOn);
    MITCheckAsset(MITImageShuttlesAlertOff);
    MITCheckAsset(MITImageShuttlesAnnotationBus);
    MITCheckAsset(MITImageShuttlesAnnotationCurrentStop);


#pragma mark - Tours
    MITCheckAsset(MITImageToursSelfGuidedBackground);
    MITCheckAsset(MITImageToursCircleRed);
    MITCheckAsset(MITImageToursCircleBlue);
    MITCheckAsset(MITImageToursAnnotationArrowStart);
    MITCheckAsset(MITImageToursAnnotationArrowEnd);
    MITCheckAsset(MITImageToursTemplateWhiteActionArrow);
    MITCheckAsset(MITImageToursPadChevronUp);
    MITCheckAsset(MITImageToursPadChevronDown);
    MITCheckAsset(MITImageToursWBRogers);
    MITCheckAsset(MITImageToursKillian);
    MITCheckAsset(MITImageToursMITSeal);


#pragma mark - Global Assets
    MITCheckAsset(MITImageNameEmail);
    MITCheckAsset(MITImageNameMap);
    MITCheckAsset(MITImageNamePeople);
    MITCheckAsset(MITImageNamePhone);
    MITCheckAsset(MITImageActionExternalWhite);
    MITCheckAsset(MITImageActionExternal);
    MITCheckAsset(MITImageNameEmergency);
    MITCheckAsset(MITImageNameSecure);
    MITCheckAsset(MITImageNameCalendar);
    MITCheckAsset(MITImageNameShare);

    MITCheckAsset(MITImageNameLeftArrow);
    MITCheckAsset(MITImageNameRightArrow);
    MITCheckAsset(MITImageNameUpArrow);
    MITCheckAsset(MITImageNameDownArrow);

    MITCheckAsset(MITImageNameSearch);
    MITCheckAsset(MITImageDisclosureRight);
    MITCheckAsset(MITImageCalloutDisclosureRight);
    MITCheckAsset(MITImageTransparentPixel);

    MITCheckAsset(MITImageLogoDarkContent);
    MITCheckAsset(MITImageLogoLightContent);
    
#pragma mark UIBarButtonItem icons
    MITCheckAsset(MITImageBarButtonMenu);
    MITCheckAsset(MITImageBarButtonLocation);
    MITCheckAsset(MITImageBarButtonGrid);
    MITCheckAsset(MITImageBarButtonList);
    MITCheckAsset(MITImageBarButtonListSelected);
    MITCheckAsset(MITImageBarButtonFilter);
    
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
