#import "MITModule.h"

@class CampusTourHomeController;

@interface ToursModule : MITModule {
    
    CampusTourHomeController *homeController;

}

@property (nonatomic, retain) CampusTourHomeController *homeController;

@end
