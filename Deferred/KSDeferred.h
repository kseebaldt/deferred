#import "KSPromiseOld.h"
#import "KSPromise.h"

@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;

+ (KSDeferred *)defer;

- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;

@end
