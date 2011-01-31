#import "FeatureSection.h"
#import "CoreDataManager.h"
#import "FeatureLink.h"

@implementation FeatureSection 

@dynamic title;
@dynamic ordinality;
@dynamic links;

+ (FeatureSection *)featureSectionWithTitle:(NSString *)aTitle {
	FeatureSection *featureSection = [CoreDataManager insertNewObjectForEntityForName:@"FeatureSection"];
	// TODO: make order dependent on a value from the server, and make this only a fallback
	static NSInteger sortOrder = 1000; // something to fall back on in case sort order is not defined on the server

	featureSection.title = aTitle;
	
	featureSection.ordinality = [NSNumber numberWithInteger:sortOrder];;
	sortOrder++;	
	
	return featureSection;
}

- (NSString *)description {
	return self.title;
}

@end
