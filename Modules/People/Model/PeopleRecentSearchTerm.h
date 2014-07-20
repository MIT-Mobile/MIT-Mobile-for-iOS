//
//  PeopleRecentSearchTerm.h
//  MIT Mobile
//
//  Created by Yev Motov on 7/18/14.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "MITManagedObject.h"

@interface PeopleRecentSearchTerm : MITManagedObject

@property (nonatomic, retain) NSString * recentSearchTerm;

@end
