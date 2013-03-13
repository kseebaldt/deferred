#import <Foundation/Foundation.h>

@class KSPromise;

typedef id(^promiseValueCallback)(id value);
typedef id(^promiseErrorCallback)(NSError *error);
typedef void(^deferredCallback)(KSPromise *p);

@interface KSPromise : NSObject
@property (strong, nonatomic, readonly) id value;
@property (strong, nonatomic, readonly) NSError *error;

+ (KSPromise *)join:(NSArray *)promises;

- (KSPromise *)then:(promiseValueCallback)fulfilledCallback error:(promiseErrorCallback)errorCallback;
- (void)cancel;

#pragma deprecated
- (void)whenResolved:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenRejected:(deferredCallback)complete DEPRECATED_ATTRIBUTE;
- (void)whenFulfilled:(deferredCallback)complete DEPRECATED_ATTRIBUTE;


@end
