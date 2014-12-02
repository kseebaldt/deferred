#import "KSPromise.h"
#import "KSCancellable.h"


@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;
- (void)whenCancelled:(void (^)(void))cancelledBlock;

@end
