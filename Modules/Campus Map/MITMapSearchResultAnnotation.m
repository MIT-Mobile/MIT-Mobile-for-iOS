
#import "MITMapSearchResultAnnotation.h"
#import "MITMobileWebAPI.h"
#import "UIKit+MITAdditions.h"
#import "MobileRequestOperation.h"


@implementation MITMapSearchResultAnnotation
+ (void) executeServerSearchWithQuery:(NSString *)query jsonDelegate:(id<JSONLoadedDelegate>)delegate object:(id)object {

    NSDictionary *parameters = nil;
    if (query) {
        parameters = @{@"q" : query};
    }

    MobileRequestOperation *apiRequest = [[MobileRequestOperation alloc] initWithModule:@"map"
                                                                                command:@"search"
                                                                             parameters:parameters];
    apiRequest.userData = object;
    apiRequest.completeBlock = ^(MobileRequestOperation *operation, id content, NSString *mimeType, NSError *error) {
        if (error) {
            if ([delegate respondsToSelector:@selector(handleConnectionFailureForRequest:)]) {
                [delegate handleConnectionFailureForRequest:operation];
            }
            
            BOOL showAlert = NO;
            if ([delegate respondsToSelector:@selector(request:shouldDisplayStandardAlertForError:)]) {
                showAlert = [delegate request:operation shouldDisplayStandardAlertForError:error];
            }
            
            if (showAlert) {
                NSString *header = nil;
                id<UIAlertViewDelegate> alertViewDelegate = nil;
                
                if ([delegate respondsToSelector:@selector(request:displayHeaderForError:)]) {
                    header = [delegate request:operation
                     displayHeaderForError:error];
                }
                
                if ([delegate respondsToSelector:@selector(request:alertViewDelegateForError:)]) {
                    alertViewDelegate = [delegate request:operation alertViewDelegateForError:error];
                }
                
                [[UIAlertView alertViewForError:error
                                      withTitle:header
                              alertViewDelegate:alertViewDelegate] show];
            }
        } else {
            [delegate request:operation
                   jsonLoaded:content];
        }
    };
    
    [[MobileRequestOperation defaultQueue] addOperation:apiRequest];
}

-(id) initWithInfo:(NSDictionary*)info
{
	self = [super init];
	if (self) {
		self.info = info;
		
		self.architect = info[@"architect"];
		self.bldgimg = info[@"bldgimg"];
		self.bldgnum = info[@"bldgnum"];
		self.uniqueID = info[@"id"];
		self.mailing = info[@"mailing"];
		self.name = info[@"name"];
		self.street = info[@"street"];
		self.viewAngle = info[@"viewangle"];
		self.city = info[@"city"];
        self.coordinate = CLLocationCoordinate2DMake([info[@"lat_wgs84"] doubleValue],
                                                     [info[@"long_wgs84"] doubleValue]);
		
		
		NSArray* contents = info[@"contents"];
		NSMutableArray* contentsWithNames = [[NSMutableArray alloc] init];
		for (NSDictionary* content in contents) {
            if ([content[@"name"] length]) {
                [contentsWithNames addObject:content[@"name"]];
            }
		}
		
		self.contents = contentsWithNames;
		self.snippets = info[@"snippets"];
		
		self.dataPopulated = YES;
	}
	
	return self;
	
}

- (NSDictionary*)info
{
	// if there is a dictionary of info, return it. Otherwise construct the dictionary based on what we do have. 
    if (!_info) {
        NSMutableDictionary* info = [NSMutableDictionary dictionary];
        if (self.architect) {
            info[@"architect"] = info;
        }

        if (self.bldgimg) {
            info[@"bldgimg"] = info;
        }

        if (self.bldgnum) {
            info[@"bldgnum"] = info;
        }

        if (self.uniqueID) {
            info[@"id"] = info;
        }

        if (self.mailing) {
            info[@"mailing"] = info;
        }

        if (self.name) {
            info[@"name"] = info;
        }

        if (self.street) {
            info[@"street"] = info;
        }

        if (self.viewAngle) {
            info[@"viewangle"] = info;
        }

        if (self.city) {
            info[@"city"] = info;
        }

        info[@"lat_wgs84"] = @(self.coordinate.latitude);
        info[@"long_wgs84"] = @(self.coordinate.longitude);

        NSMutableArray *namedContents = [[NSMutableArray alloc] init];
        [self.contents enumerateObjectsUsingBlock:^(NSString *contentName, NSUInteger idx, BOOL *stop) {
            [namedContents addObject:@{@"name" : contentName}];
        }];

        if ([namedContents count]) {
            info[@"contents"] = namedContents;
        }

        if (self.snippets) {
            info[@"snippets"] = self.snippets;
        }
    }

    return _info;
}

- (id)initWithCoordinate:(CLLocationCoordinate2D) coordinate
{
	self = [super init];
	if (self) {
		_coordinate = coordinate;
	}
	
	return self;
}

#pragma mark MKAnnotation
-(NSString*) title
{
    if (self.name && self.bldgnum) {
		NSString* buildingName = [NSString stringWithFormat:@"Building %@", self.bldgnum];
		if ([buildingName isEqualToString:self.name]) {
			return self.name;
		}

		return [NSString stringWithFormat:@"%@ (%@)", buildingName, self.name];
    } else if (self.name) {
		return self.name;
    } else if (self.bldgnum) {
		return [NSString stringWithFormat:@"Building %@", self.bldgnum];
    }

	return nil;
}

- (NSString *)subtitle
{
	return nil;
}
@end
