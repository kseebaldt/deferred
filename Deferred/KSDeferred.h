#import "KSPromise.h"
#import "KSCancellable.h"
#import "KSNetworkClient.h"
#import "KSURLConnectionClient.h"
#import "KSURLSessionClient.h"

@interface KSDeferred : NSObject

@property (strong, nonatomic) KSPromise *promise;

+ (instancetype)defer;

- (void)resolveWithValue:(id)value;
- (void)rejectWithError:(NSError *)error;
- (void)whenCancelled:(void (^)(void))cancelledBlock;

@end
