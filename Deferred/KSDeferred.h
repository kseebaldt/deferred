#import "KSPromise.h"
#import "KSPromiseA.h"

@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;
@property (strong, nonatomic) KSPromiseA *promiseA;

+ (KSDeferred *)defer;

- (void)resolveWithValue:(id)value;
- (void)fullfillWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;

@end
