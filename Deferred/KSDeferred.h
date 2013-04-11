#import "KSPromise.h"

@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;

@end
