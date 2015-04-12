#import <Foundation/Foundation.h>
#import "KSCancellable.h"


@class KSPromise;

typedef id(^promiseValueCallback)(id value);
typedef id(^promiseErrorCallback)(NSError *error);
typedef void(^deferredCallback)(KSPromise *p);

FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorDomain;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorErrorsKey;
FOUNDATION_EXPORT NSString *const KSPromiseWhenErrorValuesKey;

@interface KSPromise : NSObject<KSCancellable>
@property (strong, nonatomic, readonly) id value;
@property (strong, nonatomic, readonly) NSError *error;
@property (assign, nonatomic, readonly) BOOL fulfilled;
@property (assign, nonatomic, readonly) BOOL rejected;
@property (assign, nonatomic, readonly) BOOL cancelled;

+ (KSPromise *)when:(NSArray *)promises;
- (KSPromise *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback;

- (id)waitForValue;
- (id)waitForValueWithTimeout:(NSTimeInterval)timeout;

- (void)addCancellable:(id<KSCancellable>)cancellable;

#pragma deprecated
+ (KSPromise *)join:(NSArray *)promises;
- (void)whenResolved:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenRejected:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenFulfilled:(deferredCallback)complete DEPRECATED_ATTRIBUTE;

@end
