#import <Foundation/Foundation.h>
#import "MITModule.h"

@interface MITModuleURL : NSObject {
	NSString *path;
	NSString *query;
	NSString *moduleTag;
}

- (id) initWithTag:(NSString *)tag;
- (id) initWithTag:(NSString *)tag path:(NSString *)path query:(NSString *)query;
- (void) setPath:(NSString *)path query:(NSString *)query;
- (void) setAsModulePath;
- (void) setPathWithViewController: (UIViewController *)viewController extension:(NSString *)extension;

@property (readonly) NSString *path;
@property (readonly) NSString *query;

@end

@protocol MITModuleURLContainer
@property (readonly) MITModuleURL *url;
@end

