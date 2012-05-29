#import <Foundation/Foundation.h>

@class KSPromise;
typedef void(^deferredCallback)(KSPromise *);

@interface KSPromise : NSObject

@property (strong, nonatomic) id value;
@property (strong, nonatomic) NSError *error;

+ (KSPromise *)join:(NSArray *)promises;
- (KSPromise *)whenFulfilled:(deferredCallback)complete;
- (KSPromise *)whenResolved:(deferredCallback)complete;
- (KSPromise *)whenRejected:(deferredCallback)complete;
- (void)cancel;
- (NSArray *)joinedPromises;
- (BOOL)isResolved;
- (BOOL)isRejected;
- (BOOL)isFulfilled;

@end
