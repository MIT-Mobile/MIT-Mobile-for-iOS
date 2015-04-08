#ifndef MIT_Mobile_MITAdditions_h
#define MIT_Mobile_MITAdditions_h

#import "Foundation+MITAdditions.h"
#import "UIKit+MITAdditions.h"
#import "CoreLocation+MITAdditions.h"
#import "UIImage+Resize.h"
#import "NSDateFormatter+RelativeString.h"
#import "NSTimer+MITBlockTimer.h"
#import "CoreData+MITAdditions.h"

#ifndef MITClassAssert
    #define MITClassAssert(object,klass) NSAssert([object isKindOfClass:klass],@"%@ is kind of %@, expected %@",object,NSStringFromClass([object class]),NSStringFromClass(klass))
#endif //MITClassAssert

#endif
